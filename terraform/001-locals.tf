locals {
  common = {
    name           = "penghian"
    region         = "East US"
    vnet_cidr      = "10.0.0.0/20"
    subnet_cidr    = "10.0.0.0/21"

    vm_size        = "Standard_D2s_v3"
    admin_username = file("./admin_username.txt")
    admin_password = file("./admin_password.txt")
  }
}