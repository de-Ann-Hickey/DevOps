# Create my mgmt instance with ansible, docker, kali linux
data "google_compute_image" "mgmt_image" {
  name    = "centos-stream-9-v20220920"
  project = "centos-cloud"
}
resource "google_compute_instance" "mgmt-vm" {
  name         = "mgmt-vm"
  machine_type = "n2d-standard-2"
  allow_stopping_for_update = true
  min_cpu_platform = "AMD Rome"
  zone         = "us-west3-c"
  tags         = ["ssh"]

  metadata = {
    enable-oslogin = "TRUE"
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.mgmt_image.self_link
      size = 50
    }
  }

  # Install ansible
  metadata_startup_script = "sudo yum update -y; sudo yum install -y git yum-utils epel-release ansible; sudo yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine; sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo; sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin"

  network_interface {
    network = "default"
    access_config {
      # Include this section to give the VM an external IP address
    }
  }
}
# Create my nagios instance
data "google_compute_image" "nagios_image" {
  name    = "cis-centos-linux-7-level-1-v3-1-2-10"
  project = "cis-public"
}
resource "google_compute_instance" "nagios-vm" {
  name         = "nagios-vm"
  machine_type = "n1-standard-1"
  zone         = "us-west3-c"
  tags         = ["web", "ssh"]

  metadata = {
    enable-oslogin = "TRUE"
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.nagios_image.self_link
      size = 30
    }
  }

  # Install packages needed for nagios. I'll do the rest in ansible
  metadata_startup_script = "sudo yum update -y; sudo yum install -y gcc glibc glibc-common gd gd-devel net-snmp openssl-devel wget unzip"

  network_interface {
    network = "default"
    access_config {
      # Include this section to give the VM an external IP address
    }
  }
}

# install my jenkins web server. I will install jenkins software with my ansible vm
data "google_compute_image" "nginx_image" {
  name    = "cis-nginx-centos-linux-7-level-1-v1-1-0-33"
  project = "cis-public"
}

resource "google_compute_instance" "nginx-vm" {
  name         = "jenkins-vm"
  machine_type = "n1-standard-1"
  zone         = "us-west3-c"
  tags         = ["jenkins", "web", "ssh"]

  metadata = {
    enable-oslogin = "TRUE"
  }
  
  boot_disk {
    initialize_params {
      image = data.google_compute_image.nginx_image.self_link
      size = 30
    }
  }

  # 
  metadata_startup_script = "sudo yum update -y"

  network_interface {
    network = "default"
    access_config {
      # Include this section to give the VM an external IP address
    }
  }
}

#create firewall rules for these servers
resource "google_compute_firewall" "web_rule" {
  name        = "web-firewall-rule"
  network     = "default"
  description = "Creates firewall rule for web tags"

  allow {
    protocol  = "tcp"
    ports     = ["80"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["web"]
}
resource "google_compute_firewall" "ssh_rule" {
  name        = "ssh-firewall-rule"
  network     = "default"
  description = "Creates firewall rule for ssh tags"

  allow {
    protocol  = "tcp"
    ports     = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["ssh"]
}
resource "google_compute_firewall" "jenk_rule" {
  name        = "jenk-firewall-rule"
  network     = "default"
  description = "Creates firewall rule for jenkins tags"

  allow {
    protocol  = "tcp"
    ports     = ["8080"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["jenkins"]
}