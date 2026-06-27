variable "subscription_id" {
  description = "ID de l'abonnement Azure (récupéré via : az account show --query id -o tsv)"
  type        = string
}

variable "location" {
  description = "Région Azure où déployer (Sweden Central : UE/RGPD, ouverte aux comptes d'essai)"
  type        = string
  default     = "swedencentral"
}

variable "prefix" {
  description = "Préfixe de nommage des ressources (rg, vnet, vm...)"
  type        = string
  default     = "cloudops"
}

variable "vm_size" {
  description = "Taille de la VM (B2s_v2 = 2 vCPU / 8 Go, burstable, dispo en Sweden Central)"
  type        = string
  default     = "Standard_B2s_v2"
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
  description = "IP publique de l'administrateur en /32 pour restreindre l'accès à Grafana (3000) et Prometheus (9090). Obtenir avec : curl ifconfig.me"
  type        = string
}

variable "ssh_source_address" {
  description = "Source autorisée pour SSH (port 22). \"*\" par défaut pour permettre le déploiement CI/CD depuis les runners GitHub (IP non fixes) ; mettre votre IP /32 pour un accès admin strict."
  type        = string
  default     = "*"
}
