output "instance_public_ip" {
  description = "Public IP address of the k3s EC2 instance"
  value       = aws_eip.k3s_node.public_ip
}

output "key_pair_name" {
  description = "AWS EC2 key pair attached to the k3s instance"
  value       = aws_key_pair.k3s_node.key_name
}

output "key_pair_fingerprint" {
  description = "AWS key pair fingerprint for the registered SSH public key"
  value       = aws_key_pair.k3s_node.fingerprint
}

output "ssh_command" {
  description = "SSH command for connecting to the k3s node"
  value       = "ssh -i <PRIVATE_KEY_PATH> ubuntu@${aws_eip.k3s_node.public_ip}"
}

output "k3s_boot_log_command" {
  description = "Command to inspect the boot-time Ansible k3s installation log"
  value       = "ssh -i <PRIVATE_KEY_PATH> ubuntu@${aws_eip.k3s_node.public_ip} 'sudo tail -n 80 /var/log/k3s-ansible-init.log'"
}

output "hello_world_url" {
  description = "Public URL for the Hello World Nginx service after the manifest is deployed"
  value       = "http://${aws_eip.k3s_node.public_ip}:30080"
}
