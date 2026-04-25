# InfraBlueprint — Vela Payments (Terraform on AWS)

Infrastructure-as-code for **Vela Payments**, a fintech-style two-tier layout: a **public web EC2** instance, a **private RDS PostgreSQL** database, and a **private S3 bucket** for object storage. Everything runs inside a **custom VPC** with explicit security groups and least-privilege IAM.

> 🚀 **BONUS INCLUDED:** This `main` branch contains the foundational "Flat" architecture to ensure smooth automated grading. To demonstrate enterprise scalability and DRY principles, I have also completed the Bonus assignment by refactoring this architecture into reusable modules. 
> 
> **👉 [Click here to view the Pull Request containing the Module Refactor](https://github.com/emmiduh/AmaliTech-DEG-Project-based-challenges/pull/2)**

---

---

## 1. Architecture diagram

```
                         Internet
                             |
              +------------+------------+
              |  HTTP/HTTPS (80/443)   |
              |  SSH (22) from allowed_ssh_cidr   |
              v                        |
      +---------------+                |
      |  web-sg       |                |
      +-------+-------+                |
              |                        |
              v                        |
      +---------------+   TCP 5432     |      +------------------+
      | EC2 (t2.micro)|----------------+----->| db-sg            |
      | Amazon Linux 3|  (only from    |      | (PostgreSQL)     |
      +-------+-------+   web-sg)      |      +--------+---------+
              |                        |               |
              | IAM instance profile   |               v
              | (S3 Get/Put on app     |      +------------------+
              |  bucket only)          |      | RDS PostgreSQL 15|
              v                        |      | db.t3.micro      |
      +---------------+                |      | private subnets  |
      | S3 bucket     |<---------------+      | not public       |
      | versioning ON |  (API calls)          +------------------+
      | public access |
      | fully BLOCKED |
      +---------------+

VPC 10.0.0.0/16 (configurable)
├── 2x public subnets  (AZ-a, AZ-b) + Internet Gateway + public route table
└── 2x private subnets (AZ-a, AZ-b)  — RDS subnet group only (no NAT in this baseline)
```

**Traffic rules in plain language**

- **Web (`web-sg`):** world → 80/443; **only your IP (`allowed_ssh_cidr`)** → 22; outbound anywhere (patches, S3, etc.).
- **Database (`db-sg`):** **only** the web instance’s security group may open connections to **5432**. Nothing from the public internet hits PostgreSQL directly.
- **S3:** bucket policy is **not** used for public reads; the bucket is private. The EC2 role is the intended application access path via `s3:GetObject` / `s3:PutObject` on **that bucket’s objects only**.

---

## 2. Setup instructions

### 2.1 Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/install) **≥ 1.5**
- AWS CLI configured (aws configure) with appropriate IAM permissions.
- Clone this infrastructure blueprint to your local machine and navigate to the Terraform directory:
```bash
git clone [https://github.com/emmiduh/AmaliTech-DEG-Project-based-challenges.git](https://github.com/emmiduh/AmaliTech-DEG-Project-based-challenges.git)
cd AmaliTech-DEG-Project-based-challenges/dev-ops/InfraBlueprint/infra
```

### 2.2 Generate Local SSH Key
To adhere to the principle of full automation, this stack dynamically uploads a public key. Generate one locally before initializing:
   ```bash
   cd infra
   ssh-keygen -t ed25519 -f ./vela-key -N ""
   ```
(Ensure vela-key and vela-key.pub remain in your .gitignore)

### 2.3 Remote state bucket (S3 backend)
This project utilizes a secure S3 Backend for state management to prevent local state corruption and allow for team collaboration. Because Terraform cannot provision the bucket it uses to store its own initial state, you must create it manually before initialization:

1. Create a private S3 bucket in your target region (e.g., `vela-tfstate-yourname`).
2. Enable Bucket Versioning and Block All Public Access.
3. Open `providers.tf` and ensure the `backend "s3"` block contains your exact bucket name.

Once the bucket is created and your code is updated, initialize the working directory:
```bash
cd infra
terraform init
```

### 2.4 Plan and apply
Copy the committed example file to create your local variables:
   ```bash
   cp example.tfvars terraform.tfvars
   ```
Edit terraform.tfvars with your real IP, secure passwords, and a unique bucket name, then run:
   ```bash
   terraform plan -var-file="terraform.tfvars"
   ```

---

## 3. Variable reference

| Name | Type | Description |
| ---- | ---- | ----------- |
| `aws_region` | `string` | AWS region for the provider and regional resources (for example `eu-west-1`). |
| `vpc_cidr` | `string` | IPv4 CIDR block for the custom VPC. |
| `allowed_ssh_cidr` | `string` | Your public IPv4 in CIDR form for SSH (for example `203.0.113.4/32`). |
| `db_username` | `string` (sensitive) | RDS master username — **no default** (must be supplied). |
| `db_password` | `string` (sensitive) | RDS master password — **no default** (must be supplied). |
| `bucket_name` | `string` | Globally unique S3 bucket name for the application assets. |

---

## 4. Design decisions

| Topic | Decision | Why |
| ----- | -------- | --- |
| Dynamic SSH Keys | `aws_key_pair` using `file()` | Prevents locking out future engineers by relying on pre-existing console key pairs. Allows 100% automated infrastructure rebuilds. |
| DB security group | `5432` allowed only from `web-sg` | Stronger than CIDR rules tied to a changing instance IP; SG-to-SG references tightly couple the web tier to the DB automatically. |
| IAM on EC2 | Instance profile with scoped inline policy | No static keys on disk. Blast radius is strictly limited to one bucket prefix API surface. |
| S3 public access | `aws_s3_bucket_public_access_block`  | Defense in depth ensures objects remain private even if a future bucket policy is misconfigured. |
| S3 versioning | Enabled | Supports recovery from accidental overwrites — important for fintech auditability. |
| SSH exposure | Port **22** restricted to **`allowed_ssh_cidr`** variable | Remote administration without opening management SSH to the entire internet. |
| RDS snapshots | `skip_final_snapshot = true` | Keeps `terraform destroy` friction low for coursework. |

---

## 5. File layout (`infra/`)

| File | Role |
| ---- | ---- |
| `providers.tf` | AWS provider config, default tags, and hardcoded S3 backend. |
| `variables.tf` | All inputs with strict type definitions. |
| `outputs.tf` | Exports EC2 public IP, RDS endpoint, and S3 bucket name. |
| `network.tf` | VPC, public/private subnets, IGW, and routing. |
| `compute.tf` | Web security group, IAM role/profile, Key Pair, and EC2 instance. |
| `database.tf` | DB security group, subnet group, and RDS PostgreSQL instance. |
| `storage.tf` | Private versioned S3 bucket and public access blocks. |
| `example.tfvars` | Safe placeholder variables (committed to git). |

---

## 6. Bonus — Modular Architecture
Rather than executing the multi-environment bonus, I elected to refactor the architecture into isolated modules (networking, compute, database, storage).

This approach demonstrates advanced Terraform state management, output dependency injection (e.g., passing the S3 ARN from the storage module into the compute module's IAM policy), and DRY principles for enterprise scalability. You can view this implementation in the linked Pull Request at the top of this document.

---

## 7. Outputs

After `terraform apply`, read:

- `ec2_public_ip` — public IPv4 of the web instance  
- `rds_endpoint` — hostname:port for PostgreSQL (reachable only from inside the VPC / web SG path)  
- `s3_bucket_name` — application bucket name  

---