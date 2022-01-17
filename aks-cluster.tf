resource "random_pet" "prefix" {}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "default" {
  name     = "${random_pet.prefix.id}-rg"
  location = "East US 2"

  tags = {
    environment = "Demo"
  }
}
resource "azurerm_kubernetes_cluster" "default" {
  name                = "${random_pet.prefix.id}-aks"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = "${random_pet.prefix.id}-k8s"
  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "standard_d2_v5"
    os_disk_size_gb = 30
  }
  service_principal {
    client_id     = var.appId
    client_secret = var.password
  }

  role_based_access_control {
    enabled = true
  }

  tags = {
    environment = "Demo"
  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.default.kube_config.0.host
  username               = azurerm_kubernetes_cluster.default.kube_config.0.username
  password               = azurerm_kubernetes_cluster.default.kube_config.0.password
  client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
}

resource "kubectl_manifest" "secret1" {
    yaml_body = file("./kubernetes/secrets.yaml")
    depends_on = [azurerm_kubernetes_cluster.default]
}
resource "kubectl_manifest" "volume1" {
    yaml_body = file("./kubernetes/persistent-volumes.yaml")
     depends_on = [azurerm_kubernetes_cluster.default]
}
resource "kubectl_manifest" "db1" {
    yaml_body = file("./kubernetes/mariadb-deployment.yaml")
     depends_on = [azurerm_kubernetes_cluster.default]
}
resource "kubectl_manifest" "app1" {
    yaml_body = file("./kubernetes/app-deployment.yaml")
     depends_on = [azurerm_kubernetes_cluster.default]
}
resource "kubectl_manifest" "dbsvc1" {
    yaml_body = file("./kubernetes/mariadb-svc.yaml")
     depends_on = [azurerm_kubernetes_cluster.default]
}
resource "kubectl_manifest" "websvc1" {
    yaml_body = file("./kubernetes/web-service.yaml")
     depends_on = [azurerm_kubernetes_cluster.default]
}

