### Terraform Configuration Explained

This Terraform configuration file is structured to provision a robust infrastructure on Google Cloud Platform (GCP) with a focus on security, scalability, and availability. Each component in the configuration serves a specific purpose, enabling streamlined deployment and management of the application. Below, I’ll break down each block, explaining the commands, what they create, and the purpose behind each resource.

---

#### Provider Block
```hcl
provider "google" {
  credentials = file("terraform-sa-key.json")
  project     = var.gcp_project_id
  region      = "us-east4"
  zone        = "us-east4-c"
}
```
**Purpose**: This block configures the GCP provider for Terraform. It:
- Authenticates using a service account key (`terraform-sa-key.json`).
- Defines the GCP project, region, and zone where resources will be deployed.

**Reason**: This setup ensures all resources are created within the same project and region, essential for network connectivity, latency, and cost optimization.

---

#### IP Address Resource
```hcl
resource "google_compute_global_address" "ip_address" {
  name = "${var.app_name}-ip-${terraform.workspace}"
}
```
**Creates**: A global static IP address.

**Reason**: This IP is required for routing internet traffic to the application and for creating DNS A records that point to this address.

---

#### Network Block
```hcl
data "google_compute_network" "default" {
  name = "default"
}
```
**Purpose**: Accesses the default network for GCP.

**Reason**: Using the default network allows all resources to be deployed within an existing network structure, simplifying configuration.

---

#### Firewall Rules
```hcl
resource "google_compute_firewall" "allow_http" { ... }
resource "google_compute_firewall" "allow_ssh" { ... }
```
- **allow_http**: Opens ports `80` and `443` for HTTP and HTTPS traffic.
- **allow_ssh**: Opens port `22` for SSH access.

**Reason**: These firewall rules are crucial for both public access to the application and secure SSH access for maintenance. Tags link the firewall rules to specific instances.

---

#### Health Check Resource
```hcl
resource "google_compute_health_check" "default" {
  name               = "${var.app_name}-health-check-${terraform.workspace}"
  check_interval_sec = 5
  timeout_sec        = 5
  http_health_check {
    port = 80
  }
}
```
**Creates**: A health check that monitors HTTP responses on port `80`.

**Reason**: Ensures the load balancer only routes traffic to healthy instances, improving reliability and user experience.

---

#### Compute Instance
```hcl
resource "google_compute_instance" "app_instance" { ... }
```
**Creates**: A single VM instance to run the application.

- **Machine type**: Defined by `var.gcp_machine_type`.
- **Tags**: Used to associate this instance with firewall rules.
- **Startup script**: Installs the Google Cloud Ops Agent for monitoring and logging.

**Reason**: This VM instance hosts the application, with access to logging and monitoring for enhanced visibility.

---

#### Unmanaged Instance Group
```hcl
resource "google_compute_instance_group" "unmanaged_group" { ... }
```
**Creates**: An unmanaged instance group containing the VM instance.

**Reason**: Enables load balancing across a group of instances, even if they're managed manually.

---

#### SSL Certificate
```hcl
resource "google_compute_managed_ssl_certificate" "default" {
  name = "${var.app_name}-ssl-cert-${terraform.workspace}"
  managed {
    domains = [var.domain_name]
  }
}
```
**Creates**: A managed SSL certificate.

**Reason**: Provides encrypted HTTPS access for the application, improving security and meeting best practices for modern web applications.

---

#### Backend Service
```hcl
resource "google_compute_backend_service" "default" { ... }
```
**Creates**: A backend service that links the instance group with the load balancer.

**Reason**: The backend service directs HTTP traffic to the instance group and allows setting up additional configurations such as health checks.

---

#### URL Map
```hcl
resource "google_compute_url_map" "default" { ... }
```
**Creates**: A URL map to associate specific paths with backend services.

**Reason**: Directs incoming requests to the backend service, enabling traffic management based on paths if needed.

---

#### HTTPS Proxy
```hcl
resource "google_compute_target_https_proxy" "default" { ... }
```
**Creates**: An HTTPS proxy to handle HTTPS requests.

**Reason**: The HTTPS proxy works with the SSL certificate and URL map to securely route traffic to the application.

---

#### Global Forwarding Rule
```hcl
resource "google_compute_global_forwarding_rule" "default" { ... }
```
**Creates**: A forwarding rule that links the IP address to the HTTPS proxy, listening on port `443`.

**Reason**: The forwarding rule ensures that requests to the application’s domain are routed to the correct backend service, enabling global reach.

---

#### DNS Zone and DNS Record
```hcl
resource "google_dns_managed_zone" "default" { ... }
resource "google_dns_record_set" "default" { ... }
```
- **DNS Zone**: Creates a managed DNS zone for the specified domain.
- **DNS Record**: Configures an A record to point to the global IP address.

**Reason**: These resources ensure the application’s domain points to the infrastructure, making it accessible via a friendly URL.

---

#### OS Image Data Source
```hcl
data "google_compute_image" "cos_image" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}
```
**Purpose**: Retrieves the latest image of Ubuntu 22.04 for the VM.

**Reason**: Using a standard, updated OS image ensures compatibility with Google Cloud services and security updates.

---

### Summary
This infrastructure setup provisions a scalable and secure GCP environment with:
- **VM Instances** for application hosting.
- **Managed SSL and HTTPS** for secure access.
- **Firewall Rules and Health Checks** to protect and monitor the environment.
- **DNS Configuration** for custom domain access.

Each resource works together to provide a reliable and production-ready infrastructure for deploying web applications on GCP.