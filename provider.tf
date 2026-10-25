# ==================================
# Terraform & Provider Configuration
# ==================================
# Провайдер cloud.ru Evolution не опубликован в registry.terraform.io.
# Бинарник лежит локально: ~/.terraform.d/plugins/cloud.ru/cloudru/cloud/<версия>/darwin_arm64/
# Ключ доступа сервисного аккаунта берётся из переменных окружения AUTH_KEY_ID / AUTH_SECRET
# (файл ~/.cloudru.env), project_id — из TF_VAR_project_id.

terraform {
  required_providers {
    cloudru = {
      source  = "cloud.ru/cloudru/cloud"
      version = "2.1.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
  }
  required_version = ">= 1.5"
}

provider "cloudru" {
  project_id = var.project_id
}
