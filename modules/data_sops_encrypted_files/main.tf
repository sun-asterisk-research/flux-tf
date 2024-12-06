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

variable "encrypted_regex" {
  type     = string
  default  = ""
}

variable "unencrypted_regex" {
  type     = string
  default  = ""
}

variable "encrypted_suffix" {
  type     = string
  default  = ""
}

variable "unencrypted_suffix" {
  type     = string
  default  = ""
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
    encrypt_flags='--indent 2 --input-type ${local.input_type} --output-type ${local.output_type}'

    if [ -n "${var.recipients.age}" ]; then
      encrypt_flags="$encrypt_flags --age ${var.recipients.age}"
    fi

    if [ -n "${var.recipients.gcp_kms}" ]; then
      encrypt_flags="$encrypt_flags --gcp-kms ${var.recipients.gcp_kms}"
    fi

    if [ -n "${var.recipients.kms}" ]; then
      encrypt_flags="$encrypt_flags --kms ${var.recipients.kms}"
    fi

    if [ -n "${var.recipients.pgp}" ]; then
      encrypt_flags="$encrypt_flags --pgp ${var.recipients.pgp}"
    fi

    if [ -n "${var.encrypted_regex}" ]; then
      encrypt_flags="$encrypt_flags --encrypted-regex ${var.encrypted_regex}"
    fi

    if [ -n "${var.unencrypted_regex}" ]; then
      encrypt_flags="$encrypt_flags --unencrypted-regex ${var.unencrypted_regex}"
    fi

    if [ -n "${var.encrypted_suffix}" ]; then
      encrypt_flags="$encrypt_flags --encrypted-suffix ${var.encrypted_suffix}"
    fi

    if [ -n "${var.unencrypted_suffix}" ]; then
      encrypt_flags="$encrypt_flags --unencrypted-suffix ${var.unencrypted_suffix}"
    fi

    result="$(sed -n 's/.*"input"[ \t]*:[ \t]*"\([^"]*\)".*/\1/p' \
      | base64 --decode  \
      | sops --encrypt $encrypt_flags /dev/stdin
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
