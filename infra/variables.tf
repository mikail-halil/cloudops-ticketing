variable "subscription_id" {
  description = "ID de l'abonnement Azure (récupéré via : az account show --query id -o tsv)"
  type        = string
}

variable "location" {
  description = "Région Azure où déployer"
  type        = string
  default     = "westeurope"
}

variable "prefix" {
  description = "Préfixe de nommage des ressources (rg, vnet, vm...)"
  type        = string
  default     = "cloudops"
}

variable "vm_size" {
  description = "Taille de la VM (B2s = 2 vCPU / 4 Go, suffisant pour la stack)"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Nom de l'utilisateur administrateur de la VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Chemin de la clé publique SSH (~ est résolu via pathexpand)"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "my_public_ip" {
  description = "Ton IP publique en /32 pour autoriser SSH (ex: 203.0.113.5/32). curl ifconfig.me"
  type        = string
}
