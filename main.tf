provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-hello-azure-tf"
    storage_account_name = "genryhelloazuretf"
    container_name       = "terraform-state"
    key                  = "terraform.tfstate"
  }
}

### ---------- RESOURCE GROUP ---------------

resource "azurerm_resource_group" "rgfrontend" {
  name     = "team4-rg-frontend"
  location = local.location
}

resource "azurerm_resource_group" "rgbackend" {
  name     = "team4-rg-backend"
  location = local.location
}

### ---------- APP PLAN ---------------

resource "azurerm_app_service_plan" "planfrontend" {
  name                = "team4-plan-frontend"
  location            = local.location
  resource_group_name = azurerm_resource_group.rgfrontend.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service_plan" "planbackend" {
  name                = "team4-plan-backend"
  location            = local.location
  resource_group_name = azurerm_resource_group.rgbackend.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

### ---------- APP WEB ---------------

resource "azurerm_app_service" "appfrontend" {
  name                = "team4-web-frontend"
  location            = local.location
  resource_group_name = azurerm_resource_group.rgfrontend.name
  app_service_plan_id = azurerm_app_service_plan.planfrontend.id
}

resource "azurerm_app_service" "appbackend" {
  name                = "team4-web-backend"
  location            = local.location
  resource_group_name = azurerm_resource_group.rgbackend.name
  app_service_plan_id = azurerm_app_service_plan.planbackend.id
}


### ---------- CDN ---------------

resource "azurerm_cdn_profile" "cdnprofile" {
  name                = "team4-cdn-profile"
  location            = local.location
  resource_group_name = azurerm_resource_group.rgfrontend.name
  sku                 = "Standard_Verizon"
}

resource "azurerm_cdn_endpoint" "cdnendpoint" {
  name                = "team4-cdn-endpoint"
  profile_name        = azurerm_cdn_profile.cdnprofile.name
  location            = local.location
  resource_group_name = azurerm_resource_group.rgfrontend.name

  origin {
    name      = "cdng4instagram"
    host_name = "www.cdng4instagram.com"
  }
}

### ---------- SERVICEBUS ---------------

resource "azurerm_servicebus_namespace" "servicebus" {
  name                = "team4-servicebus-namespace"
  location            = local.location
  resource_group_name = azurerm_resource_group.rgbackend.name
  sku                 = "Standard"

  tags = {
    # source = "terraform"
  }
}

resource "azurerm_servicebus_queue" "servicebusqueue" {
  name                = "team4-servicebus-queue"
  resource_group_name = azurerm_resource_group.rgbackend.name
  namespace_name      = azurerm_servicebus_namespace.servicebus.name

  enable_partitioning = true
}

### ---------- COSMOSDB ---------------

resource "azurerm_storage_account" "storageaccount" {
  name                     = "t4c2storageaccountt4c2"
  resource_group_name      = azurerm_resource_group.rgbackend.name
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource  "azurerm_cosmosdb_account" "cosmosdbaccount" {
  name                = "team4-cosmosdb"
  resource_group_name = azurerm_resource_group.rgbackend.name
  location            = local.location
  offer_type          = "Standard"
  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }
  geo_location {
    location          = local.location
    failover_priority = 0
  }
}

# resource "azurerm_cosmosdb_mongo_database" "mongodb" {
#   name                = "team4-mongodb"
#   resource_group_name = azurerm_resource_group.rgbackend.name
#   account_name        = azurerm_cosmosdb_account.cosmosdbaccount.name
# }

# resource "azurerm_cosmosdb_mongo_collection" "collection" {
#   name                = "team4-collection"
#   resource_group_name = azurerm_resource_group.rgbackend.name
#   account_name        = azurerm_cosmosdb_account.cosmosdbaccount.name
#   database_name       = azurerm_cosmosdb_mongo_database.mongodb.name
#   default_ttl_seconds = "777"
#   shard_key           = "uniqueKey"
#   throughput          = 400
# }