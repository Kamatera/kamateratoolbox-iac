resource "null_resource" "deploy_cert_manager" {
  triggers = {
    v = "1"
  }
  provisioner "local-exec" {
    command = <<-EOF
      ${var.set_context} &&\
      kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.3/cert-manager.yaml
    EOF
  }
}

resource "kubernetes_manifest" "cluster_issuer_letsencrypt" {
  depends_on = [null_resource.deploy_cert_manager]
  manifest = yamldecode(<<-EOF
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt
    spec:
      acme:
        email: ${var.letsencrypt_email}
        server: https://acme-v02.api.letsencrypt.org/directory
        privateKeySecretRef:
          name: letsencrypt
        solvers:
          - http01:
              ingress:
                class: traefik
EOF
)
}