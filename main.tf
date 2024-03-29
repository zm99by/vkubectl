// Create a managed instance group
provider "google" {
  project = "develop-409117"
  region  = "us-central1"
}


resource "google_compute_instance_template" "default" {
  name = "lb-backend-template"
  disk {
    auto_delete  = true
    boot         = true
    device_name  = "persistent-disk-0"
    mode         = "READ_WRITE"
    source_image = "projects/debian-cloud/global/images/family/debian-11"
    type         = "PERSISTENT"
  }
  labels = {
    managed-by-cnrm = "true"
  }
  machine_type = "n1-standard-1"
  metadata = {
    startup-script = <<EOF
  #!/bin/bash

  # Обновите пакеты
  sudo apt-get update

  # Установите необходимые пакеты
  sudo apt-get install -y openjdk-11-jdk wget

  # Добавьте ключ и репозиторий Jenkins
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5BA31D57EF5975CA

  wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
  sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5BA31D57EF5975CA


  # Обновите информацию пакетах и установите Jenkins
  sudo apt-get update
  sudo apt-get install -y jenkins

  # Запустите службу Jenkins
  sudo systemctl start jenkins

  # Убедитесь, что служба Jenkins запускается при загрузке системы
  sudo systemctl enable jenkins
  EOF
  }

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }
    network    = "global/networks/default"
    subnetwork = "regions/us-east1/subnetworks/default"
  }
  region = "us-east1"
  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }
  service_account {
    email  = "default"
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/pubsub", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }
  tags = ["allow-health-check", "jenkins-instance" ]
}


//Create the managed instance group and select the instance template.
resource "google_compute_instance_group_manager" "default" {
  name = "lb-backend-example"
  zone = "us-east1-b"
  named_port {
    name = "http"
    port = 80
  }

  named_port {
    name = "http-alt"
    port = 8080
  }


  version {
    instance_template = google_compute_instance_template.default.id
    name              = "primary"
  }
  base_instance_name = "vm"
  target_size        = 1
}

//Configure a firewall rule

resource "google_compute_firewall" "default" {
  name          = "fw-allow-health-check"
  direction     = "INGRESS"
  network       = "global/networks/default"
  priority      = 1000
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["allow-health-check"]
  allow {
    ports    = ["8080"]
    protocol = "tcp"
  }
}

//Reserve an external IP address

resource "google_compute_global_address" "default" {
  name       = "lb-ipv4-1"
  ip_version = "IPV4"
}

//Create the health check

resource "google_compute_health_check" "default" {
  name               = "http-basic-check"
  check_interval_sec = 5
  healthy_threshold  = 2
  http_health_check {
    port               = 8080
    port_specification = "USE_FIXED_PORT"
    proxy_header       = "NONE"
    request_path       = "/"
  }
  timeout_sec         = 5
  unhealthy_threshold = 2
}

//create the backend service

resource "google_compute_backend_service" "default" {
  name                            = "web-backend-service"
  connection_draining_timeout_sec = 0
  health_checks                   = [google_compute_health_check.default.id]
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  port_name                       = "http"
  protocol                        = "HTTP"
  session_affinity                = "NONE"
  timeout_sec                     = 30
  backend {
    group           = google_compute_instance_group_manager.default.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

//create the URL map

resource "google_compute_url_map" "default" {
  name            = "web-map-http"
  default_service = google_compute_backend_service.default.id
}

//create the target HTTP proxy

resource "google_compute_target_http_proxy" "default" {
  name    = "http-lb-proxy"
  url_map = google_compute_url_map.default.id
}

//create the forwarding rule

resource "google_compute_global_forwarding_rule" "default" {
  name                  = "http-content-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "8080"
  target                = google_compute_target_http_proxy.default.id
  ip_address            = google_compute_global_address.default.id
}


