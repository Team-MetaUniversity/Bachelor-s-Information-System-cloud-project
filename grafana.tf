resource "helm_release" "grafana" {
  provider    = helm
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"


  namespace  = kubernetes_namespace.grafana.metadata.0.name
  depends_on = [kubernetes_namespace.grafana]

  set {
    name  = "service.type"
    value = "NodePort"  
  }
}

resource "kubernetes_namespace" "grafana" {
  provider = kubernetes
  metadata {
    name = "grafana"
  }
}