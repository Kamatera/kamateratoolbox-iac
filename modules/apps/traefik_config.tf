resource "kubernetes_manifest" "traefik_helm_config" {
  manifest = yamldecode(<<-EOF
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    deployment:
      replicas: 3
    additionalArguments:
      - "--entrypoints.websecure.transport.respondingtimeouts.readtimeout=240s"
EOF
)
}
