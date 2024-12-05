terraform {
  required_version = ">=1.8"
}

variable "filename" {
  type     = string
  default  = null
  nullable = true
}

variable "content" {
  type     = string
  default  = null
  nullable = true
}

variable "input_type" {
  type     = string
  default  = null
  nullable = true

  validation {
    condition     = var.input_type == null || can(index(["json", "yaml", "binary"], var.input_type))
    error_message = "Input type must be either 'json', 'yaml' or 'binary'"
  }
}

variable "output_type" {
  type     = string
  default  = null
  nullable = true

  validation {
    condition     = var.output_type == null || can(index(["json", "yaml", "binary"], var.output_type))
    error_message = "Input type must be either 'json', 'yaml' or 'binary'"
  }
}

locals {
  input  = var.content != null ? var.content : file(var.filename)
  file_ext = var.filename != null ? replace(var.filename, "/.*\\.([\\w]+)$/", "$1") : null

  input_type = var.input_type != null ? var.input_type : try({
    "yaml" = "yaml"
    "yml"  = "yaml"
    "json" = "json"
  }[local.file_ext], "binary")

  output_type = var.output_type != null ? var.output_type : local.input_type
}

data "external" "decrypted_files" {
  program = [
    "sh",
    "-c",
    <<-EOT
    result="$(sed -n 's/.*"input"[ \t]*:[ \t]*"\([^"]*\)".*/\1/p' \
      | base64 --decode \
      | sops --decrypt --indent 2 --input-type ${local.input_type} --output-type ${local.output_type} /dev/stdin \
    )"
    status=$?
    if [ $status -ne 0 ]; then
      exit $status
    fi

    echo "$result" \
      | base64 -w0 \
      | awk -v status="$?" '{print "{\"output\": \"" $0 "\", \"status\": \"" status "\"}"}'
    EOT
  ]

  query = {
    input = base64encode(local.input)
  }
}

output "content_base64" {
  value     = data.external.decrypted_files.result.output
  sensitive = true
}

output "is_valid" {
  value = data.external.decrypted_files.result.status == "0"
}
