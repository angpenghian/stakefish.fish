# Use an official Python runtime as a base image
FROM python:3.9-slim

# Set the working directory in the container to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY main.py /app/

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir fastapi uvicorn httpx databases[mysql] sqlalchemy aiofiles starlette_prometheus

# Make port 3000 available to the world outside this container
EXPOSE 3000

# Define environment variable for the database URL
ENV DATABASE_URL=""

# CMD to start uvicorn
CMD ["uvicorn", "main:app", "--reload", "--host", "0.0.0.0", "--port", "3000"]
