resource "azurerm_resource_group" "rg2"{
name = "${var.resourceG[1]}"
location ="${var.server[1]}"
}

resource "azurerm_virtual_network" "myterraformnetwork2" {
    name                = "${var.vn[1]}${count.index}"
    address_space       = ["10.1.${count.index}.0/27"]
    location            = "${azurerm_resource_group.rg2.location}"
    resource_group_name = "${azurerm_resource_group.rg2.name}"
}

resource "azurerm_subnet" "myterraformsubnet2" {
    name                 = "${var.subvn[1]}${count.index}"
    resource_group_name  = "${azurerm_resource_group.rg2.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork2.name}"
    address_prefix       = "10.1.${count.index}.0/28"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip2" {
    name                         = "${var.ips[1]}${count.index}"
    location                     = "${azurerm_resource_group.rg2.location}"
    resource_group_name          = "${azurerm_resource_group.rg2.name}"
    allocation_method            = "Dynamic"
    count                        = 3
    tags {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg2" {
    name                = "${var.NSG[1]}${count.index}"
    location            = "${azurerm_resource_group.rg2.location}"
    resource_group_name = "${azurerm_resource_group.rg2.name}"
    count               = 3
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    tags {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic2" {
    name                      = "${var.NIC[1]}${count.index}"
    location                  = "${azurerm_resource_group.rg2.location}"
    resource_group_name       = "${azurerm_resource_group.rg2.name}"
    network_security_group_id = "${element(azurerm_network_security_group.myterraformnsg2.*.id,count.index)}"
    count                     = 3
    ip_configuration {
        name                          = "${var.NIConfig[1]}${count.index}"
        subnet_id                     = "${element(azurerm_subnet.myterraformsubnet2.*.id, count.index)}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${element(azurerm_public_ip.myterraformpublicip2.*.id, count.index)}"
    }
    tags {
        environment = "Terraform Demo"
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
    name                        = "diag${random_id.randomId2.hex}${count.index}"
    resource_group_name         = "${azurerm_resource_group.rg2.name}"
    location                    = "${azurerm_resource_group.rg2.location}"
    account_tier                = "Standard"
    account_replication_type    = "LRS"
    count                       = 3
    tags {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm2" {
    name                  = "${var.VM[1]}${count.index}"
    location              = "${azurerm_resource_group.rg2.location}"
    resource_group_name   = "${azurerm_resource_group.rg2.name}"
    network_interface_ids = ["${element(azurerm_network_interface.myterraformnic2.*.id, count.index)}"]
    vm_size               = "Standard_B1s"
    count                 = 3
    storage_os_disk {
        name              = "myOsDisk${count.index}"
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
        computer_name  = "myvm${count.index}"
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
        storage_uri = "${element(azurerm_storage_account.mystorageaccount2.*.primary_blob_endpoint, count.index)}"
    }

    tags {
        environment = "Terraform Demo"
    }
}