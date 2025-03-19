resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr                      # Defines the IP range for the VPC. Required to allocate IPs for resources.
  enable_dns_hostnames = true                              # Enables DNS hostnames for instances in the VPC, allowing readable names.
  enable_dns_support    = true                             # Enables DNS resolution, allowing domain names to be translated into IPs.
  tags = {
    Name = "${var.cluster_name}-vpc"                      # Dynamically generates the VPC's name based on the cluster_name variable.
    "kubernetes.io/cluster/${var.cluster_name}" = "shared" # Associates the VPC with a specific Kubernetes cluster. 
                                                           # "shared" allows multiple cluster components to use this VPC.
                                                           # If "owned" is used, the VPC is exclusively tied to one cluster.
  }
}

resource "aws_subnet" "private" {                              # Defines an AWS subnet resource named "private". Required for creating subnets in a VPC.
  count             = length(var.private_subnet_cidrs)         # Dynamically determines the number of subnets to create, based on 
                                                                the length of the CIDR blocks provided in 'var.private_subnet_cidrs'. 
                                                                Required for scalability.
  vpc_id            = aws_vpc.main.id                           # Associates the subnet with the specified VPC. Required to ensure the subnet exists within the desired VPC.
  cidr_block        = var.private_subnet_cidrs[count.index]     # Assigns a CIDR block to each subnet from the list 'var.private_subnet_cidrs', using 'count.index' to select 
                                                                the current subnet. Required to specify IP ranges for the subnets.
  availability_zone = var.availability_zones[count.index]       # Assigns each subnet to a specific availability zone using the corresponding 'count.index'. Significant for high availability and fault tolerance.

  tags = {                                                      # Tags are metadata added to resources for easy identification and management. Not strictly required but highly recommended.
    Name                                           = "${var.cluster_name}-private-${count.index + 1}"  # Creates a unique name for each subnet using the cluster name and index (count.index). Helps in resource identification.
    "kubernetes.io/cluster/${var.cluster_name}"    = "shared"   # Indicates that the subnet is shared within the Kubernetes cluster. Necessary for Kubernetes integration.
    "kubernetes.io/role/internal-elb"              = "1"        # Marks the subnet as suitable for internal load balancers in Kubernetes. Required for proper functionality of internal ELBs.
  }
}
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true                                # Enables automatic assignment of public IP addresses to instances launched in this subnet. 
                                                                Required for making resources accessible from the internet.

  tags = {
    Name                                           = "${var.cluster_name}-public-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}"    = "shared"
    "kubernetes.io/role/elb"                       = "1"
  }
}

resource "aws_internet_gateway" "main"{
  vpc_id = aws_vpc.main.id

  tags ={
    Name = "${var.cluster_name}-igw"
  }
}

resource "aws_eip" "nat" {          # Define an Elastic IP (EIP) resource to be used by NAT gateways.

  count = length(var.public_subnet_cidrs) # Creates one EIP for each public subnet dynamically.
                                         # Question: Why use public subnets when NAT is for private subnets?
                                         # Answer: NAT gateways live in public subnets to access the internet
                                         # via the internet gateway, even though they serve private subnets.

  domain = "vpc"                       # Specifies that the EIPs are allocated for use in the VPC.
                                       # Question: Why is "domain" set to "vpc"?
                                       # Answer: Ensures the Elastic IPs are allocated for VPC usage
                                       # (not legacy EC2-Classic).

  tags = {                             # Assigns tags to make resources easier to identify.
    Name = "${var.cluster_name}-nat-${count.index + 1}" # Creates a descriptive tag for each EIP.
                                                       # Question: Why use tags here?
                                                       # Answer: Tags help in organizing and managing resources
                                                       # efficiently.
  }
}

resource "aws_nat_gateway" "main" { 
  count         = length(var.public_subnet_cidrs) # Creates one NAT gateway for each public subnet
  allocation_id = aws_eip.nat[count.index].id     # Associates each NAT gateway with a specific Elastic IP
  subnet_id     = aws_subnet.public[count.index].id # Places each NAT gateway in a corresponding public subnet

  tags = {
    Name = "${var.cluster_name}-nat-${count.index + 1}" # Assigns a descriptive tag to each NAT gateway
  }
}

resource "aws_route_table" "public" {  # Creates a route table for public subnet(s).

  vpc_id = aws_vpc.main.id             # Associates the route table with a specific VPC.

  route {                              # Adds a route to the route table.
    cidr_block = "0.0.0.0/0"           # Specifies that this route is for all IPv4 addresses (default route).
    gateway_id = aws_internet_gateway.main.id # Routes all internet-bound traffic through the internet gateway.
  }
 tags = {
    Name = "${var.cluster_name}-public"
  }
}

resource "aws_route_table" "private" {      # Creates a route table for private subnets.
  count  = length(var.private_subnet_cidrs) # Dynamically creates one route table per private subnet.
  vpc_id = aws_vpc.main.id                  # Associates each route table with the main VPC.

  route {                                   # Defines a route in the route table.
    cidr_block     = "0.0.0.0/0"           # Routes all IPv4 traffic (default route) to the NAT gateway.
    nat_gateway_id = aws_nat_gateway.main[count.index].id # Routes through the corresponding NAT gateway.
  }

  tags = {
    Name = "${var.cluster_name}-private-${count.index + 1}" # Adds a tag with the cluster name and index.
  }
}
resource "aws_route_table_association" "private" {  
  count          = length(var.private_subnet_cidrs)         # Creates one route table association for each private subnet.
  subnet_id      = aws_subnet.private[count.index].id       # Associates each private subnet with its corresponding route table.
  route_table_id = aws_route_table.private[count.index].id  # Links the private route table to the respective private subnet.
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
