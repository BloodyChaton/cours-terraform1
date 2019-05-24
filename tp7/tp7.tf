# declare variables and defaults
variable "location" {
    default ="westus"
}
variable "environment" {
    default = "dev"
}
variable "vm_size" {
    default = {
        "dev"   = "Standard_B2s"
        "prod"  = "Standard_D2s_v3"
    }
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
    name     = "myResourceGroup"
    location = "${var.location}"
}

# Use the network module to create a vnet and subnet
module "network" {
    source              = "Azure/network/azurerm"
    version             = "2.0.0"
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    address_space       = "10.0.0.0/16"
    subnet_names        = ["mySubnet"]
    subnet_prefixes     = ["10.0.1.0/24"]
}

# Use the compute module to create the VM
module "compute" {
    source            = "Azure/compute/azurerm"
    version           = "1.2.0"
    location          = "${var.location}"
    vnet_subnet_id    = "${element(module.network.vnet_subnets, 0)}"
    admin_username    = "plankton"
    admin_password    = "Password1234!"
    remote_port       = "22"
    vm_os_simple      = "UbuntuServer"
    vm_size           = "${lookup(var.vm_size, var.environment)}"
    public_ip_dns     = ["zzdns"]
}
