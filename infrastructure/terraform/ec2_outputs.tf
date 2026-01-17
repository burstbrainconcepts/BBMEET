# EC2 Outputs
output "api_server_public_ip" {
  value = aws_eip.api_server.public_ip
}

output "api_server_private_ip" {
  value = aws_instance.api_server.private_ip
}

output "media_server_public_ip" {
  value = aws_eip.media_server.public_ip
}

output "media_server_private_ip" {
  value = aws_instance.media_server.private_ip
}

output "redis_media_configuration_endpoint" {
  value = aws_elasticache_replication_group.media.configuration_endpoint_address
}
