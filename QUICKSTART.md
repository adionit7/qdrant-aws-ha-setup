# Quick Start Guide

Get your Qdrant HA cluster running in 5 minutes!

## Prerequisites Check

```bash
# Check Terraform
terraform version  # Should be >= 1.0

# Check AWS CLI
aws --version

# Verify AWS credentials
aws sts get-caller-identity
```

## Step-by-Step Deployment

### 1. Clone and Navigate

```bash
git clone https://github.com/yourusername/qdrant-aws-ha-setup.git
cd qdrant-aws-ha-setup
```

### 2. Configure Variables

Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your settings (or use defaults):

```hcl
aws_region = "us-east-1"
instance_type = "t3.micro"
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review Plan

```bash
terraform plan
```

This will show you all resources that will be created. Review carefully!

### 5. Deploy

```bash
terraform apply
```

Type `yes` when prompted. This will take approximately 10-15 minutes.

### 6. Get Your Endpoint

```bash
terraform output load_balancer_url
```

Or use the Makefile:

```bash
make url
```

### 7. Test It

```bash
# Health check
curl http://$(terraform output -raw load_balancer_dns)/health

# Or use Makefile
make health
```

## Using Makefile (Optional)

The repository includes a Makefile for convenience:

```bash
make init      # Initialize Terraform
make validate  # Validate configuration
make plan      # Show plan
make apply     # Deploy
make destroy   # Clean up
make url       # Show API URL
make health    # Check health
```

## Next Steps

1. **Create a Collection**: See README.md for examples
2. **Insert Vectors**: Start using Qdrant!
3. **Monitor**: Check AWS Console for instance health
4. **Scale**: Adjust `desired_instances` in terraform.tfvars

## Troubleshooting

### Terraform fails to initialize

```bash
# Clear cache and retry
rm -rf .terraform
terraform init
```

### Instances not healthy

1. Wait 5-10 minutes for instances to fully boot
2. Check security groups in AWS Console
3. SSH into instance and check logs: `sudo docker logs qdrant`

### Can't access endpoint

1. Verify security groups allow HTTP (port 80)
2. Check ALB target group health in AWS Console
3. Ensure instances are in "InService" state

## Cost Optimization

For minimal cost testing:

1. Set `min_instances = 1` and `desired_instances = 1`
2. Use `t2.micro` instead of `t3.micro`
3. Set `volume_size = 8` (minimum)
4. **Note**: ALB and NAT Gateway still incur costs (~$50/month)

## Cleanup

When done testing:

```bash
terraform destroy
```

**Warning**: This deletes everything including data!

---

Need help? Open an issue on GitHub!
