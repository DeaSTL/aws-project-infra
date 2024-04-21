provider "acme" {
  #server_url = "https://acme-v02.api.letsencrypt.org/directory"
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
}

data "aws_route53_zone" "base_domain" {
  name = "${var.domain}" 
}

resource "tls_private_key" "private_key" {
   algorithm = "RSA"
   rsa_bits = 2048
}

resource "acme_registration" "registration" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address = "jhartway99@gmail.com"
}


resource "aws_route53_record" "route" {
  for_each = toset([for service in var.services : service.domain])
  zone_id = var.route_zone_id
  name = each.value
  type = "A"
  ttl = "300"
  records = [aws_instance.instance.public_ip]
}


resource "acme_certificate" "certificate" {
  account_key_pem           = acme_registration.registration.account_key_pem
  common_name               = data.aws_route53_zone.base_domain.name
  subject_alternative_names = ["*.${data.aws_route53_zone.base_domain.name}"]

  dns_challenge {
    provider = "route53"
    config = {
      AWS_HOSTED_ZONE_ID = var.route_zone_id
    }
  }

  depends_on = [acme_registration.registration]
}

resource "aws_vpc" "main_vpc" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main_subnet" {
    vpc_id            = aws_vpc.main_vpc.id
    availability_zone = "us-east-1a"
    cidr_block = "10.0.0.0/16"
    map_public_ip_on_launch = true
}

resource "aws_security_group" "main_sg" {
  name = "main_sg"
  description = "Allow 8080,443,80"

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "main_sg"
  }
}

resource "aws_key_pair" "main_key_pair" {
  key_name = "main_key_pair"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "instance" {
  ami = var.ami
  instance_type = "t2.micro"
  key_name = aws_key_pair.main_key_pair.key_name
  tags = {
    Name = var.name
  }
  security_groups = [aws_security_group.main_sg.name]

  user_data = templatefile("${path.module}/cloud-init.yaml",
  {
    ssh_key:"${aws_key_pair.main_key_pair.public_key}",
    private_key = nonsensitive(lookup(acme_certificate.certificate, "private_key_pem")),
    cert = lookup(acme_certificate.certificate, "certificate_pem"),
    base_domain = "${data.aws_route53_zone.base_domain.name}",
    services = var.services
  })

  depends_on = [acme_certificate.certificate]
}


