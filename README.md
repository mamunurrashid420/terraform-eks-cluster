# AWS EKS Cluster Configuration, Setup and Application Deployment

This Terraform project creates an Amazon EKS cluster in the `us-east-1` AWS region, including its VPC, public subnets, IAM roles, security groups, managed node group, and AWS EBS CSI add-on.

## Project Details

- **AWS region:** `us-east-1`
- **EKS cluster:** `awsclass-cluster`
- **Node group:** `awsclass-node-group`
- **Node instance type:** `t2.medium`
- **Desired, minimum, and maximum nodes:** `3`
- **SSH key pair:** supplied through `ssh_key_name`

## Prerequisites

Install and configure the following tools before deploying:

- An AWS account with permission to create EKS, EC2, VPC, IAM, and related resources
- AWS CLI
- Terraform
- `kubectl`
- `eksctl`
- An existing EC2 key pair in `us-east-1` matching `ssh_key_name`

Make sure your AWS credentials are configured:

```bash
aws configure
aws sts get-caller-identity
```

> Do not commit AWS access keys or other credentials to this repository.

## 1. Install AWS CLI on Linux

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt update
sudo apt install -y unzip
unzip awscliv2.zip
sudo ./aws/install
aws --version
aws configure
```

For Windows, install AWS CLI using the official MSI installer and run the commands from PowerShell.

## 2. Deploy the EKS Cluster with Terraform

Clone the repository and open the Terraform directory:

```bash
git clone <terraform_project_repo>
cd <terraform_project_folder>/Terraform-Code
```
## Terraform install process
```
snap install terraform --classic
```
Initialize Terraform and review the proposed resources:

```bash
terraform init
terraform plan
```

Deploy the infrastructure:

```bash
terraform apply --auto-approve
```

To use a different EC2 key pair:

```bash
terraform apply -var='ssh_key_name=<your-existing-key-pair>'
```

The key pair must already exist in `us-east-1`. Check available key pairs with:

```bash
aws ec2 describe-key-pairs --region us-east-1 --query 'KeyPairs[].KeyName' --output table
```

## 3. Update kubeconfig

After Terraform completes, configure `kubectl` to access the cluster:

```bash
aws eks --region us-east-1 update-kubeconfig --name awsclass-cluster
```

Confirm that the current context points to the expected cluster:

```bash
kubectl config current-context
```

## 4. Install kubectl on Linux

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client
```

On Windows, install `kubectl` using the official Kubernetes installation instructions or a package manager such as Chocolatey.

## 5. Install eksctl on Linux

```bash
curl -LO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz"
tar -xzf eksctl_Linux_amd64.tar.gz
sudo mv eksctl /usr/local/bin/
eksctl version
```

## 6. Associate the IAM OIDC Provider

Associate an IAM OIDC provider with the EKS cluster to enable IAM roles for Kubernetes service accounts:

```bash
eksctl utils associate-iam-oidc-provider \
  --region us-east-1 \
  --cluster awsclass-cluster \
  --approve
```

## 7. Create the EBS CSI IAM Service Account

Create the service account only if your installation uses an IRSA-managed EBS CSI driver. The command is safe to re-run because it includes `--override-existing-serviceaccounts`:

```bash
eksctl create iamserviceaccount \
  --region us-east-1 \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster awsclass-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --override-existing-serviceaccounts
```

## 8. EBS CSI Driver

This Terraform configuration already creates the AWS-managed EBS CSI add-on:

```hcl
resource "aws_eks_addon" "ebs_csi_driver" {
  addon_name = "aws-ebs-csi-driver"
}
```

Wait for the add-on to become active:

```bash
aws eks describe-addon \
  --region us-east-1 \
  --cluster-name awsclass-cluster \
  --addon-name aws-ebs-csi-driver \
  --query 'addon.status'
```

Do not also apply a second self-managed driver using `kubectl apply -k` unless you intentionally remove or replace the Terraform-managed add-on. If a self-managed installation is required instead, use:

```bash
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/ecr/?ref=release-1.11"
```

## 9. Deploy the Application

Apply your Kubernetes manifest after the cluster and nodes are ready:

```bash
kubectl apply -f manifest.yaml
```

Replace `manifest.yaml` with the path to your application manifest, for example:

```bash
kubectl apply -f ./kubernetes/manifest.yaml
```

## Verification

Check that the cluster is reachable and nodes are ready:

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

Check the EBS CSI service account, if created:

```bash
kubectl get serviceaccount ebs-csi-controller-sa -n kube-system
```

Check the EBS CSI driver pods:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
```

Check the application deployment:

```bash
kubectl get pods
kubectl get services
```

## Destroy the Infrastructure

When the environment is no longer needed, remove the Terraform-managed resources:

```bash
terraform destroy
```

Review the plan carefully before confirming destruction. Kubernetes resources created outside Terraform may need to be deleted separately.
