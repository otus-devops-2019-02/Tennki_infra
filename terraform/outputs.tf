output "app_external_ip" {
  value = "${google_compute_instance.app.network_interface.0.access_config.0.nat_ip}"
}

output "app-pool_external_ip" {
  value = "${google_compute_instance.app-pool.*.network_interface.0.access_config.0.nat_ip}"
}

output "lb_external_ip" {
  value = "${google_compute_global_address.lb-ip.address}"
}

