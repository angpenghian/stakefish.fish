# Output the Public IP of the VM
output "runner" {
  value = azurerm_public_ip.instance.ip_address
  description = "The public IP address of the VM to SSH into."
}

# Output the AKS cluster connection information (kubeconfig)
output "aks_cluster_kubeconfig" {
  value = azurerm_kubernetes_cluster.instance.kube_config_raw
  description = "The kubeconfig content to connect to the AKS cluster."
  sensitive = true
}
