# Cloud Prime Factorization with AWS

Inspired by [eniac/faas](https://github.com/eniac/faas) and [cado-nfs](https://gitlab.inria.fr/cado-nfs/cado-nfs)

This repository sets up a cluster on AWS to factorize large numbers (up to 512 bits) using [cado-nfs](https://gitlab.inria.fr/cado-nfs/cado-nfs/). The Terraform configuration will build 1 master node and 8 worker nodes, all running in AWS. Each node will have a large compute-optimized instance type (e.g., `c5.12xlarge`) to speed up factorization.

## Overview of the Process

1. Configure your AWS credentials and variables.
2. Use Terraform to set up the infrastructure.
3. Run cado-nfs from the master node to factorize your target number.
4. Wait for the factorization to complete, then retrieve your prime factors.

## Requirements

- [Terraform](https://www.terraform.io/) installed on your local machine.
- An AWS account and access credentials (Access Key, Secret Key).
- An existing SSH key pair on your local machine (e.g., `~/.ssh/my-admin-key` and `~/.ssh/my-admin-key.pub`). The public key will be uploaded to AWS so you can SSH into the instances.

## Setting up Infrastructure

1. **Set up your SSH key pair:**  
   Ensure you have a public key file at `~/.ssh/my-admin-key.pub`. If not, create one:
   ```sh
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f ~/.ssh/my-admin-key

2. **Configure Terraform variables:**
    Copy terraform.tfvars.defaults to terraform.tfvars (if provided) or create your own terraform.tfvars.

    In terraform.tfvars, set:
    ```sh
    aws_region     = "eu-central-1"
    my_ip = "0.0.0.0/0"
    aws_instance_type = "t3.large"
    number_of_workers = 2
    number_of_slaves = 4
    number_of_threads = 2
    number_to_factor = 90377629292003121684002147101760858109247336549001090677692

3. **Authenticate with AWS**
Authenticate with AWS CLI and ensure ~/.aws/credentials is set. Terraform will use these values.

3. **Initialize and apply Terraform:**
    ```sh
    terraform init
    terraform apply
    
4. **Terraform will provision:**

    One master EC2 instance.
    Eight worker EC2 instances.
    A security group allowing SSH from your IP and internal communication between instances.
    Automatically download and compile cado-nfs on the master and worker instances.
    Note: The chosen AMI and instance types must be available in your selected AWS region. Adjust them if needed.

## Running cado-nfs
Get the cado-nfs command: After terraform apply finishes, run:
    ```sh
    terraform output master_command
    

This outputs the exact command you’ll run on the master node to start cado-nfs.

SSH into the master instance: Obtain the master’s IP:

    terraform output master_ip

For Ubuntu-based AMIs:

    ssh -i ~/.ssh/my-admin-key -o "ServerAliveInterval 60" -o "ServerAliveCountMax 120" ubuntu@<master_ip>

Once logged in:

    cd /root/cado-nfs

Run the factorization: Use the command from terraform output master_command. It will look like:

    ./cado-nfs.py <number_to_factor> \
        server.address=<master_private_ip> \
        tasks.workdir=/tmp/c100 \
        slaves.hostnames=<worker_private_ips> \
        slaves.scriptpath=/root/cado-nfs/ \
        --slaves 24 \
        --client-threads 2
The command is pre-populated with correct IPs by Terraform.

Monitoring and Completion:

The process may take several hours, depending on the instance type and the number's complexity.
If cado-nfs gets interrupted, it will print a snapshot command you can use to resume the factorization.
When completed, cado-nfs prints out the prime factors.

## Clean Up
When you're done, destroy the infrastructure to avoid further costs:

    terraform destroy