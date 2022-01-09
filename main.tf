resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_network_security_group" "example" {
  name                = "example-security-group"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}
resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
}  

resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "example" {
    name                         = "myPublicIP"
    location                     = azurerm_resource_group.example.location
    resource_group_name          = azurerm_resource_group.example.name
    allocation_method            = "Static"
}

resource "azurerm_network_interface" "example" {
    name                      = "example"
    location                  = azurerm_resource_group.example.location
    resource_group_name       = azurerm_resource_group.example.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.example.id
        private_ip_address_allocation = "Static"
        public_ip_address_id          = azurerm_public_ip.example.id
    }
}

resource "azurerm_route_table" "example" {
  name                = "example-routetable"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  route {
    name                   = "example"
    address_prefix         = "10.100.0.0/14"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.10.1.1"
  }
}

resource "azurerm_subnet_route_table_association" "example" {
  subnet_id      = azurerm_subnet.example.id
  route_table_id = azurerm_route_table.example.id
}

resource "azurerm_network_security_rule" "allow-http" {
  name                        = "http-access"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "80"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
} 

resource "azurerm_network_security_rule" "allow-ssh" {
  name                        = "http-access"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "22"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}
resource "azurerm_network_security_rule" "allow-node" {
  name                        = "http-access"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "30163"
  destination_port_range      = "30163"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
} 

resource "azurerm_storage_account" "example" {
    name                        = "example"
    resource_group_name         = azurerm_resource_group.example.name
    location                    = azurerm_resource_group.example.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" { 
    value = tls_private_key.example_ssh.private_key_pem 
    sensitive = true
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "example" {
    name                  = "example"
    location              = azurerm_resource_group.example.location
    resource_group_name   = azurerm_resource_group.example.name
    network_interface_ids = [azurerm_network_interface.example.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "myvm"
    admin_username = "azureuser"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.example_ssh.public_key_openssh
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.example.primary_blob_endpoint
    }
}
 provisioner "remote-exec" {
    connection {
      type                      = "ssh"
      user                      = "ubuntu"
      private_key               = "${file("wikimedia")}"
      host                      = "${element(aws_instance.web.*.public_ip,count.index)}"

    }

    inline                      = [
      "sudo apt-get update && sudo apt-get install docker.io -y",
      "sudo mkdir /mnt/data && chmod 644 /mnt/data",
      "sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && sudo chmod 755 ./kubectl && sudo mv ./kubectl /usr/local/bin/kubectl",
      "curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/",
       "sudo minikube start --vm-driver=none",
      "sleep 30",
      "sudo apt-get install git -y",
      "sudo git clone https://github.com/Anurag-30/MediaWiki.git && cd MediaWiki && cd kubernetes && sudo kubectl create -f secrets.yaml -f persistent-volumes.yaml",
      "sudo kubectl create  -f mariadb-deployment.yaml -f mariadb-svc.yaml",
      "sudo kubectl create -f app-deployment.yaml -f web-service.yaml"

    ]
  }




  




