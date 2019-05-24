resource "azurerm_resource_group" "rg3"{
name = "${var.resourceG[2]}"
location ="${var.server[2]}"
}

resource "azurerm_virtual_network" "myterraformnetwork3" {
    name                = "${var.vn[2]}"
    address_space       = ["12.0.0.0/27"]
    location            = "${azurerm_resource_group.rg3.location}"
    resource_group_name = "${azurerm_resource_group.rg3.name}"
}

resource "azurerm_subnet" "myterraformsubnet3" {
    name                 = "${var.subvn[2]}"
    resource_group_name  = "${azurerm_resource_group.rg3.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork3.name}"
    address_prefix       = "12.0.0.0/28"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip3" {
    name                         = "${var.ips[2]}"
    location                     = "${azurerm_resource_group.rg3.location}"
    resource_group_name          = "${azurerm_resource_group.rg3.name}"
    allocation_method            = "Dynamic"
    tags {
        environment = "dev"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg3" {
    name                = "${var.NSG[2]}"
    location            = "${azurerm_resource_group.rg3.location}"
    resource_group_name = "${azurerm_resource_group.rg3.name}"
    security_rule {
        name                       = "HTTP-31"
        priority                   = 1100
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "445"
        destination_port_range     = "445"
        source_address_prefix      = "12.0.0.0/28"
        destination_address_prefix = "*"
    }
        security_rule {
        name                       = "HTTP-32"
        priority                   = 1120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "1251"
        destination_port_range     = "1251"
        source_address_prefix      = "11.0.0.0/28"
        destination_address_prefix = "12.0.0.0/28"
    }
        security_rule {
        name                       = "HTTP-33"
        priority                   = 1130
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "1251"
        destination_port_range     = "1251"
        source_address_prefix      = "12.0.0.0/28"
        destination_address_prefix = "11.0.0.0/28"
    }
    tags {
        environment = "dev"
    }
}
# Associate Network Security Rule to Subnet
resource "azurerm_subnet_network_security_group_association" "associate3" {
  subnet_id                 = "${azurerm_subnet.myterraformsubnet3.id}"
  network_security_group_id = "${azurerm_network_security_group.myterraformnsg3.id}"
}
# Create network interface
resource "azurerm_network_interface" "myterraformnic3" {
    name                      = "${var.NIC[2]}"
    location                  = "${azurerm_resource_group.rg3.location}"
    resource_group_name       = "${azurerm_resource_group.rg3.name}"
    #network_security_group_id = "${azurerm_network_security_group.myterraformnsg3.id}"
    ip_configuration {
        name                          = "${var.NIConfig[2]}"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet3.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip3.id}"
    }
    tags {
        environment = "dev"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId3" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.rg3.name}"
    }
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount3" {
    name                        = "diag${random_id.randomId3.hex}"
    resource_group_name         = "${azurerm_resource_group.rg3.name}"
    location                    = "${azurerm_resource_group.rg3.location}"
    account_tier                = "Standard"
    account_replication_type    = "LRS"
    tags {
        environment = "dev"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm3" {
    name                  = "${var.VM[2]}"
    location              = "${azurerm_resource_group.rg3.location}"
    resource_group_name   = "${azurerm_resource_group.rg3.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic3.id}"]
    vm_size               = "Standard_DS1_v2"
    storage_os_disk {
        name              = "myOsDisk-dataVM"
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
        computer_name  = "mydatavm"
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
        storage_uri = "${azurerm_storage_account.mystorageaccount3.primary_blob_endpoint}"
    }

    tags {
        environment = "dev"
        name ="APPs"
    }
}