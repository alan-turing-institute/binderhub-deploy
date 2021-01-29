output "acr_id" {
  value = length(module.container_registry) > 0 ? module.container_registry[0].acr_id : ""
}

output "acr_login_server" {
  value = length(module.container_registry) > 0 ? module.container_registry[0].acr_login_server : ""
}
