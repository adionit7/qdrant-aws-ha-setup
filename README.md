# Qdrant High Availability Setup on AWS

A production-ready Terraform configuration for deploying a High Availability Qdrant vector database cluster on AWS, optimized for the AWS Free Tier.

## 🎯 Overview

This repository contains Terraform/OpenTofu scripts that deploy a highly available Qdrant cluster on AWS with:

- **Multi-AZ Deployment**: Qdrant instances across multiple Availability Zones
- **Application Load Balancer**: Distributes traffic across healthy instances
- **Auto Scaling Group**: Automatically scales based on demand
- **Health Checks**: Ensures only healthy instances receive traffic
- **VPC with Public/Private Subnets**: Secure network architecture
- **Free Tier Optimized**: Uses t3.micro instances and minimal resources

## 🏗️ Architecture

```
                    Internet
                       |
              [Application Load Balancer]
                       |
        +--------------+--------------+
        |              |              |
    [Qdrant-1]    [Qdrant-2]    [Qdrant-N]
    (AZ-1)        (AZ-2)        (Auto-scaled)
```

### Components

- **VPC**: Custom VPC with public and private subnets across 2+ AZs
- **NAT Gateway**: Allows private instances to access internet
- **Application Load Balancer**: Routes traffic to healthy Qdrant instances
- **Auto Scaling Group**: Maintains desired number of instances
- **Security Groups**: Restricts access to necessary ports only
- **IAM Roles**: Provides necessary permissions for instances

## 📋 Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0 or [OpenTofu](https://opentofu.org/) >= 1.0
- AWS CLI configured with appropriate credentials
- AWS Account with Free Tier eligibility
- (Optional) SSH key pair for instance access

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/qdrant-aws-ha-setup.git
cd qdrant-aws-ha-setup
```

### 2. Configure AWS Credentials

```bash
aws configure
```

Or set environment variables:
```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-1
```

### 3. Customize Variables (Optional)

Edit `terraform.tfvars` or set variables:

```hcl
aws_region        = "us-east-1"
instance_type     = "t3.micro"
min_instances     = 2
desired_instances = 2
max_instances     = 4
qdrant_version    = "1.7.4"
```

### 4. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 5. Access Qdrant

After deployment, get the load balancer URL:

```bash
terraform output load_balancer_url
```

Test the API:
```bash
curl http://$(terraform output -raw load_balancer_dns)/health
```

## 📊 AWS Free Tier Considerations

This setup is optimized for AWS Free Tier:

- **EC2 Instances**: Uses `t3.micro` (750 hours/month free)
- **EBS Storage**: 20GB per instance (30GB total free tier)
- **NAT Gateway**: ~$0.045/hour (not free, but minimal for testing)
- **Load Balancer**: ~$0.0225/hour (not free, but required for HA)

**Estimated Monthly Cost**: ~$50-60 for a 2-instance HA setup (outside Free Tier for ALB/NAT)

For true Free Tier testing, consider:
- Using a single instance without ALB
- Using t2.micro instead of t3.micro
- Removing NAT Gateway (instances in public subnets)

## 🔧 Configuration

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `instance_type` | EC2 instance type | `t3.micro` |
| `min_instances` | Minimum ASG instances | `2` |
| `desired_instances` | Desired ASG instances | `2` |
| `max_instances` | Maximum ASG instances | `4` |
| `qdrant_version` | Qdrant version | `1.7.4` |
| `volume_size` | EBS volume size (GB) | `20` |

### Qdrant Configuration

Qdrant is configured via `/opt/qdrant/config/production.yaml` on each instance. Key settings:

- **HTTP Port**: 6333
- **gRPC Port**: 6334
- **P2P Port**: 6335 (for cluster mode)
- **Storage Path**: `/qdrant/storage`
- **Health Check**: `/health` endpoint

## 🔐 Security

- Instances are in private subnets (not directly accessible from internet)
- Security groups restrict access:
  - ALB: HTTP/HTTPS from internet
  - Instances: Qdrant ports from ALB only, SSH from VPC
- EBS volumes are encrypted
- IAM roles follow least privilege principle

## 📈 Monitoring & Health Checks

- **ALB Health Checks**: Monitors `/health` endpoint every 30 seconds
- **Auto Scaling**: Automatically replaces unhealthy instances
- **CloudWatch Logs**: Instance logs available via IAM role

Check instance health:
```bash
# Get instance IDs
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw autoscaling_group_name) \
  --query 'AutoScalingGroups[0].Instances[*].InstanceId'

# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw target_group_arn)
```

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: This will delete all resources including data. Backup important data before destroying.

## 🔄 Updating Qdrant

To update Qdrant version:

1. Update `qdrant_version` variable
2. Run `terraform apply`
3. ASG will perform rolling update

## 📝 Example Usage

### Create a Collection

```bash
QDRANT_URL=$(terraform output -raw load_balancer_url)

curl -X PUT "$QDRANT_URL/collections/my-collection" \
  -H "Content-Type: application/json" \
  -d '{
    "vectors": {
      "size": 384,
      "distance": "Cosine"
    }
  }'
```

### Insert Vectors

```bash
curl -X PUT "$QDRANT_URL/collections/my-collection/points" \
  -H "Content-Type: application/json" \
  -d '{
    "points": [
      {
        "id": 1,
        "vector": [0.1, 0.2, 0.3, ...]
      }
    ]
  }'
```

### Search Vectors

```bash
curl -X POST "$QDRANT_URL/collections/my-collection/points/search" \
  -H "Content-Type: application/json" \
  -d '{
    "vector": [0.1, 0.2, 0.3, ...],
    "limit": 10
  }'
```

## 🐛 Troubleshooting

### Instances not joining target group

1. Check security groups allow traffic from ALB
2. Verify Qdrant is running: `curl http://instance-ip:6333/health`
3. Check ASG health status in AWS Console

### High latency

- Consider using `t3.small` or larger instances
- Enable cluster mode for distributed queries
- Check CloudWatch metrics for bottlenecks

### Out of memory

- Reduce `max_optimization_threads` in Qdrant config
- Use larger instance types
- Optimize collection settings

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- [Qdrant](https://qdrant.tech/) - Vector similarity search engine
- [Terraform](https://www.terraform.io/) - Infrastructure as Code
- AWS Free Tier for making this accessible

## 📧 Contact

For questions or issues, please open an issue on GitHub.

---

**Built for production. Optimized for Free Tier. Ready for Day 1.**
