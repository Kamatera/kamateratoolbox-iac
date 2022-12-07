data "external" "data" {
  working_dir = path.cwd
  program = ["python3", "modules/common/external_data_command/bin/terraform_external_data_cmd.py"]
  query = {
    script = var.script
  }
}
