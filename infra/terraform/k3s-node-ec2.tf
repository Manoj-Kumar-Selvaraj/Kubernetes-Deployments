resource "aws_vpc" "k3s_vpc" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "k3s_subnet" {
  vpc_id                  = aws_vpc.k3s_vpc.id
  cidr_block              = "172.16.10.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

resource "aws_internet_gateway" "k3s_igw" {
  vpc_id = aws_vpc.k3s_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "k3s_public_rt" {
  vpc_id = aws_vpc.k3s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k3s_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "k3s_public_subnet" {
  subnet_id      = aws_subnet.k3s_subnet.id
  route_table_id = aws_route_table.k3s_public_rt.id
}

resource "aws_security_group" "k3s_node" {
  name        = "${var.project_name}-node-sg"
  description = "Allow SSH and web access to the k3s node"
  vpc_id      = aws_vpc.k3s_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    description = "Kubernetes NodePort services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.nodeport_allowed_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-node-sg"
  }
}

resource "aws_network_interface" "k3s_ni" {
  subnet_id       = aws_subnet.k3s_subnet.id
  private_ips     = ["172.16.10.100"]
  security_groups = [aws_security_group.k3s_node.id]

  tags = {
    Name = "${var.project_name}-node-eni"
  }
}

resource "aws_eip" "k3s_node" {
  domain            = "vpc"
  network_interface = aws_network_interface.k3s_ni.id

  depends_on = [aws_internet_gateway.k3s_igw]

  tags = {
    Name = "${var.project_name}-node-eip"
  }
}

resource "aws_key_pair" "k3s_node" {
  key_name   = var.key_pair_name
  public_key = var.ssh_public_key
}

resource "aws_instance" "k3s_node_instance" {
  ami                         = data.aws_ami.ubuntu_22_04.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.k3s_node.key_name
  monitoring                  = true
  user_data_replace_on_change = true

  network_interface {
    network_interface_id = aws_network_interface.k3s_ni.id
    device_index         = 0
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  volume_tags = {
    Name = "${var.project_name}-node-root"
  }

  user_data = templatefile("${path.module}/templates/k3s-ansible-init.sh.tftpl", {
    k3s_install_channel = var.k3s_install_channel
    ssh_public_key      = var.ssh_public_key
  })

  tags = {
    Name = "${var.project_name}-node"
  }

  depends_on = [
    aws_eip.k3s_node,
    aws_route_table_association.k3s_public_subnet
  ]

  disable_api_termination = true
}
