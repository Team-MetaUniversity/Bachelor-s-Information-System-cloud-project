output "gateway_frontend_ip" {
  value = "http://${azurerm_public_ip.appgw_public_ip.ip_address}"
}

