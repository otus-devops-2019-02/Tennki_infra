resource "google_compute_instance" "db" {
  name         = "${var.env}-reddit-db"
  machine_type = "g1-small"
  zone         = "${var.zone}"
  tags         = ["reddit-db", "${var.env}"]

  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }

  boot_disk {
    initialize_params {
      image = "${var.db_disk_image}"
    }
  }

  network_interface {
    network       = "default"
    access_config = {}
  }

  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
  }

  #  provisioner "remote-exec" {
  #    inline =[
  #      "sudo sed -i '/bindIp/s/^/#/g' /etc/mongod.conf",
  #      "sudo systemctl restart mongod.service"
  #    ]
  #  }
  provisioner "remote-exec" {
    inline = [
      "${element(list("echo","sudo sed -i '/bindIp/s/^/#/g' /etc/mongod.conf"),var.enable_provisioners)}",
      "${element(list("echo","sudo systemctl restart mongod.service"),var.enable_provisioners)}",
    ]
  }
}

resource "google_compute_firewall" "firewall_mongo" {
  name    = "allow-mongo-default"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["27017"]
  }

  source_tags = ["reddit-app"]
  target_tags = ["reddit-db"]
}

