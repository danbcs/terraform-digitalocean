terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# For download the provider run terraform init
provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "ssh_key" {
  name = var.ssh_key_name
}

# Create a server/droplet for Jenkins run terraform apply
resource "digitalocean_droplet" "jenkins" {
  image    = "ubuntu-22-04-x64"
  name     = "jenkins"
  region   = var.region
  size     = "s-2vcpu-2gb"
  ssh_keys = [data.digitalocean_ssh_key.ssh_key.id]
}

# Create a cluster kubernetes with 2 nodes run terraform apply
resource "digitalocean_kubernetes_cluster" "k8s" {
  name   = "k8s"
  region = var.region
  # Grab the latest version slug from `doctl kubernetes options versions`
  version = "1.24.4-do.0"

  node_pool {
    name       = "default"
    size       = "s-2vcpu-2gb"
    node_count = 2
  }
}
# Create variables for terraform with terraform.tfvars
variable "region" {
  default = ""
}

variable "do_token" {
  default = ""
}

variable "ssh_key_name" {
  default = ""
}

# Return the value IPV4 from server created
output "jenkins-ip" {
    value = digitalocean_droplet.jenkins.ipv4_address
}

# Create file with kube_config in local
resource "local_file" "kube_config" {
    content = digitalocean_kubernetes_cluster.k8s.kube_config.0.raw_config
    filename = "kube_config.yaml"
}