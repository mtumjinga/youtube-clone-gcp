provider "google" {
  credentials = file("terraform-sa-key.json")
  project     = var.gcp_project_id
  region      = "us-east4"
  zone        = "us-east4-c"
}

# IP ADDRESS
resource "google_compute_global_address" "ip_address" {
  name = "${var.app_name}-ip-${terraform.workspace}"
}

# NETWORK
data "google_compute_network" "default" {
  name = "default"
}

# FIREWALL RULES
resource "google_compute_firewall" "allow_http" {
  name    = "${var.app_name}-allow-http-${terraform.workspace}"
  network = data.google_compute_network.default.name
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.app_name}-allow-http-ssh-${terraform.workspace}"]
}
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.app_name}-allow-ssh-${terraform.workspace}"
  network = data.google_compute_network.default.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.app_name}-allow-http-ssh-${terraform.workspace}"]
}

# HEALTH CHECK
resource "google_compute_health_check" "default" {
  name               = "${var.app_name}-health-check-${terraform.workspace}"
  check_interval_sec = 5
  timeout_sec        = 5
  http_health_check {
    port = 80
  }
}

# SINGLE VM INSTANCE
resource "google_compute_instance" "app_instance" {
  name         = "${var.app_name}-instance-${terraform.workspace}"
  machine_type = var.gcp_machine_type
  zone         = "us-east4-c"
  tags         = ["${var.app_name}-allow-http-ssh-${terraform.workspace}"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.cos_image.self_link
    }
  }

  network_interface {
    network = data.google_compute_network.default.name
    access_config {
      // Ephemeral IP
    }
  }

  service_account {
    scopes = ["storage-ro","logging-write","monitoring-write","monitoring-read","monitoring"]
  }

   metadata_startup_script = <<-EOF
    #!/bin/bash
   curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
   sudo bash add-google-cloud-ops-agent-repo.sh --also-install
  EOF
}

# UNMANAGED INSTANCE GROUP
resource "google_compute_instance_group" "unmanaged_group" {
  name = "${var.app_name}-unmanaged-group-${terraform.workspace}"
  zone = "us-east4-c"
  instances = [google_compute_instance.app_instance.self_link]
  named_port {
    name = "http"
    port = 80
  }
}

# SSL CERTIFICATE
resource "google_compute_managed_ssl_certificate" "default" {
  name = "${var.app_name}-ssl-cert-${terraform.workspace}"
  managed {
    domains = ["markbosire.click"]
  }
}

# BACKEND SERVICE
resource "google_compute_backend_service" "default" {
  name                            = "${var.app_name}-backend-service-${terraform.workspace}"
  protocol                        = "HTTP"
  port_name                       = "http"
  timeout_sec                     = 10
  enable_cdn                      = true
  custom_request_headers          = []
  custom_response_headers         = []
  health_checks                   = [google_compute_health_check.default.id]
  
  backend {
    group = google_compute_instance_group.unmanaged_group.self_link
  }
}

# URL MAP
resource "google_compute_url_map" "default" {
  name            = "${var.app_name}-url-map-${terraform.workspace}"
  default_service = google_compute_backend_service.default.id
}

# HTTPS PROXY
resource "google_compute_target_https_proxy" "default" {
  name             = "${var.app_name}-https-proxy-${terraform.workspace}"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}

# FORWARDING RULE
resource "google_compute_global_forwarding_rule" "default" {
  name                  = "${var.app_name}-forwarding-rule-${terraform.workspace}"
  ip_address            = google_compute_global_address.ip_address.address
  port_range            = "443"
  target                = google_compute_target_https_proxy.default.id
  load_balancing_scheme = "EXTERNAL"
}

# DNS ZONE
resource "google_dns_managed_zone" "default" {
  name        = "${var.app_name}-dns-zone-${terraform.workspace}"
  dns_name    = "markbosire.click."
  description = "DNS zone for markbosire.click"
}

# DNS RECORD
resource "google_dns_record_set" "default" {
  name         = "markbosire.click."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.default.name
  rrdatas      = [google_compute_global_address.ip_address.address]
}

# OS IMAGE
data "google_compute_image" "cos_image" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}
