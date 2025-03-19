# Define a variable to specify the CIDR block for the VPC
variable "vpc_cidr" {
  description = "CIDR block for VPC"       # Provides a description for the variable.
  type        = string                    # Specifies that the variable value should be a single string.
}

# Define a variable for the list of availability zones
variable "availability_zones" {
  description = "Availability zones"      # Provides a description for the variable.
  type        = list(string)              # Specifies that the variable value should be a list of strings.
}

# Define a variable for the CIDR blocks of private subnets
variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"  # Description of the variable's purpose.
  type        = list(string)                       # Specifies that the variable should be a list of strings.
}

# Define a variable for the CIDR blocks of public subnets
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"   # Describes the variable's purpose.
  type        = list(string)                       # Specifies that the variable should be a list of strings.
}

# Define a variable for the EKS cluster name
variable "cluster_name" {
  description = "Name of the EKS cluster"          # Provides a description of this variable.
  type        = string                             # Specifies that the variable value should be a single string.
}
