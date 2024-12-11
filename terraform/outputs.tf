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
    tasks.workdir=/home/ubuntu/cado-nfs-workdir \
    tasks.execpath=/home/ubuntu/cado-nfs/build \
    slaves.hostnames=${join(",", [for w in aws_instance.worker : "${w.private_ip}"])} \
    slaves.scriptpath=/home/ubuntu/cado-nfs/ \
    --slaves ${var.number_of_slaves} \
    --client-threads ${var.number_of_threads}
EOL
}
