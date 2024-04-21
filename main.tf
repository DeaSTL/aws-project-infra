provider "aws" {
  region = "us-east-1"
}

module "ec2-east" {
   source = "./ec2"
   name = "personal-projects"
   ami = "ami-07d9b9ddc6cd8dd30"
   route_zone_id = "Z05859407AHEY4L0BH7B"
   domain = "aws.jmhart.dev"
   services = [
    {
      name = "Nate Stream Bingo"
      external_port = 3000,
      internal_port = 3000,
      domain = "ns-bingo",
      image = "ghcr.io/nate-incubator/ns-bingo:latest"
    },
    {
      name = "HTMX Agario"
      external_port = 3001,
      internal_port = 8080,
      domain = "htmx-agario-test",
      image = "jhartway99/htmx-agario:latest"
    }
   ]
}

