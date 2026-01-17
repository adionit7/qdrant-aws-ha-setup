.PHONY: init plan apply destroy output validate fmt

# Initialize Terraform
init:
	terraform init

# Validate Terraform configuration
validate:
	terraform validate

# Format Terraform files
fmt:
	terraform fmt -recursive

# Plan infrastructure changes
plan:
	terraform plan

# Apply infrastructure changes
apply:
	terraform apply

# Destroy infrastructure
destroy:
	terraform destroy

# Show outputs
output:
	terraform output

# Show load balancer URL
url:
	@echo "Qdrant API URL:"
	@terraform output -raw load_balancer_url

# Check health
health:
	@curl -s http://$$(terraform output -raw load_balancer_dns)/health | jq .

# Full setup (init + validate + plan)
setup: init validate fmt

# Quick deploy (init + apply)
deploy: init apply
