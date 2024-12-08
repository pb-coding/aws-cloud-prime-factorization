output "master_ip" {
  value = aws_instance.master.public_ip
}

output "worker_ips" {
  value = [for w in aws_instance.worker : w.public_ip]
}

output "worker_ips_private" {
  value = [for w in aws_instance.worker : w.private_ip]
}

output "master_command" {
  value = <<EOL
./cado-nfs.py ${var.number_to_factor} \
    server.address=${aws_instance.master.private_ip} \
    tasks.workdir=/tmp/c100 \
    slaves.hostnames=${join(",", [for w in aws_instance.worker : w.private_ip])} \
    slaves.scriptpath=/root/cado-nfs/ \
    --slaves 24 \
    --client-threads 2
EOL
}
