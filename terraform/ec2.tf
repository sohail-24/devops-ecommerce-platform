resource "aws_instance" "master" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  root_block_device {
    volume_size = 20 # 🔥 STORAGE FIX
  }

  user_data = file("../scripts/master.sh")

  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "worker" {
  count                  = var.worker_count
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  root_block_device {
    volume_size = 20
  }

  user_data = templatefile("../scripts/worker.sh", {
    MASTER_IP = aws_instance.master.private_ip
  })

  tags = {
    Name = "k8s-worker-${count.index}"
  }
}
