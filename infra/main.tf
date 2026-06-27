# ============================================================================
#  Infrastructure CloudOps Ticketing — une VM Ubuntu prête pour Docker
#  Graphe : RG -> VNet -> Subnet -> NSG -> IP publique -> NIC -> VM
# ============================================================================

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags = {
    project = "cloudops-ticketing"
    env     = "exam"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Subnet défini EN LIGNE dans le VNet plutôt qu'en ressource séparée :
  # cela évite la "race" de lecture du provider azurerm sur azurerm_subnet
  # (le subnet existe mais est relu comme absent -> boucle créer/supprimer).
  subnet {
    name             = "${var.prefix}-subnet"
    address_prefixes = ["10.0.1.0/24"]
  }
}

# IP publique en SKU Standard (le SKU Basic est retiré par Azure depuis fin 2025).
resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Pare-feu réseau : on n'ouvre QUE le strict nécessaire.
#  - 22  (SSH)        : source paramétrable (var.ssh_source_address) ; ouvert par
#                       défaut pour le déploiement CI/CD (runners GitHub, IP non fixes)
#  - 80  (HTTP)       : ouvert (application, via Nginx)
#  - 3000 (Grafana)   : restreint à l'IP admin (var.my_public_ip)
#  - 9090 (Prometheus): restreint à l'IP admin (var.my_public_ip)
# HTTPS (443) est hors périmètre de cette V1 : la règle n'est pas ouverte.
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # SSH : authentification par CLÉ uniquement (root désactivé + fail2ban + MaxAuthTries).
  # Source paramétrable via var.ssh_source_address. Par défaut "*", car le déploiement
  # CI/CD se fait en SSH depuis des runners GitHub Actions dont l'IP n'est pas fixe.
  # Pour un accès admin strict, fixer var.ssh_source_address à votre IP /32 (la CI/CD
  # nécessiterait alors un runner auto-hébergé ou un bastion).
  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_source_address
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowGrafanaFromMe"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = var.my_public_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowPrometheusFromMe"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9090"
    source_address_prefix      = var.my_public_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = one(azurerm_virtual_network.vnet.subnet[*].id)
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# On associe le pare-feu (NSG) à la carte réseau de la VM.
resource "azurerm_network_interface_security_group_association" "assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "${var.prefix}-vm"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.nic.id]

  # Authentification par clé SSH uniquement (pas de mot de passe).
  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  # cloud-init : installe Docker au premier démarrage.
  custom_data = base64encode(file("${path.module}/cloud-init.yaml"))

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = {
    project = "cloudops-ticketing"
  }
}
