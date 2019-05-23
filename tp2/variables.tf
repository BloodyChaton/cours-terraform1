variable "server" {
    type = "list"
    default= ["westus","eastus"]
}

variable "resourceG" {
    type = "list"
    default= ["testResourceGroupWUS","testResourceGroupEUS"]
}

variable "vn"{
    type= "list"
    default = ["myVNetWUS", "myVNetEUS"]
}

variable "subvn"{
    type= "list"
    default = ["mySubnetWUS","mySubnetEUS"]
}

variable "ips"{
    type= "list"
    default = ["myPublicIPWUS","myPublicIPEUS"]
}

variable "NSG"{
    type= "list"
    default = ["myNetworkSecurityGroupWUS","myNetworkSecurityGroupEUS"]
}

variable "NIC"{
    type= "list"
    default = ["myNICWUS", "myNICEUS"]
}

variable "NIConfig"{
    type= "list"
    default = ["myNicConfigurationWUS", "myNicConfigurationEUS"]
}

variable "VM"{
    type= "list"
    default = ["myVMNameWUS","myVMNameEUS"]
}