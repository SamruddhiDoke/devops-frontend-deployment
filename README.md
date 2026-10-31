# TaskFlow Frontend: CI/CD to AWS EKS

A DevOps project that builds the existing React + Vite frontend (`frontend/`) into a Docker image and deploys it to Amazon EKS through a Jenkins pipeline. Terraform provisions the AWS infrastructure; Prometheus and Grafana provide basic cluster monitoring.

> These files have been written and reviewed but **not tested or deployed**. Review them before you apply anything.

## Architecture

```
GitHub ──► Jenkins (EC2, IAM role) ──► docker build ──► Amazon ECR
                    │                                       │
                    └── kubectl apply ──► Amazon EKS ◄──────┘ (nodes pull image)
                                            ├── taskflow-frontend Deployment (2 × Nginx pods)
                                            ├── taskflow-frontend Service (LoadBalancer ──► Internet)
                                            └── Prometheus + Grafana (ClusterIP, internal only)
```

- **Terraform** creates the ECR repository, the EKS cluster and node group, the IAM roles, and the Jenkins EC2 instance in the **default VPC** of `ap-south-1`. No NAT gateway or custom VPC is created.
- **Jenkins** uses its EC2 IAM role (no stored keys). Through an EKS access entry it gets *edit* rights in the `default` namespace only, plus read-only access to nodes through the Kubernetes group `jenkins-node-readers` (`k8s/jenkins-node-reader.yaml`, applied once by the admin).
- **EKS** runs the frontend. The `LoadBalancer` Service creates an AWS Classic Load Balancer.

## Folder structure

```
.
├── frontend/                    # Existing React + Vite app (unchanged)
├── Dockerfile                   # Multi-stage: Node build → Nginx
├── .dockerignore
├── .gitignore                   # Ignores node_modules, dist, Terraform state, tfvars
├── Jenkinsfile
├── terraform/
│   ├── provider.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── jenkins-node-reader.yaml # RBAC: lets Jenkins run `kubectl get nodes`
├── monitoring/
│   ├── prometheus-config.yaml   # ConfigMap: prometheus-config
│   ├── prometheus.yaml          # RBAC + Deployment + Service: prometheus
│   └── grafana.yaml             # Datasource ConfigMap + Deployment + Service: grafana
└── README.md
```

## Names used everywhere

| Item | Value |
|---|---|
| AWS region | `ap-south-1` |
| ECR repository | `taskflow-frontend` |
| EKS cluster | `taskflow-eks` |
| Namespace | `default` |
| Deployment / container / Service / label `app` | `taskflow-frontend` |
| Image tag | Jenkins `BUILD_NUMBER` |

If you change a name in `terraform/variables.tf`, change it in the `Jenkinsfile` too.

## AWS resources and cost

| Resource | Notes |
|---|---|
| EKS control plane | Charged per hour, whether or not anything runs on it |
| 2 × t3.medium worker nodes | EC2 + EBS |
| 1 × t3.medium Jenkins server | EC2 + 30 GB gp3 |
| Classic Load Balancer | Created by the `LoadBalancer` Service |
| Public IPv4 addresses | Charged per hour (nodes, Jenkins, load balancer) |
| ECR storage | Small |

Leaving everything running costs roughly **US $7 per day (about $0.30 per hour)** in `ap-south-1`. Check current AWS pricing, and **destroy everything when you are done**. This is not Free Tier.

## Prerequisites

- An AWS account and an IAM user/role on your laptop that can create EKS, EC2, IAM and ECR resources
- AWS CLI v2, Terraform ≥ 1.5 and kubectl installed locally
- An **existing EC2 key pair** in `ap-south-1`
- The **default VPC** must still exist in `ap-south-1`, with its default subnets
- This project pushed to a GitHub repository

## Values you must configure

1. `terraform/terraform.tfvars` (copy it from `terraform.tfvars.example`):
   - `jenkins_key_name`: your existing key pair name
   - Jenkins ports 22 and 8080 are open to `0.0.0.0/0` (any IP). Protect Jenkins with a strong admin password.
2. `kubernetes_version` (default `1.37`, in EKS standard support until Dec 2027 per AWS docs): confirm it with `aws eks describe-cluster-versions` before you apply.
3. Grafana admin credentials: create them as a Kubernetes Secret (see Monitoring). Never commit them.

## Deployment workflow (high level)

1. **Terraform**: run `init`, `plan` and `apply` in `terraform/`. Note the outputs.
2. **kubectl (your laptop)**: run the `configure_kubectl` output. Your Terraform identity is cluster admin. Apply `k8s/jenkins-node-reader.yaml` once.
3. **Jenkins setup**:
   - Wait about 5 minutes after apply for the install script to finish. Its log is `/var/log/cloud-init-output.log`.
   - SSH in as `ubuntu` (the Jenkins server runs Ubuntu Server 24.04 LTS) and check that `java`, `git`, `docker`, `aws` and `kubectl` are all installed. Node.js is not needed on the server; the pipeline runs npm inside the `node:22-alpine` container.
   - Open the `jenkins_url` output. Unlock Jenkins with `/var/lib/jenkins/secrets/initialAdminPassword`. Choose *Select plugins to install* and install only **Pipeline** and **Git**.
   - Create a **Pipeline** job using *Pipeline script from SCM*: Git, your GitHub repo URL, the correct branch, and Script Path `Jenkinsfile`. If the repo is private, add GitHub credentials (a personal access token) in Jenkins.
   - Run the first build manually (**Build Now**). After that, the `pollSCM` trigger in the Jenkinsfile checks GitHub about every 5 minutes and builds new commits automatically. GitHub webhooks are not used because port 8080 only allows your IP.
4. **Monitoring**: create the Grafana secret, then apply the files in `monitoring/` (see below).

## How Jenkins deploys a new image

1. Checks out the repo, then runs `npm ci` and `npm run build` for `frontend/` inside a `node:22-alpine` container as a fast build check.
2. Builds the image from the repo root and tags it `<account>.dkr.ecr.ap-south-1.amazonaws.com/taskflow-frontend:<BUILD_NUMBER>`. The account ID is read at runtime with `aws sts get-caller-identity`.
3. Logs in to ECR and pushes the image.
4. Runs `aws eks update-kubeconfig` for `taskflow-eks`.
5. Replaces `IMAGE_URI_PLACEHOLDER` in `k8s/deployment.yaml` with the new image URI and applies it, together with `k8s/service.yaml`. This creates the Deployment on the first run and rolls out the new image on later runs.
6. Runs `kubectl rollout status` with a 180-second timeout. If the pods don't become ready, the build fails.

Do **not** apply `k8s/deployment.yaml` by hand: it contains a placeholder image.

## Accessing the application

```
kubectl get svc taskflow-frontend
```

Open `http://<EXTERNAL-IP hostname>` in a browser. The load balancer DNS name can take a few minutes to start working.

## Monitoring

Create the Grafana admin secret (use your own password, never commit it):

```
kubectl create secret generic grafana-admin --from-literal=admin-user=admin --from-literal=admin-password='<choose-a-strong-password>'
```

Apply `monitoring/prometheus-config.yaml`, `monitoring/kube-state-metrics.yaml`, `monitoring/prometheus.yaml` and `monitoring/grafana.yaml`. Then open Grafana through a port-forward (it is not exposed publicly):

```
kubectl port-forward svc/grafana 3000:3000      # then open http://localhost:3000
kubectl port-forward svc/prometheus 9090:9090   # optional: Prometheus UI
```

Grafana already has Prometheus set up as its default data source.

**What is monitored:** Prometheus itself, Grafana, the EKS API server, per-container CPU, memory and network usage (cAdvisor through the kubelet), and pod, deployment and node state (kube-state-metrics). For example: `container_memory_working_set_bytes{pod=~"taskflow-frontend.*"}`.

**What is not monitored:**
- The Nginx frontend exposes no metrics endpoint. Request metrics would need `nginx-prometheus-exporter`.
- Node OS metrics (disk, load) would need `node-exporter`.
- Prometheus and Grafana data live in `emptyDir` volumes, so they are lost when the pods restart. Persistent volumes would need the EBS CSI driver add-on.

## Cleanup (do this in order)

1. Delete the frontend Service **first**, so AWS deletes its load balancer: `kubectl delete -f k8s/service.yaml`
2. Delete the remaining workloads: `kubectl delete -f k8s/deployment.yaml -f monitoring/`
3. Run `terraform destroy` in `terraform/`. ECR has `force_delete = true`, so its images are deleted too.
4. In the AWS console, check that no load balancers, EC2 instances or EKS clusters are left in `ap-south-1`.

If you skip step 1, the load balancer can be left behind and keep charging you.

## Important warnings

- **Costs**: EKS and EC2 charge by the hour. Destroy everything after each session.
- **Credentials**: never commit AWS keys, `terraform.tfvars`, or the Grafana password. Jenkins uses its IAM role, not access keys.
- **Terraform state**: `terraform.tfstate` is stored locally and is git-ignored. It can contain sensitive data. Don't delete it while resources exist, or Terraform can no longer destroy them.
- **EKS API endpoint**: it is public (`0.0.0.0/0` by default) so you can use kubectl from your laptop. Access still requires valid IAM credentials and an access entry. You can narrow it with `cluster_endpoint_public_cidrs`. Jenkins uses the private endpoint, so narrowing the public one does not break the pipeline.
