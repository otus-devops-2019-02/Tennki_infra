resource "google_compute_instance" "app" {
  name         = "${var.env}-reddit-app"
  machine_type = "g1-small"
  zone         = "${var.zone}"
  tags         = ["reddit-app", "${var.env}"]

  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }

  boot_disk {
    initialize_params {
      image = "${var.app_disk_image}"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = "${google_compute_address.app_ip.address}"
    }
  }

  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
  }

  #  provisioner "file" {    
  #    source      = "${path.module}/files/puma.service"
  #    destination = "/tmp/puma.service"
  #  }
  #  provisioner "remote-exec" {       
  #    inline =["sudo sed -i '/ExecStart/iEnvironment=\"DATABASE_URL=${var.db_url}\"' /tmp/puma.service"]
  #  }
  #  provisioner "remote-exec" {    
  #    script = "${path.module}/files/deploy.sh"
  #  }

  provisioner "file" {
    # В зависимости от значения enable_provisioners подставляем в source null.sh или puma.service
    source      = "${element(list("${path.module}/files/null.sh","${path.module}/files/puma.service"),var.enable_provisioners)}"
    destination = "/tmp/puma.service"
  }
  provisioner "remote-exec" {
    inline = ["${element(list("echo","sudo sed -i '/ExecStart/iEnvironment=\"DATABASE_URL=${var.db_url}\"' /tmp/puma.service"),var.enable_provisioners)}"]
  }
  provisioner "remote-exec" {
    script = "${element(list("${path.module}/files/null.sh","${path.module}/files/deploy.sh"),var.enable_provisioners)}"
  }
}

resource "google_compute_address" "app_ip" {
  name = "reddit-app-ip"
}

resource "google_compute_firewall" "firewall_puma" {
  name    = "allow-puma-default"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["reddit-app"]
}

