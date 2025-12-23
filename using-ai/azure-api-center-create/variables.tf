variable "resource_group_name" {
  type        = string
  description = "The name of the resource group."
}

variable "location" {
  type        = string
  description = "Specifies the location for resources."
  default     = ""
}

variable "api_center_name" {
  type        = string
  description = "The name of the API center."
  default     = ""
}

variable "api_name" {
  type        = string
  description = "The name of an API to register in the API center."
  default     = "first-api"
}

variable "api_type" {
  type        = string
  description = "The type of the API to register in the API center."
  default     = "rest"
  validation {
    condition     = contains(["rest", "soap", "graphql", "grpc", "webhook", "websocket"], var.api_type)
    error_message = "The api_type must be one of: rest, soap, graphql, grpc, webhook, websocket."
  }
}
