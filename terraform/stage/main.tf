provider "google" {
  version = "2.0.0"
  project = "${var.project}"
  region  = "${var.region}"
}

module "app" {
  source              = "../modules/app"
  public_key_path     = "${var.public_key_path}"
  private_key_path    = "${var.private_key_path}"
  zone                = "${var.zone}"
  app_disk_image      = "${var.app_disk_image}"
  db_url              = "${module.db.db_internal_ip}"
  enable_provisioners = "${var.enable_provisoners}"
  env                 = "${var.env}"
}

module "db" {
  source              = "../modules/db"
  public_key_path     = "${var.public_key_path}"
  private_key_path    = "${var.private_key_path}"
  zone                = "${var.zone}"
  db_disk_image       = "${var.db_disk_image}"
  enable_provisioners = "${var.enable_provisoners}"
  env                 = "${var.env}"
}

module "vpc" {
  source        = "../modules/vpc"
  source_ranges = "${var.source_ranges}"
}

