# Prometheus를 배포하는 Helm 차트
resource "helm_release" "prometheus" {
  provider    = helm
  name        = "prometheus"
  repository  = "https://prometheus-community.github.io/helm-charts"
  chart       = "prometheus"


  namespace   = kubernetes_namespace.prometheus.metadata.0.name
  depends_on = [kubernetes_namespace.prometheus]

  set {
    name  = "server.service.type"
    value = "NodePort"
  }
}

resource "kubernetes_namespace" "prometheus" {
  provider = kubernetes
  metadata {
    name = "prometheus"
  }
}