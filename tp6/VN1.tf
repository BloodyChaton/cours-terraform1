provider "azurerm"{
}
resource "azurerm_resource_group" "rg"{
name = "${var.resourceG}"
location ="${var.server[0]}"
}

resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "${var.vn[0]}"
    address_space       = ["10.0.0.0/27"]
    location            = "${azurerm_resource_group.rg.location}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "${var.subvn[0]}"
    resource_group_name  = "${azurerm_resource_group.rg.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
    address_prefix       = "10.0.0.0/28"
}

# Create Load Balancer

resource "azurerm_public_ip" "lbip" {
  name                = "PublicIPForLB"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Static"
}

resource "azurerm_lb" "lblb" {
  name                = "LoadBalancer"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddressLB"
    public_ip_address_id = "${azurerm_public_ip.lbip.id}"
  }
} 
resource "azurerm_lb_backend_address_pool" "lbba" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.lblb.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_availability_set" "lbas" {
  name                = "acceptanceTestAvailability"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  platform_update_domain_count = 2
  platform_fault_domain_count = 2
  managed             = true

  tags = {
    environment = "Production"
  }
}


# Create public IPs
# resource "azurerm_public_ip" "myterraformpublicip" {
#     name                         = "${var.ips[0]}${count.index}"
#     location                     = "${azurerm_resource_group.rg.location}"
#     resource_group_name          = "${azurerm_resource_group.rg.name}"
#     allocation_method            = "Dynamic"
#     count                        = 2
#     tags {
#         environment = "dev"
#     }
# }

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "${var.NSG[0]}"
    location            = "${azurerm_resource_group.rg.location}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    security_rule {
        name                       = "HTTP"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "80"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "11.0.0.0/28"
    }
        security_rule {
        name                       = "SSH"
        priority                   = 1010
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "22"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "11.0.0.0/28"
    }
        security_rule {
        name                       = "HTTP2"
        priority                   = 1020
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "7050"
        destination_port_range     = "7050"
        source_address_prefix      = "11.0.0.0/28"
        destination_address_prefix = "10.0.0.0/28"
    }
        security_rule {
        name                       = "HTTP3"
        priority                   = 1030
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "7050"
        destination_port_range     = "7050"
        source_address_prefix      = "10.0.0.0/28"
        destination_address_prefix = "11.0.0.0/28"
    }
    tags {
        environment = "dev"
    }
}
# Associate Network Security Rule to Subnet
resource "azurerm_subnet_network_security_group_association" "associate" {
  subnet_id                 = "${azurerm_subnet.myterraformsubnet.id}"
  network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "${var.NIC[0]}${count.index}"
    location                  = "${azurerm_resource_group.rg.location}"
    resource_group_name       = "${azurerm_resource_group.rg.name}"
    count                     = 2
    ip_configuration {
        name                          = "${var.NIConfig[0]}${count.index}"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "Dynamic"
    }
    tags {
        environment = "dev"
    }
}

# Associate LB to Network
resource "azurerm_network_interface_backend_address_pool_association" "assoLB" {
  count                   = 2
  network_interface_id    = "${element(azurerm_network_interface.myterraformnic.*.id, count.index)}"
  ip_configuration_name   = "${var.NIConfig[0]}${count.index}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.lbba.id}"
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.rg.name}"
    }
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}${count.index}"
    resource_group_name         = "${azurerm_resource_group.rg.name}"
    location                    = "${azurerm_resource_group.rg.location}"
    account_tier                = "Standard"
    account_replication_type    = "LRS"
    count                       = 2
    tags {
        environment = "dev"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "${var.VM[0]}${count.index}"
    location              = "${azurerm_resource_group.rg.location}"
    resource_group_name   = "${azurerm_resource_group.rg.name}"
    availability_set_id   = "${azurerm_availability_set.lbas.id}"
    network_interface_ids = ["${element(azurerm_network_interface.myterraformnic.*.id, count.index)}"]
    vm_size               = "Standard_DS1_v2"
    count                 = 2
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
        storage_uri = "${element(azurerm_storage_account.mystorageaccount.*.primary_blob_endpoint, count.index)}"
    }

    tags {
        environment = "dev"
        name ="tech"
    }
}