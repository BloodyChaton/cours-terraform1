
resource "azurerm_resource_group" "rg2"{
name = "${var.resourceG[1]}"
location ="${var.server[1]}"
}

resource "azurerm_virtual_network" "myterraformnetwork2" {
    name                = "${var.vn[1]}"
    address_space       = ["11.0.0.0/27"]
    location            = "${azurerm_resource_group.rg2.location}"
    resource_group_name = "${azurerm_resource_group.rg2.name}"
}

resource "azurerm_subnet" "myterraformsubnet2" {
    name                 = "${var.subvn[1]}"
    resource_group_name  = "${azurerm_resource_group.rg2.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork2.name}"
    address_prefix       = "11.0.0.0/28"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip2" {
    name                         = "${var.ips[1]}"
    location                     = "${azurerm_resource_group.rg2.location}"
    resource_group_name          = "${azurerm_resource_group.rg2.name}"
    allocation_method            = "Dynamic"
    tags {
        environment = "dev"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg2" {
    name                = "${var.NSG[1]}"
    location            = "${azurerm_resource_group.rg2.location}"
    resource_group_name = "${azurerm_resource_group.rg2.name}"

        security_rule {
        name                       = "HTTP-22"
        priority                   = 152
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "7050"
        destination_port_range     = "7050"
        source_address_prefix      = "10.0.0.0/28"
        destination_address_prefix = "11.0.0.0/28"
    }
        security_rule {
        name                       = "HTTP-23"
        priority                   = 153
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "7050"
        destination_port_range     = "7050"
        source_address_prefix      = "11.0.0.0/28"
        destination_address_prefix = "10.0.0.0/28"
    }
            security_rule {
        name                       = "HTTP-24"
        priority                   = 154
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "1251"
        destination_port_range     = "1251"
        source_address_prefix      = "12.0.0.0/28"
        destination_address_prefix = "11.0.0.0/28"
    }
            security_rule {
        name                       = "HTTP-25"
        priority                   = 155
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "1251"
        destination_port_range     = "1251"
        source_address_prefix      = "11.0.0.0/28"
        destination_address_prefix = "12.0.0.0/28"
    }
    tags {
        environment = "dev"
    }
}
# Associate Network Security Rule to Subnet
resource "azurerm_subnet_network_security_group_association" "associate2" {
  subnet_id                 = "${azurerm_subnet.myterraformsubnet2.id}"
  network_security_group_id = "${azurerm_network_security_group.myterraformnsg2.id}"
}
# Create network interface
resource "azurerm_network_interface" "myterraformnic2" {
    name                      = "${var.NIC[1]}"
    location                  = "${azurerm_resource_group.rg2.location}"
    resource_group_name       = "${azurerm_resource_group.rg2.name}"
    #network_security_group_id = "${azurerm_network_security_group.myterraformnsg2.id}"
    ip_configuration {
        name                          = "${var.NIConfig[1]}"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet2.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip2.id}"
    }
    tags {
        environment = "dev"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId2" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.rg2.name}"
    }
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount2" {
    name                        = "diag${random_id.randomId2.hex}"
    resource_group_name         = "${azurerm_resource_group.rg2.name}"
    location                    = "${azurerm_resource_group.rg2.location}"
    account_tier                = "Standard"
    account_replication_type    = "LRS"
    tags {
        environment = "dev"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm2" {
    name                  = "${var.VM[1]}"
    location              = "${azurerm_resource_group.rg2.location}"
    resource_group_name   = "${azurerm_resource_group.rg2.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic2.id}"]
    vm_size               = "Standard_DS1_v2"
    storage_os_disk {
        name              = "myOsDisk-appVM"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myappvm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa  AAAAB3NzaC1yc2EAAAADAQABAAABAQCym+NouF8g0DKCnFhRX6qHBVYXyaTyiPZkwL33Hr4GrYFREP4cDeTNnklIeRwXfXdgOjF5QBnMGQIKe6pki/CoulTkElz62rCOKPVmMYuudTEMmBN7eYOihDPP4Q9BrmDTakwwMpTTNxiPwpjPZaeU8UUVwKQWYDngSOX40oLW68A6oe4QGkbi2j9XqF/HbOuq7dwQV49ZPwZXiIiK0W/NZjyd7vBqUZlifwHJoVxOVhi7zjxUlHESg1qGkWWboiBnXi1a3nq/MOHlGxGdVlhQiWS+zefZsm9ZlpTSUNEuJTOaL874HcF9DtFVl3zCKeAhMzLFp5RpOJkr0taWLAgN"     
            }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount2.primary_blob_endpoint}"
    }

    tags {
        environment = "dev"
        name ="APPs"
    }
}