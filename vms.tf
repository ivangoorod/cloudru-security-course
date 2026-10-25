data "cloudru_evolution_compute_image_collection" "images" {
  project_id = var.project_id
}

locals {
  image_id = one([
    for img in data.cloudru_evolution_compute_image_collection.images.images : img.id
    if img.name == var.image_name
  ])

  # dc01 — Keycloak + DNS + PKI, opencartshop2 — магазин OpenCart, ws — рабочая станция
  vms = {
    (var.keycloak_name) = { ip = cidrhost(var.subnet_cidr, 10), disk = 20 }
    opencartshop2       = { ip = cidrhost(var.subnet_cidr, 20), disk = 20 }
    (var.ws_name)       = { ip = cidrhost(var.subnet_cidr, 30), disk = 20 }
  }

  openssl_root_b64         = base64encode(file("${path.module}/init/openssl.cnf"))
  openssl_intermediate_b64 = base64encode(file("${path.module}/init/intermediate/openssl.cnf"))
  realm_b64 = base64encode(templatefile("${path.module}/init/realm.json.tpl", {
    realm  = var.kc_realm
    domain = var.domain_fqdn
  }))

  ssh_key = chomp(tls_private_key.ssh.public_key_openssh)

  user_data = {
    (var.keycloak_name) = templatefile("${path.module}/init/kc-install.yml", {
      ssh_key                  = local.ssh_key
      hostname                 = var.keycloak_name
      domain                   = var.domain_fqdn
      upstream_dns             = var.upstream_dns
      subnet_cidr              = var.subnet_cidr
      ip                       = local.vms[var.keycloak_name].ip
      hosts_zone_b64           = base64encode(join("", [for name, vm in local.vms : "${name}  IN  A  ${vm.ip}\n"]))
      kc_ver                   = var.kc_ver
      kc_port                  = var.kc_port
      kc_adm_user              = var.kc_adm_user
      kc_adm_pass              = var.kc_adm_pass
      pg_db_name               = var.pg_db_name
      pg_db_user               = var.pg_db_user
      pg_db_pass               = var.pg_db_pass
      openssl_root_b64         = local.openssl_root_b64
      openssl_intermediate_b64 = local.openssl_intermediate_b64
      realm_b64                = local.realm_b64
    })
    opencartshop2 = templatefile("${path.module}/init/opencart-install.yaml", {
      ssh_key  = local.ssh_key
      hostname = "opencartshop2"
      domain   = var.domain_fqdn
      dns_ip   = local.vms[var.keycloak_name].ip
    })
    (var.ws_name) = templatefile("${path.module}/init/ws-install.yml", {
      ssh_key  = local.ssh_key
      hostname = var.ws_name
      domain   = var.domain_fqdn
      dns_ip   = local.vms[var.keycloak_name].ip
    })
  }
}

resource "cloudru_evolution_compute_disk" "boot" {
  for_each = local.vms

  project_id = var.project_id
  name       = "${each.key}-boot"
  zone       = { name = var.zone }
  disk_type  = { name = var.disk_type }
  size       = each.value.disk
  image      = { id = local.image_id }
  bootable   = true
  encrypted  = false
  readonly   = false
  shared     = false
}

resource "cloudru_evolution_compute_external_ip" "public" {
  for_each = local.vms

  project_id = var.project_id
  name       = "${each.key}-public-ip"
  zone       = { name = var.zone }
}

resource "cloudru_evolution_compute_interface" "nic" {
  for_each = local.vms

  project_id                 = var.project_id
  name                       = "${each.key}-nic"
  zone                       = { name = var.zone }
  subnet                     = { id = cloudru_evolution_compute_subnet.subnet_a.id }
  ip_address                 = each.value.ip
  type                       = "INTERFACE_TYPE_REGULAR"
  interface_security_enabled = true
  security_groups            = [{ id = cloudru_evolution_compute_security_group.allow_all.id }]
  attach_external_ip         = { id = cloudru_evolution_compute_external_ip.public[each.key].id }
}

resource "cloudru_evolution_compute_vm" "vm" {
  for_each = local.vms

  project_id          = var.project_id
  name                = each.key
  zone                = { name = var.zone }
  flavor              = { name = var.flavors[each.key] }
  disks               = [{ id = cloudru_evolution_compute_disk.boot[each.key].id }]
  network_interfaces  = [{ id = cloudru_evolution_compute_interface.nic[each.key].id }]
  cloud_init_userdata = base64encode(local.user_data[each.key])

  depends_on = [local_file.private_key]
}

#Create ssh key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/pt_key.pem"
  file_permission = "0600"
}
