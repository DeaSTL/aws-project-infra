variable "name" {
  type = string
}

variable "ami" {
  type = string
}

variable "route_zone_id" {
  type = string
}

variable "domain" {
  type = string
}

variable "services" {
  type = list(object({
    name = string
    domain = string
    image = string
    internal_port = number
    external_port = number
  }))
}

