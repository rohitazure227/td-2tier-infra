variable "environment" {
  type        = string
  default     = "dev"
  description = "The deployment stage used for naming conventions (dev, qa, prod)."
}

variable "location" {
  type        = string
  default     = "Canada Central"
  description = "The target Azure region where the network will be deployed."
}

variable "vm_count" {
  type        = number
  default     = 2
  description = "The number of App/Client Virtual Machines and NICs to deploy."
}

variable "vm_size" {
  type        = string
  default     = "Standard_B2s" # Low-cost VM choice perfect for learning environments
  description = "The structural compute hardware size for the client VMs."
}

variable "ssh_public_key_path" {
  type        = string
  description = "The path to the SSH public key used to access the Linux VMs."
}

variable "sql_admin_login" {
  description = "Microsoft Entra administrator login name for Azure SQL"
  type        = string
}

variable "sql_admin_object_id" {
  description = "Microsoft Entra Object ID of the SQL administrator"
  type        = string
}