# Outputs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "redis_api_endpoint" {
  value = aws_elasticache_cluster.api.cache_nodes[0].address
}

output "redis_media_endpoints" {
  value = aws_elasticache_replication_group.media.configuration_endpoint_address
}

output "s3_bucket_name" {
  value = aws_s3_bucket.storage.id
}

output "api_sg_id" {
  value = aws_security_group.api_server.id
}

output "media_sg_id" {
  value = aws_security_group.media_server.id
}

output "public_subnet_1_id" {
  value = aws_subnet.public_1.id
}

output "public_subnet_2_id" {
  value = aws_subnet.public_2.id
}
