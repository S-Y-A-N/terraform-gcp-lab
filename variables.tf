variable "project_id" {
  type        = string
  description = "GCP project to deploy into"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "service_name" {
  type    = string
  default = "hello-lab"
}

variable "image" {
  type        = string
  description = "Container image to deploy"
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}