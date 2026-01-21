# EC2 Key Pair (create this manually or use existing)
variable "key_pair_name" {
  description = "Name of existing EC2 key pair for SSH access"
  type        = string
  default     = "bb-sdk-keypair"
}

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# API Server EC2
resource "aws_instance" "api_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.api_server.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = var.key_pair_name

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              dnf update -y
              
              # Install Node.js 18
              dnf install -y nodejs npm
              
              # Install PM2, nginx
              npm install -g pm2 yarn
              dnf install -y nginx
              
              # Enable nginx
              systemctl enable nginx
              systemctl start nginx
              EOF

  tags = {
    Name = "${var.project_name}-api-server"
    Role = "API"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
}

# Media Server EC2
resource "aws_instance" "media_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.media_server.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = var.key_pair_name

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              dnf update -y
              
              # Install development tools
              dnf groupinstall -y "Development Tools"
              dnf install -y git wget
              
              # Install Rust
              curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
              
              # Install GStreamer
              dnf install -y gstreamer1 gstreamer1-plugins-base gstreamer1-plugins-good \
                gstreamer1-plugins-bad-free gstreamer1-plugins-ugly-free gstreamer1-devel glib2-devel gstreamer1-plugins-base-devel protobuf-compiler
              
              # Install PostgreSQL client
              dnf install -y postgresql15 libpq-devel
              EOF

  tags = {
    Name = "${var.project_name}-media-server"
    Role = "Media"
  }

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }
}

# Elastic IPs for stable addresses
resource "aws_eip" "api_server" {
  instance = aws_instance.api_server.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-api-eip"
  }
}

resource "aws_eip" "media_server" {
  instance = aws_instance.media_server.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-media-eip"
  }
}
