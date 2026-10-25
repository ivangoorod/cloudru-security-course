locals {
  public_ip = { for name, ip in cloudru_evolution_compute_external_ip.public : name => ip.ip_address }
}

output "keycloak_address" {
  value = local.public_ip[var.keycloak_name]
}

output "opencart_address" {
  value = local.public_ip["opencartshop2"]
}

output "ws_address" {
  value = local.public_ip[var.ws_name]
}

output "internal_ips" {
  value = { for name, vm in local.vms : name => vm.ip }
}

output "instructions" {
  value = <<-EOT
    SSH:
      dc01:          ssh -i pt_key.pem ubuntu@${local.public_ip[var.keycloak_name]}
      ws:            ssh -i pt_key.pem sles@${local.public_ip[var.ws_name]}
      opencartshop2: ssh -i pt_key.pem yc-user@${local.public_ip["opencartshop2"]}

    OpenCart: откройте http://${local.public_ip["opencartshop2"]}/ и пройдите установщик.
    Значения Username / Database / Password для шага с базой данных:
      ssh -i pt_key.pem -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null yc-user@${local.public_ip["opencartshop2"]} cat /tmp/default_passwords.txt

    VNC (ws): после ssh на ws выполните
      vncserver -geometry 1200x800 -depth 32 -name remote-desktop :1
    и подключитесь VNC-клиентом к ${local.public_ip[var.ws_name]}:5901

    Ход установки на каждой ВМ: /var/log/lab-prep.log
  EOT
}
