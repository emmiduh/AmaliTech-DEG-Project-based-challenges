# Add your outputs here after creating the resources.

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance."
  value       = aws_instance.web.public_ip
}

output "rds_endpoint" {
  description = "Connection endpoint for the RDS instance."
  value       = aws_db_instance.main.endpoint
}

output "s3_bucket_name" {
  description = "Name of the S3 static assets bucket."
  value       = aws_s3_bucket.assets.bucket
}
