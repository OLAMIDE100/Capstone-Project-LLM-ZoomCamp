terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "" 
    key    = ""
    region = ""
    profile= ""
  }
}


provider "aws" {
  region = var.region
}



data "aws_caller_identity" "current" {}


################################################################################################################### VPC  CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################
resource "aws_vpc" "eks" {
  assign_generated_ipv6_cidr_block     = false
  cidr_block                           = "10.0.0.0/16"
  enable_dns_hostnames                 = true
  enable_dns_support                   = true
  enable_network_address_usage_metrics = false
  instance_tenancy                     = "default"
  tags = {
    Name     = "eks-cluster"
    solution = "eks"
  }
  tags_all = {
    Name     = "eks-cluster"
    solution = "eks"
  }
}

################################################################################################################### SUBNET CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################

resource "aws_subnet" "eks-private-one" {
  assign_ipv6_address_on_creation                = false
  availability_zone                              = "eu-central-1a"
  cidr_block                                     = "10.0.0.0/20"

  tags = {
    Name     = "eks-private-one"
    solution = "eks"
  }
  tags_all = {
    Name     = "eks-private-one"
    solution = "eks"
  }
  vpc_id = aws_vpc.eks.id
}




resource "aws_subnet" "eks-private-two" {
  assign_ipv6_address_on_creation                = false
  availability_zone                              = "eu-central-1b"
  cidr_block                                     = "10.0.16.0/20"
  tags = {
    Name     = "eks-private-two"
    solution = "eks"
  }
  tags_all = {
    Name     = "eks-private-two"
    solution = "eks"
  }
  vpc_id = aws_vpc.eks.id
}

resource "aws_subnet" "eks-public-one" {
  assign_ipv6_address_on_creation                = false
  availability_zone                              = "eu-central-1a"
  cidr_block                                     = "10.0.32.0/20"
  tags = {
    Name     = "eks-public-one"
    solution = "eks"
  }
  tags_all = {
    Name     = "eks-public-one"
    solution = "eks"
  }
  vpc_id = aws_vpc.eks.id
}

resource "aws_subnet" "eks-public-two" {
  assign_ipv6_address_on_creation                = false
  availability_zone                              = "eu-central-1b"
  cidr_block                                     = "10.0.48.0/20"
  tags = {
    Name     = "eks-public-two"
    solution = "eks"
  }
  tags_all = {
    Name     = "eks-public-two"
    solution = "eks"
  }
  vpc_id = aws_vpc.eks.id
}


################################################################################################################### NETWORK ACL CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################

resource "aws_network_acl" "eks-private" {
  egress = [{
    action          = "allow"
    cidr_block      = "0.0.0.0/0"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 100
    to_port         = 0
  }]
  ingress = [{
    action          = "allow"
    cidr_block      = "0.0.0.0/0"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 100
    to_port         = 0
  }]
  subnet_ids = [aws_subnet.eks-private-one.id, aws_subnet.eks-private-two.id]
  tags = {
    Name     = "eks-private"
    solution = "eks"
  }
  tags_all = {
    Name     = "eks-private"
    solution = "eks"
  }
  vpc_id = aws_vpc.eks.id
}


resource "aws_network_acl" "eks-public" {
  vpc_id = aws_vpc.eks.id
  subnet_ids       = [aws_subnet.eks-public-one.id, aws_subnet.eks-public-two.id]
  tags = {
    Name = "eks-public"
  }
  tags_all = {
    Name = "eks-public"
  }
  egress = [{
    action          = "allow"
    cidr_block      = "0.0.0.0/0"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 100
    to_port         = 0
  }]

  ingress = [{
    action          = "allow"
    cidr_block      = "0.0.0.0/0"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = null
    protocol        = "-1"
    rule_no         = 100
    to_port         = 0
  }]
}





################################################################################################################### INTERNET GATEWAY CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################





resource "aws_internet_gateway" "eks-internet-gateway" {
  tags = {
    Name     = "eks-internet-gateway"
    solution = "eks"
  }
  tags_all = {
    Name     = "eks-internet-gateway"
    solution = "eks"
  }
  vpc_id = aws_vpc.eks.id
}

################################################################################################################### NAT GATEWAY CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################

resource "aws_eip" "nat" {
  
}

resource "aws_nat_gateway" "eks-nat-gateway" {
  subnet_id                          = aws_subnet.eks-public-one.id
  allocation_id = aws_eip.nat.id
  tags = {
    Name     = "eks-nat-gateway"
    solution = "eks"
  }
  tags_all = {
    Name     = "eks-nat-gateway"
    solution = "eks"
  }
}

################################################################################################################### ROUTE TABLE CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################
resource "aws_route_table" "eks-private" {
  route = [{
    cidr_block                 = "0.0.0.0/0"
    nat_gateway_id             = aws_nat_gateway.eks-nat-gateway.id
    carrier_gateway_id = ""
    core_network_arn = ""
    destination_prefix_list_id = ""
    egress_only_gateway_id = ""
    ipv6_cidr_block = null
    local_gateway_id = ""
    gateway_id = ""
    network_interface_id = ""
    transit_gateway_id = ""
    vpc_endpoint_id = ""
    vpc_peering_connection_id = ""
    
  }]
  
  tags = {
    Name = "eks-private"
  }
  tags_all = {
    Name = "eks-private"
  }
  vpc_id = aws_vpc.eks.id
  
}

resource "aws_route_table" "eks-public" {
  
  route = [{
    cidr_block                 = "0.0.0.0/0"
    gateway_id                 = aws_internet_gateway.eks-internet-gateway.id
    carrier_gateway_id = ""
    core_network_arn = ""
    destination_prefix_list_id = ""
    egress_only_gateway_id = ""
    ipv6_cidr_block = null
    local_gateway_id = ""
    nat_gateway_id = ""
    network_interface_id = ""
    transit_gateway_id = ""
    vpc_endpoint_id = ""
    vpc_peering_connection_id = ""
    
  }]
  tags = {
    Name     = "eks-public"
    solution = "eks"
  }
  tags_all = {
    Name     = "eks-public"
    solution = "eks"
  }
  vpc_id = aws_vpc.eks.id
}
################################################################################################################### ROUTE TABLE ASSOCIATION CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################


resource "aws_route_table_association" "eks-private-one" {
  subnet_id      = aws_subnet.eks-private-one.id
  route_table_id = aws_route_table.eks-private.id
}

resource "aws_route_table_association" "eks-private-two" {
  subnet_id      = aws_subnet.eks-private-two.id
  route_table_id = aws_route_table.eks-private.id
}


resource "aws_route_table_association" "eks-public-one" {
  subnet_id      = aws_subnet.eks-public-one.id
  route_table_id = aws_route_table.eks-public.id
}

resource "aws_route_table_association" "eks-public-two" {
  subnet_id      = aws_subnet.eks-public-two.id
  route_table_id = aws_route_table.eks-public.id
}

################################################################################################################### SECURITY GROUP CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################


resource "aws_security_group" "eks-public" {
  description = "ssh"
  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 443
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 443
    }, {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 80
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 80
    }, {
    cidr_blocks      = ["10.0.0.0/16"]
    description      = ""
    from_port        = 22
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 22
  }]
  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 5432
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 5432
  }]
  name                   = "eks-public"
  name_prefix            = null
  revoke_rules_on_delete = null
  tags = {
    Name     = "eks-public"
    solution = "eks"
  }
  tags_all = {
    Name     = "eks-public"
    solution = "eks"
  }
  vpc_id = aws_vpc.eks.id
}


resource "aws_security_group" "eks-private" {
  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
  }]
  ingress = [{
    cidr_blocks      = ["10.0.0.0/16"]
    description      = ""
    from_port        = 22
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 22
    }, {
    cidr_blocks      = []
    description      = ""
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = true
    to_port          = 0
  }]
  name                   = "eks-private"
  name_prefix            = null
  revoke_rules_on_delete = null
  tags = {
    Name = "eks-private"
  }
  tags_all = {
    Name = "eks-private"
  }
  vpc_id = aws_vpc.eks.id
}


################################################################################################################### CLUSTER CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################

resource "aws_eks_cluster" "eks" {
  bootstrap_self_managed_addons = false
  enabled_cluster_log_types     = ["api", "audit"]
  name                          = "eks"
  role_arn                      = aws_iam_role.eksClusterRole.arn
  tags = {
    solution = "eks"
    "alpha.eksctl.io/cluster-oidc-enabled" = "true"
  }
  tags_all = {
    solution = "eks"
    "alpha.eksctl.io/cluster-oidc-enabled" = "true"
  }
  version = "1.31"
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
  kubernetes_network_config {
    ip_family         = "ipv4"
    service_ipv4_cidr = "172.16.0.0/12"
  }
  upgrade_policy {
    support_type = "STANDARD"
  }
  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
    security_group_ids      = []
    subnet_ids              = [aws_subnet.eks-private-one.id, aws_subnet.eks-private-two.id]
  }
  zonal_shift_config {
    enabled = true
  }
}

################################################################################################################### NODE GROUP CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################

resource "aws_eks_node_group" "eks" {
  ami_type             = "AL2_x86_64"
  capacity_type        = "ON_DEMAND"
  cluster_name         = aws_eks_cluster.eks.name
  disk_size            = 20
  force_update_version = null
  instance_types       = ["t3.2xlarge"]
  labels = {
    solution = "eks"
  }
  node_group_name        = "eks"
  node_group_name_prefix = null
  node_role_arn          = aws_iam_role.eks-node-role.arn
  subnet_ids             = [aws_subnet.eks-private-one.id, aws_subnet.eks-private-two.id]
  tags                   = {}
  tags_all               = {}
  version                = "1.31"
  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }
  update_config {
    max_unavailable            = 1
  }
  depends_on = [ aws_eks_cluster.eks ]
}

################################################################################################################### CLUSTER MISSCELANOUS CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################

resource "aws_eks_access_entry" "root" {
  cluster_name      =  aws_eks_cluster.eks.name
  kubernetes_groups = []
  principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  tags              = {}
  tags_all          = {}
  type              = "STANDARD"
  user_name         = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
}


resource "aws_eks_access_policy_association" "root" {
  cluster_name  = aws_eks_cluster.eks.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"

  access_scope {
    type       = "cluster"
  }
  depends_on = [ aws_eks_cluster.eks,aws_eks_access_entry.root ]
}


################################################################################################################### CLUSTER ROLE AND POLICIES CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eksClusterRole" {
  name               = "eksClusterRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "eksClusterRole-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eksClusterRole.name
}


resource "aws_iam_role_policy_attachment" "eksClusterRole-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eksClusterRole.name
}




################################################################################################################### NODE GROUP  ROLE AND POLICIES CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################


data "aws_iam_policy_document" "assume_role_1" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com","ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role" "eks-node-role" {
  name               = "eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_1.json
}

resource "aws_iam_role_policy_attachment" "eks-node-role-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-node-role.name
}


resource "aws_iam_role_policy_attachment" "eks-node-role-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-node-role.name
}

resource "aws_iam_role_policy_attachment" "eks-node-role-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-node-role.name
}


resource "aws_iam_role_policy_attachment" "eks-node-role-AmazonElasticFileSystemFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
  role       = aws_iam_role.eks-node-role.name
}


resource "aws_iam_role_policy_attachment" "eks-node-role-AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks-node-role.name
}


################################################################################################################### ADDONS CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################


resource "aws_eks_addon" "vpc-cni" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "vpc-cni"
  resolve_conflicts_on_update = "PRESERVE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "coredns"
  resolve_conflicts_on_update = "PRESERVE"
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_update = "PRESERVE"
}

resource "aws_eks_addon" "eks-pod-identity-agent" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_update = "PRESERVE"
}


resource "aws_eks_addon" "aws-ebs-csi-driver" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_update = "PRESERVE"
}

################################################################################################################### STREAMLIT IMAGE PUSH CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################

resource "aws_ecr_repository" "streamlit" {
  name                 = "streamlit"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "null_resource" "build_and_push_docker_image" {
          triggers = {
            always_run = timestamp()
          }

          provisioner "local-exec" {
            command = <<EOT
              docker build --platform linux/amd64 -t ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.streamlit.name}:${var.image_tag} ../streamlit
              aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com
              docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.streamlit.name}:${var.image_tag}
            EOT
          }
          depends_on         = [ aws_ecr_repository.streamlit]
}

################################################################################################################### SECRET STORE CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################

resource "aws_iam_role" "aws-eks-secret-role" {
  name = "aws-eks-secret-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:aud" = "sts.amazonaws.com"
            "${var.oidc_provider}:sub" = "system:serviceaccount:default:${var.service_account}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "SecretsManagerReadWrite" {
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  role       = aws_iam_role.aws-eks-secret-role.name
}


################################################################################################################### DATABASE CONFIGURATION #########################################################################################
#######################################################################################################################################################################################################################################

resource "aws_db_subnet_group" "eks-public" {
  description = "public"
  name        = "eks-public"
  name_prefix = null
  subnet_ids  = [ aws_subnet.eks-public-one.id, aws_subnet.eks-public-two.id]
  tags        = {}
  tags_all    = {}
}


resource "aws_db_parameter_group" "ssl_disable" {
  description  = "disable ssl authentication"
  family       = "postgres16"
  name         = "ssl-disable"
  name_prefix  = null
  skip_destroy = false
  parameter {
    apply_method = "immediate"
    name         = "rds.force_ssl"
    value        = "0"
  }
}


resource "aws_db_instance" "llm_eks" {
  allocated_storage                     = 20
  auto_minor_version_upgrade            = false
  availability_zone                     = "eu-central-1b"
  db_name                               = "postgres"
  db_subnet_group_name                  = aws_db_subnet_group.eks-public.name
  deletion_protection                   = false
  engine                                = "postgres"
  engine_version                        = "16.1"
  identifier                            = "llm-eks"
  instance_class                        = "db.t3.small"
  max_allocated_storage                 = 100
  monitoring_interval                   = 0
  network_type                          = "IPV4"
  option_group_name                     = "default:postgres-16"
  parameter_group_name                  = aws_db_parameter_group.ssl_disable.name
  password                              = var.db_password
  port                                  = 5432
  publicly_accessible                   = true
  storage_type                          = "gp3"
  username                              = "postgres"
  vpc_security_group_ids                = [aws_security_group.eks-public.id]
  skip_final_snapshot                   = true
}