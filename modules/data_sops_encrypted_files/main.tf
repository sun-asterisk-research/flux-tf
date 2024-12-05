terraform {
  required_version = ">=1.8"
}

variable "filename" {
  type     = string
  default  = null
  nullable = true
}

variable "content_base64" {
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

variable "recipients" {
  type = object({
    age     = string
    gcp_kms = string
    kms     = string
    pgp     = string
  })
}

locals {
  input  = var.content_base64 != null ? var.content_base64 : filebase64(var.filename)
  file_ext = replace(var.filename, "/.*\\.([\\w]+)$/", "$1")

  input_type = var.input_type != null ? var.input_type : try({
    "yaml" = "yaml"
    "yml"  = "yaml"
    "json" = "json"
  }[local.file_ext], "binary")

  output_type = var.output_type != null ? var.output_type : local.input_type
}

data "external" "encrypted_files" {
  program = [
    "sh",
    "-c",
    <<-EOT
    result="$(sed -n 's/.*"input"[ \t]*:[ \t]*"\([^"]*\)".*/\1/p' \
      | base64 --decode  \
      | sops --encrypt --age ${var.recipients.age} --indent 2 --input-type ${local.input_type} --output-type ${local.output_type} /dev/stdin
    )"
    status=$?
    if [ $status -ne 0 ]; then
      exit $status
    fi

    echo "$result" \
      | base64 -w0 \
      | awk -v status="$status" '{print "{\"output\": \"" $0 "\", \"status\": \"" status "\"}"}'
    EOT
  ]

  query = {
    input = local.input
  }
}

output "content" {
  value     = base64decode(data.external.encrypted_files.result.output)
  sensitive = true
}

output "is_valid" {
  value = data.external.encrypted_files.result.status == "0"
}
