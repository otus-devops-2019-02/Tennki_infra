variable public_key_path {
  description = "Path to the public key used to connect to instance"
}

variable private_key_path {
  description = "Path to the privat key used to connect to instance"
}

variable zone {
  description = "Zone"
}

variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}

variable db_url {
  description = "DATABASE URL"
  default     = "127.0.0.1"
}

variable enable_provisioners {
  description = "Enable provisioners 1-true, 0-false (dafault)"
  default     = "0"
}

variable env {
  description = "Environment"
}

