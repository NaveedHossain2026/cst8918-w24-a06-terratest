# 4.2 Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.labelPrefix}-A05-RG"
  location = var.region
}

# 4.3 Public IP Address (Updated to Standard SKU to resolve quota limits)
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.labelPrefix}-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"   # Standard SKU requires Static allocation
  sku                 = "Standard" # Changes it from Basic to Standard
}

# 4.4 Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.labelPrefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 4.5 Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.labelPrefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 4.6 Network Security Group (Inline SSH and HTTP Rules)
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.labelPrefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 4.7 Virtual Network Interface Card (NIC)
resource "azurerm_network_interface" "nic" {
  name                = "${var.labelPrefix}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# 4.8 Apply Security Group to the NIC directly
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# 4.9 Cloud-Init Script Data Source
data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/init.sh")
  }
}

# 4.10 Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${var.labelPrefix}-webserver"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub") # Adjust path if your key is named differently (e.g., id_ed25519.pub)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-22_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = data.cloudinit_config.config.rendered
}