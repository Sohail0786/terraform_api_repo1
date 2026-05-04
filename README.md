# terraform_api_repo1

Terraform modules and environment configs for a **shared-services architecture**
that lets **Dev** and **Test** environments consume common AWS resources through
an **air-gapped VPC** (no internet) using Transit Gateway, PrivateLink, NLB,
Private API Gateway, Lambda, S3, DynamoDB, and Nginx.

---

## Architecture Diagram

```
 +--------------------------------------------------------------------------+
 |                         AWS Account (eu-west-2)                          |
 |                                                                          |
 |  +───────────────────────+       +────────────────────────────────────+  |
 |  |     Dev VPC           |       |        Shared Services VPC         |  |
 |  |  10.1.0.0/16          |       |        10.0.0.0/16                 |  |
 |  |  (air-gapped, no IGW) |       |  (air-gapped, no IGW)              |  |
 |  |                       |       |                                    |  |
 |  |  +─────────────────+  |       |  +─────────────────────────────+   |  |
 |  |  | Private Subnets |  |       |  |    Network Load Balancer     |   |  |
 |  |  | 10.1.1.0/24     |  |       |  |  (internal, TCP:80)         |   |  |
 |  |  | 10.1.2.0/24     |  |       |  +──────────────┬──────────────+   |  |
 |  |  |                 |  |       |                 |                   |  |
 |  |  |  Dev Workloads  |  |       |                 v                   |  |
 |  |  |  (EC2/ECS/etc)  |  |       |  +─────────────────────────────+   |  |
 |  |  +────────┬────────+  |       |  |   Nginx Proxy ASG (EC2)     |   |  |
 |  |           |           |       |  |   port 80 ──> API GW URL    |   |  |
 |  |  +────────v────────+  |       |  +──────────────┬──────────────+   |  |
 |  |  | VPC Endpoints   |  |       |                 |                   |  |
 |  |  |  · execute-api  |  |       |                 v                   |  |
 |  |  |  · lambda       |  |       |  +─────────────────────────────+   |  |
 |  |  |  · S3 (Gateway) |  |       |  |  Private API Gateway (REST) |   |  |
 |  |  |  · DynamoDB(GW) |  |       |  |  endpoint type: PRIVATE     |   |  |
 |  |  +────────┬────────+  |       |  +──────────────┬──────────────+   |  |
 |  +───────────|───────────+       |                 |                   |  |
 |              |                   |                 v                   |  |
 |   PrivateLink|VPC Endpoint       |  +─────────────────────────────+   |  |
 |   (NLB svc) <+──────────────────>+  |     Lambda Function          |   |  |
 |              |                   |  |  (python3.12, VPC-attached)  |   |  |
 |  +───────────|───────────+       |  +──────┬──────────┬────────────+   |  |
 |  |   Test VPC            |       |         |          |                |  |
 |  |   10.2.0.0/16         |       |         v          v                |  |
 |  |  (air-gapped, no IGW) |       |  +──────────+ +──────────────+     |  |
 |  |                       |       |  | DynamoDB | |  S3 Bucket   |     |  |
 |  |  +─────────────────+  |       |  |  Table   | | (versioned,  |     |  |
 |  |  | Private Subnets |  |       |  |(PAY/REQ) | |  encrypted)  |     |  |
 |  |  | 10.2.1.0/24     |  |       |  +──────────+ +──────────────+     |  |
 |  |  | 10.2.2.0/24     |  |       +────────────────────────────────────+  |
 |  |  |                 |  |                        ^                       |
 |  |  |  Test Workloads |  |                        |                       |
 |  |  +────────┬────────+  |       +────────────────+────────────────+      |
 |  |           |           |       |      Transit Gateway (TGW)      |      |
 |  |  +────────v────────+  |       |  auto-accept, default RT        |      |
 |  |  | VPC Endpoints   |<─+───────+  propagation enabled            |      |
 |  |  |  · execute-api  |  | attach+─────────────────────────────────+      |
 |  |  |  · S3 (Gateway) +──+──────>|  (Dev & Shared also attach here)|      |
 |  |  |  · DynamoDB(GW) |  |       +─────────────────────────────────+      |
 |  |  +─────────────────+  |                                                |
 |  |  PrivateLink VPC      |                                                |
 |  |  Endpoint (NLB svc)   |                                                |
 |  +───────────────────────+                                                |
 +--------------------------------------------------------------------------+
```

---

## Data Flow (request lifecycle)

```
Dev or Test workload
        |
        |  1. App calls http://<shared-nlb-vpce-dns>/v1/item?pk=123
        v
  VPC Endpoint (Interface – PrivateLink consumer)  [dev/test VPC]
        |
        |  2. Traffic travels through PrivateLink (stays on AWS backbone,
        |     never touches the internet or a NAT gateway)
        v
  NLB – Network Load Balancer  [shared VPC, internal]
  (TCP:80, cross-zone enabled)
        |
        |  3. NLB selects a healthy Nginx EC2 target (round-robin)
        v
  Nginx Proxy  [EC2 in Auto Scaling Group, shared VPC]
  (rewrites Host header, adds X-Forwarded-* headers)
        |
        |  4. Nginx proxies to private API Gateway DNS name
        v
  Private API Gateway  [shared VPC, execute-api VPC endpoint]
  (resource policy: only allow sourceVpce == execute-api endpoint)
        |
        |  5. API GW validates policy -> invokes Lambda (AWS_PROXY)
        v
  Lambda Function  [VPC-attached, shared VPC private subnets]
        |
        +──> 6a. DynamoDB GetItem/PutItem/Query
        |         via DynamoDB Gateway VPC Endpoint (free, no internet)
        |                      |
        |                      v
        |              DynamoDB Table
        |
        +──> 6b. S3 GetObject/PutObject
                  via S3 Gateway VPC Endpoint (free, no internet)
                               |
                               v
                          S3 Bucket

        |
        |  7. Lambda returns JSON to API GW -> Nginx -> NLB
        |     -> PrivateLink -> Dev/Test workload
        v
  200 OK { "pk": "123", "data": "..." }
```

---

## Shared Resources

| Resource | Why shared? | Isolation between envs |
|---|---|---|
| **Transit Gateway** | Single routing hub | Route tables per environment |
| **NLB + PrivateLink** | Single stable ingress endpoint | PrivateLink per consumer VPC |
| **Nginx Proxy** (ASG) | Protocol normalisation | n/a (stateless) |
| **Private API Gateway** | Single API surface | Stage variables / paths |
| **Lambda** | Business logic runs once | `ENVIRONMENT` env var |
| **S3 Bucket** | Shared data store | Key prefix `dev/` vs `test/` |
| **DynamoDB Table** | Shared state | Partition key prefix `dev#` vs `test#` |

---

## Repository Layout

```
terraform_api_repo1/
├── modules/
│   ├── networking/       # VPC, private subnets, Interface + Gateway VPC endpoints
│   ├── transit_gateway/  # TGW, VPC attachments, cross-VPC routes
│   ├── nlb/              # Internal NLB + PrivateLink endpoint service
│   ├── api_gateway/      # Private REST API Gateway + Lambda integration
│   ├── lambda/           # Lambda function, IAM role, VPC security group
│   ├── s3/               # S3 bucket with VPCE-only bucket policy + KMS
│   ├── dynamodb/         # DynamoDB table with resource policy + PITR
│   └── nginx_proxy/      # EC2 ASG (Amazon Linux 2023), Nginx Launch Template
│
├── shared/               # Shared services environment (apply first)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── provider.tf
│
├── dev/                  # Dev VPC + TGW attachment + PrivateLink consumer
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── provider.tf
│
├── test/                 # Test VPC + TGW attachment + PrivateLink consumer
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── provider.tf
│
└── lambda/
    ├── src/handler.py    # Python 3.12 Lambda handler (DynamoDB + S3 CRUD)
    └── function.zip      # Deployment package (auto-generated)
```

---

## Deployment Order

```bash
# 1. Bootstrap shared services (TGW, NLB, API GW, Lambda, S3, DynamoDB)
terraform -chdir=shared init
terraform -chdir=shared apply -var="aws_account_id=<ACCOUNT_ID>"

# 2. Deploy dev VPC and attach to TGW
terraform -chdir=dev init
terraform -chdir=dev apply -var="state_bucket=<TF_STATE_BUCKET>"

# 3. Deploy test VPC and attach to TGW
terraform -chdir=test init
terraform -chdir=test apply -var="state_bucket=<TF_STATE_BUCKET>"

# 4. Re-apply shared to add dev/test VPCE IDs to S3 and DynamoDB policies
terraform -chdir=shared apply \
  -var="dev_s3_vpce_id=$(terraform -chdir=dev output -raw dev_s3_vpce_id)" \
  -var="dev_dynamodb_vpce_id=$(terraform -chdir=dev output -raw dev_dynamodb_vpce_id)" \
  -var="test_s3_vpce_id=$(terraform -chdir=test output -raw test_s3_vpce_id)" \
  -var="test_dynamodb_vpce_id=$(terraform -chdir=test output -raw test_dynamodb_vpce_id)"
```

---

## Security Highlights

- **No Internet Gateway** in any VPC — true air-gapped setup
- **S3 bucket policy** denies all access unless `aws:sourceVpce` matches allowed endpoints
- **DynamoDB resource policy** restricts access to specific VPCE IDs and IAM principals
- **Private API Gateway** resource policy allows invocations only from the `execute-api` VPC endpoint
- **Nginx EC2** uses IMDSv2 (`http_tokens = required`) and is managed via SSM — no SSH/bastion needed
- **Lambda** runs in VPC mode with no public IP
- **S3 objects** encrypted with KMS (bucket key enabled to reduce KMS costs)
- **DynamoDB** has point-in-time recovery and server-side encryption enabled
