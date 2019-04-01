variable project {
  # Описание переменной
  description = "Project ID"
}

variable region {
  description = "Region"

  # Значение по умолчанию
  default = "europe-west3"
}

variable zone {
  description = "Zone"

  # Значение по умолчанию
  default = "europe-west3-a"
}

variable public_key_path {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}

variable private_key_path {
  # Описание переменной
  description = "Path to the private key used for ssh access"
}

variable disk_image {
  # Описание переменной
  description = "Disk image"
}

variable worker_count {
  # Описание переменной
  description = "Number of workers"
  default     = "1"
}
