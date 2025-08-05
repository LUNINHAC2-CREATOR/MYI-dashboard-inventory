# prometheus.tf
resource "docker_image" "prometheus" {
  name         = "prom/prometheus:latest"
  keep_locally = true
}

resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = docker_image.prometheus.image_id
  restart = "always"

  ports {
    internal = 9090
    external = 9090
  }

  volumes {
    host_path      = "${path.module}/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
  }

  # Dependência implícita no cadvisor
  depends_on = [docker_container.cadvisor]
}

# Configuração do Prometheus (crie um arquivo prometheus.yml no mesmo diretório)
resource "local_file" "prometheus_config" {
  filename = "${path.module}/prometheus.yml"
  content  = <<-EOT
  global:
    scrape_interval: 15s

  scrape_configs:
    - job_name: 'cadvisor'
      static_configs:
        - targets: ['${replace(docker_container.cadvisor.ip_address, "/\\[|\\]/", "")}:8080']
  EOT
}
