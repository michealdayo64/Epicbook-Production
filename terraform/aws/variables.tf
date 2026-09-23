variable "project_name" {
  description = "Project/resource name"
  type        = string
  default     = "epicbook"
}


variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR blocks for the private database subnets"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_db_cidrs" {
  description = "CIDR blocks for the private database subnets"
  type        = list(string)
  default = [
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

variable "ipv4_anywhere" {
  description = "Any IP address from the internet"
  type        = string
  default     = "0.0.0.0/0"
}

variable "vm-security-group-name" {
  description = "Security group name for the web tier"
  type        = string
  default     = "vm-security-group-name"
}

variable "db-security-group-name" {
  description = "Security group name for the database tier"
  type        = string
  default     = "db-security-group-name"
}

variable "key_name_vm" {
  description = "Name of the EC2 key pair for web tier"
  type        = string
  default     = "key_name_vm"
}

variable "vm_public_key" {
  description = "Public SSH key used to create the EC2 key pair"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_username" {
  description = "Database administrator username"
  type        = string
}

variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}
