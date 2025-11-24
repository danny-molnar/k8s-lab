resource "kubernetes_namespace" "platform" {
  metadata { name = "platform" }
}

resource "kubernetes_namespace" "apps_dev" {
  metadata { name = "apps-dev" }
}

#########################################
# ingress-nginx (Ingress controller)
#########################################

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.platform.metadata[0].name

  values = [
    yamlencode({
      controller = {
        ingressClassResource = {
          enabled = true
          name    = "nginx"
          default = true
        }
        service = {
          type = "NodePort"
        }
      }
    })
  ]
}

#########################################
# metrics-server
#########################################

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = kubernetes_namespace.platform.metadata[0].name

  depends_on = [helm_release.ingress_nginx]

  values = [
    yamlencode({
      args = [
        "--kubelet-insecure-tls",
        "--kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP",
      ]
    })
  ]
}

#########################################
# kube-prometheus stack
#########################################

resource "helm_release" "kube_prometheus" {
  name       = "kube-prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.platform.metadata[0].name

  depends_on = [
    helm_release.ingress_nginx,
    helm_release.metrics_server,
  ]
}
