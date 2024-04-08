from fastapi import FastAPI, HTTPException, Query, Body
from typing import List, Optional
from pydantic import BaseModel, Field
import time
import os
import socket
from databases import Database
import sqlalchemy
import httpx
from starlette_prometheus import PrometheusMiddleware, metrics

app = FastAPI()

# Database table definition (assuming SQLAlchemy ORM)
metadata = sqlalchemy.MetaData()
dns_logs = sqlalchemy.Table(
    "dns_logs", metadata,
    sqlalchemy.Column("id", sqlalchemy.Integer, primary_key=True),
    sqlalchemy.Column("domain", sqlalchemy.String(255)),
    sqlalchemy.Column("resolved_ips", sqlalchemy.String(255)),
    sqlalchemy.Column("query_time", sqlalchemy.Integer),
    sqlalchemy.Column("client_ip", sqlalchemy.String(255)),
)

# Azure Database for MySQL connection details
DATABASE_URL = os.getenv("DATABASE_URL", "")

# Initialize the Database object
database = Database(DATABASE_URL)

class Address(BaseModel):
    ip: str

class QueryModel(BaseModel):
    domain: str
    addresses: List[Address]
    client_ip: str = "192.168.1.1"  # Placeholder for actual client IP retrieval logic
    created_at: int = Field(default_factory=lambda: int(time.time()))

class ValidateIPRequest(BaseModel):
    ip: str

class ValidateIPResponse(BaseModel):
    status: bool

class HistoryQueryModel(BaseModel):
    id: int
    domain: str
    resolved_ips: List[str]
    query_time: int
    client_ip: str

def is_running_in_kubernetes() -> bool:
    """
    Checks if the application is running in a Kubernetes environment.
    This is determined by checking the existence of a service account token.
    """
    return os.path.exists("/var/run/secrets/kubernetes.io/serviceaccount/token")

# Add Prometheus middleware to the application
app.add_middleware(PrometheusMiddleware)
# Expose metrics endpoint for Prometheus
app.add_route("/metrics", metrics)

@app.get("/health")
async def health_check():
    return "ok"

@app.get("/", tags=["root"])
def read_root():
    running_in_k8s = is_running_in_kubernetes()
    return {"version": "1.0", "date": int(time.time()), "kubernetes": running_in_k8s}

@app.on_event("startup")
async def startup():
    await database.connect()

@app.on_event("shutdown")
async def shutdown():
    await database.disconnect()

@app.get("/v1/tools/lookup", response_model=QueryModel, tags=["tools"])
async def lookup_domain(domain: str = Query(..., description="Domain name to lookup")):
    async with httpx.AsyncClient() as client:
        response = await client.get('https://api.ipify.org')
        client_ip = response.text  # This is the public IP address of the client

    try:
        ips = socket.gethostbyname_ex(domain)[2]
        ipv4_addresses = [ip for ip in ips if ":" not in ip]
        addresses = [Address(ip=ip) for ip in ipv4_addresses]

        query = dns_logs.insert().values(
            domain=domain,
            resolved_ips=','.join(ipv4_addresses),
            query_time=int(time.time()),
            client_ip=client_ip  # Use the fetched client IP
        )
        await database.execute(query)

        return QueryModel(domain=domain, addresses=addresses, client_ip=client_ip)
    except socket.gaierror:
        raise HTTPException(status_code=404, detail=f"Domain {domain} not found")

@app.post("/v1/tools/validate", response_model=ValidateIPResponse, tags=["tools"])
async def validate_ip(request: ValidateIPRequest = Body(..., description="IP to validate")):
    valid = request.ip.count('.') == 3 and all(part.isdigit() and 0 <= int(part) <= 255 for part in request.ip.split('.'))
    return ValidateIPResponse(status=valid)

@app.get("/v1/history", response_model=List[HistoryQueryModel], tags=["history"])
async def get_history():
    query = dns_logs.select().order_by(sqlalchemy.desc(dns_logs.c.query_time)).limit(20)
    results = await database.fetch_all(query)
    history = [HistoryQueryModel(
        id=result["id"],
        domain=result["domain"],
        resolved_ips=result["resolved_ips"].split(',') if result["resolved_ips"] else [],
        query_time=result["query_time"],
        client_ip=result["client_ip"]
    ) for result in results]
    return history

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=3000)
