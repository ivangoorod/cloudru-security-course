# ===============
# VPC Resources
# ===============

resource "cloudru_evolution_vpc_vpc" "network" {
  project_id  = var.project_id
  name        = var.vpc_name
  description = "Сеть интернет-магазина Незабудка"
}

resource "cloudru_evolution_compute_subnet" "subnet_a" {
  project_id     = var.project_id
  name           = "nezabudka-subnet-a"
  zone           = { name = var.zone }
  vpc_id         = cloudru_evolution_vpc_vpc.network.id
  subnet_address = var.subnet_cidr
  routed_network = true
  default        = false

  # Только внешний DNS: внутренний (dc01) каждой ВМ прописывается через systemd-resolved в cloud-init.
  # С двумя адресами провайдер 2.1.5 падает — API возвращает список в другом порядке.
  dns_servers = {
    value = [var.upstream_dns]
  }
}

# ===============
# Security Group
# ===============
# В лабе 1 по сценарию курса все порты открыты — их закрывают в лабе 2
# («Группы безопасности»). В cloud.ru интерфейс без группы безопасности не создаётся,
# поэтому здесь явная группа «всё разрешено».

resource "cloudru_evolution_compute_security_group" "allow_all" {
  project_id  = var.project_id
  name        = "lab1-allow-all"
  zone        = { name = var.zone }
  description = "Lab 1: all ports open (closed in lab 2)"
}

locals {
  allow_all_rules = {
    in_tcp  = ["TRAFFIC_DIRECTION_INGRESS", "IP_PROTOCOL_TCP"]
    in_udp  = ["TRAFFIC_DIRECTION_INGRESS", "IP_PROTOCOL_UDP"]
    out_tcp = ["TRAFFIC_DIRECTION_EGRESS", "IP_PROTOCOL_TCP"]
    out_udp = ["TRAFFIC_DIRECTION_EGRESS", "IP_PROTOCOL_UDP"]
  }
}

resource "cloudru_evolution_compute_security_group_rule" "allow_all" {
  for_each = local.allow_all_rules

  security_group_id = cloudru_evolution_compute_security_group.allow_all.id
  direction         = each.value[0]
  ether_type        = "ETHER_TYPE_IPV4"
  ip_protocol       = each.value[1]
  port_range        = "1:65535"
  remote_ip_prefix  = "0.0.0.0/0"
  description       = "lab1 ${each.key}"
}
