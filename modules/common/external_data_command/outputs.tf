output "output" {
  value = jsondecode(data.external.data.result.output)
}
