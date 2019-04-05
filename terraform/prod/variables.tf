variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default     = "europe-west3"
}

variable zone {
  description = "Zone"
  default     = "europe-west3-a"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable private_key_path {
  description = "Path to the privat key used to connect to instance"
}

variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}

variable db_disk_image {
  description = "Disk image for reddit db"
  default     = "reddit-db-base"
}

variable source_ranges {
  description = "Allowed IP addresses"
  default     = ["0.0.0.0/0"]
}

variable db_url {
  description = "DATABASE URL"
  default     = "127.0.0.1"
}

variable enable_provisoners {
  description = "Enable provisioners 1-true, 0-false (dafault)"
  default     = "0"
}

variable env {
  description = "Environment"
  default     = "stage"
}

