# Kubernetes Deployments Assignment

This repository provisions a single-node k3s cluster on AWS EC2 with Terraform Cloud, installs k3s during EC2 boot using an Ansible playbook, and deploys a Hello World Nginx app through GitHub Actions.

## 1. Provision EC2 and k3s

Terraform Cloud runs the code in `infra/terraform`.

Required Terraform Cloud variables:

```text
ssh_public_key
ssh_allowed_cidr
nodeport_allowed_cidr
TFC_AWS_PROVIDER_AUTH
TFC_AWS_RUN_ROLE_ARN
```

`TFC_AWS_PROVIDER_AUTH` and `TFC_AWS_RUN_ROLE_ARN` should be environment variables.

After apply, connect to EC2:

```bash
ssh -i /root/.ssh/k3s-digitalxc-key-20260525150433 ubuntu@<EC2_PUBLIC_IP>
```

Verify k3s:

```bash
sudo kubectl get nodes
sudo tail -n 80 /var/log/k3s-ansible-init.log
```

## 2. Configure GitHub Actions Runner

Use a self-hosted GitHub Actions runner on the EC2 instance. This avoids exposing the Kubernetes API to GitHub-hosted runner IP ranges.

On GitHub, open:

```text
Repository -> Settings -> Actions -> Runners -> New self-hosted runner
```

Choose Linux x64 and run the GitHub-provided commands on the EC2 instance.

Install the runner as a service:

```bash
sudo ./svc.sh install ubuntu
sudo ./svc.sh start
```

Confirm the runner shows as idle in GitHub.

## 3. Deploy Hello World Nginx

The application manifest is:

```text
k8s/hello-world-nginx.yaml
```

The pipeline is:

```text
.github/workflows/deploy.yml
```

On every push to `main` that changes `k8s/**` or the workflow file, GitHub Actions runs:

```bash
sudo kubectl apply -f k8s/
sudo kubectl rollout status deployment/hello-world-nginx -n hello-world
```

Verify manually:

```bash
sudo kubectl get pods,svc -n hello-world -o wide
curl http://127.0.0.1:30080
```

Open in browser:

```text
http://<EC2_PUBLIC_IP>:30080
```

## Recording Checklist

Show these steps in the recording:

1. Terraform Cloud apply provisioning the EC2 instance.
2. SSH into the EC2 instance.
3. `sudo kubectl get nodes`.
4. Push a change to the repository.
5. GitHub Actions pipeline running automatically.
6. `sudo kubectl get pods,svc -n hello-world -o wide`.
7. Browser showing `Hello World` from `http://<EC2_PUBLIC_IP>:30080`.
