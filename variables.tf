# variables.tf

variable "environment" {
  description = "Entorno de despliegue (ej. dev, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Región de Azure para los recursos"
  type        = string
  default     = "Canada Central" # Una región estándar y económica
}

variable "project_name" {
  description = "Nombre base del proyecto para nombrar recursos"
  type        = string
  default     = "rtlmxjr26"
}