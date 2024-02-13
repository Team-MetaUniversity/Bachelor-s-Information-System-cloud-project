# 리소스 그룹
resource "azurerm_resource_group" "rg" {
  name     = "rg-aks"
  location = "Korea Central"
}

# 가상 네트워크
resource "azurerm_virtual_network" "vnet" {
  name                = "kc-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 서브넷 - AKS
resource "azurerm_subnet" "subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.2.0/24"]
}

# 서브넷 - Application Gateway
resource "azurerm_subnet" "appgw_subnet" {
  name                 = "kc-agw-svnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "random_pet" "azurerm_kubernetes_cluster_dns_prefix" {
  prefix = "dns"
}

# AKS 클러스터
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = random_pet.azurerm_kubernetes_cluster_dns_prefix.id


  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
    enable_node_public_ip = true # 노드에 Public IP 할당 활성화
    vnet_subnet_id = azurerm_subnet.subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  linux_profile {
    admin_username = "adminuser"
    ssh_key {
        key_data = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
    }
  }

    ingress_application_gateway {
      gateway_id = azurerm_application_gateway.appgw.id
    }
}

# 애플리케이션 게이트웨이용 공용 IP 주소
resource "azurerm_public_ip" "appgw_public_ip" {
  name                = "appgw-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 애플리케이션 게이트웨이
resource "azurerm_application_gateway" "appgw" {
  name                = "aks-appgw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration {
    min_capacity = 2
    max_capacity = 5
  }

  gateway_ip_configuration {
    name      = "appgw-ip-configuration"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_port {
    name = "appgw-http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.appgw_public_ip.id
  }

  backend_address_pool {
    name = var.backend_address_pool_name 
  }

  backend_http_settings {
    name                  = var.http_setting_name 
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = var.listener_name 
    frontend_ip_configuration_name = "appgw-frontend-ip-configuration" 
    frontend_port_name             = "appgw-http-port" 
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = var.request_routing_rule_name 
    rule_type                  = "Basic"
    http_listener_name         = var.listener_name 
    backend_address_pool_name  = var.backend_address_pool_name 
    backend_http_settings_name = var.http_setting_name 
    priority                   = 1
  }
}



#ACR 생성
resource "azurerm_container_registry" "acr" {
  name                = "MetaAcr" 
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic" # 또는 필요에 맞는 다른 SKU
  admin_enabled       = false
}

# AKS 클러스터에 ACR 접근 권한 부여
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# AKS 클러스터 자격 증명 가져오기
data "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster"
  resource_group_name = "rg-aks"
}

