# Выделяем статический ip для балансера
resource "google_compute_global_address" "lb-ip" {
  name = "lb-ip"
}

# Создаем группу инстансов 
resource "google_compute_instance_group" "reddit-app-group" {
  name = "reddit-app-group"
  # Указываем ВМ, которые будет входить в группу
  instances = [
    "${google_compute_instance.app.self_link}",
    "${google_compute_instance.app-pool.*.self_link}",
     
  ]

  zone = "${var.zone}"
  # Указываем имя и порт, на котором принимают запросы наши ВМ
  named_port {
    name = "app"
    port = "9292"
  }
}

# Создаем правило пересылки с ip балансировщика на http прокси 
resource "google_compute_global_forwarding_rule" "lb-forwarding-rule" {
  name       = "lb-forwarding-rule"
  ip_address = "${google_compute_global_address.lb-ip.address}"
  port_range = "80"
  target     = "${google_compute_target_http_proxy.lb-http-proxy.self_link}"
}

# Создаем TargetHttpProxy для правила пересылки
resource "google_compute_target_http_proxy" "lb-http-proxy" {
  name    = "lb-http-proxy"
  url_map = "${google_compute_url_map.lb-url-map.self_link}"
}

# Создаем балансировщик
resource "google_compute_url_map" "lb-url-map" {
  name            = "lb-url-map"
  default_service = "${google_compute_backend_service.lb-backend-service.self_link}"
}

# Бэкенд сервис 
resource "google_compute_backend_service" "lb-backend-service" {
  name      = "lb-backend-service"
  port_name = "app"
  # Группа инстансов, которая обслуживает запросы
  backend {
    group = "${google_compute_instance_group.reddit-app-group.self_link}"
  }
  # Проверка состояния сервиса
  health_checks = ["${google_compute_health_check.lb-health-check.self_link}"]
}

# Простой healthcheck сервиса на ВМ 
resource "google_compute_health_check" "lb-health-check" {
  name = "lb-health-check"

  tcp_health_check {
    port = "9292"
  }
}
