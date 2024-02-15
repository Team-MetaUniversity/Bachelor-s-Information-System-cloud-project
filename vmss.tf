#vmss
#기존 네트워크 참조
data "azurerm_virtual_network" "vmss_vnet" {
  name                = "kc-vnet"
  resource_group_name = azurerm_resource_group.rg.name
}

data "azurerm_subnet" "vmss_subnet" {
  name                 = "aks-subnet"
  virtual_network_name = data.azurerm_virtual_network.vmss_vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}

# 공용 IP 주소 - Load Balancer 용
resource "azurerm_public_ip" "lb_public_ip" {
  name                = "lb-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Load Balancer
resource "azurerm_lb" "vmss_lb" {
  name                = "vmss-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "publicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }
}

# Load Balancer 백엔드 주소 풀
resource "azurerm_lb_backend_address_pool" "vmss_backend_pool" {
  loadbalancer_id = azurerm_lb.vmss_lb.id
  name            = "vmssBackendPool"
}

# Linux Virtual Machine Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "vmss-class"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard_DS1_v2"
  instances           = 2
  admin_username      = var.username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.username
    public_key = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = data.azurerm_subnet.vmss_subnet.id #참조한 서브넷 또 참조

      # Load Balancer 백엔드 주소 풀 연결
      #load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.vmss_backend_pool.id]
    }
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
