variable "project_id" {
  description = "ID проекта cloud.ru Evolution"
  type        = string
}

variable "zone" {
  description = "Зона доступности"
  type        = string
  default     = "ru.AZ-1"
}

variable "vpc_name" {
  type    = string
  default = "nezabudka-vpc"
}

variable "subnet_cidr" {
  type    = string
  default = "10.60.1.0/24"
}

variable "upstream_dns" {
  description = "Внешний DNS, куда dc01 пересылает запросы вне домена лабы"
  type        = string
  default     = "8.8.8.8"
}

variable "image_name" {
  description = "Публичный образ для всех ВМ"
  type        = string
  default     = "ubuntu-22.04"
}

variable "disk_type" {
  type    = string
  default = "SSD"
}

# lowcost10-2-4 — 2 vCPU с долей 10% и 4 ГБ RAM (самый дешёвый вариант 2/4).
# Если конфигурация окажется недоступна, варианты: low-2-4 (1:3) или gen-2-4 (100%).
variable "flavors" {
  type = map(string)
  default = {
    dc01          = "lowcost10-2-4"
    opencartshop2 = "lowcost10-2-4"
    ws            = "lowcost10-2-4"
  }
}

#-----------------------------------------
variable "keycloak_name" {
  type = string
}

variable "ws_name" {
  type = string
}

variable "domain_fqdn" {
  type = string
}

variable "kc_realm" {
  description = "Keycloak Realm name"
  type        = string
}

variable "kc_ver" {
  description = "Keycloak version"
  type        = string
}

variable "kc_port" {
  description = "Keycloak HTTPS port listener"
  type        = string
}

variable "kc_adm_user" {
  description = "Keycloak admin user name"
  type        = string
}

variable "kc_adm_pass" {
  description = "Keycloak admin user password"
  type        = string
  sensitive   = true

  validation {
    condition = (
      length(var.kc_adm_pass) >= 8 &&
      can(regex("[a-z]", var.kc_adm_pass)) &&
      can(regex("[A-Z]", var.kc_adm_pass)) &&
      can(regex("[0-9]", var.kc_adm_pass)) &&
      can(regex("[@#%&*/:;,.?+=_-]", var.kc_adm_pass)) &&
      !can(regex("[\"'`$\\\\ ]", var.kc_adm_pass))
    )
    error_message = "Не короче 8 символов: строчные и заглавные буквы, цифра и спецсимвол из @#%&*/:;,.?+=-_ (кавычки, $, обратный слеш и пробел не допускаются)."
  }
}

variable "pg_db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "keycloak"
}

variable "pg_db_user" {
  description = "PostgreSQL database user name"
  type        = string
}

variable "pg_db_pass" {
  description = "PostgreSQL database user's password"
  type        = string
  sensitive   = true

  validation {
    condition = (
      length(var.pg_db_pass) >= 8 &&
      can(regex("[a-z]", var.pg_db_pass)) &&
      can(regex("[A-Z]", var.pg_db_pass)) &&
      can(regex("[0-9]", var.pg_db_pass)) &&
      can(regex("[@#%&*/:;,.?+=_-]", var.pg_db_pass)) &&
      !can(regex("[\"'`$\\\\ ]", var.pg_db_pass))
    )
    error_message = "Не короче 8 символов: строчные и заглавные буквы, цифра и спецсимвол из @#%&*/:;,.?+=-_ (кавычки, $, обратный слеш и пробел не допускаются)."
  }
}
