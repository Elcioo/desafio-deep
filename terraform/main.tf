
# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = "ecs-cluster"
  tags = local.default_tags

}

resource "aws_ecs_task_definition" "frontend" {

  family                   = "frontend-task"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = "frontend"
    image     = local.frontend-image-url # Substitua pela sua imagem Docker
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
      hostPort      = 0 # Mapeamento de porta dinâmica
    }]
  }])
}

resource "aws_ecs_task_definition" "backend" {

  family                   = "backend-task"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = "backend"
    image     = local.backend-image-url # Substitua pela sua imagem Docker
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [{
      containerPort = 5500
      protocol      = "tcp"
      hostPort      = 0 # Mapeamento de porta dinâmica
    }]
  }])
}

# Security Group para Instâncias ECS
resource "aws_security_group" "ecs_instance" {
  vpc_id = aws_vpc.this.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.this.id]
  }
  tags = local.default_tags

  depends_on = [aws_security_group.this, aws_vpc.this]
}



# Instance Profile para Instâncias ECS
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "worker"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  name = "worker"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.this.arn


  }
}

# Associar Capacity Provider ao Cluster
resource "aws_ecs_cluster_capacity_providers" "cluster_capacity_providers" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = [
    aws_ecs_capacity_provider.ecs_capacity_provider.name
  ]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
    weight            = 1
  }
}


# Launch Configuration
resource "aws_launch_configuration" "this" {
  name_prefix          = "ecs-"
  image_id             = "ami-093d9f343e2236e99"
  instance_type        = "t3.micro" # Updated to a type that supports UEFI
  security_groups      = [aws_security_group.ecs_instance.id]
  iam_instance_profile = aws_iam_instance_profile.ecs_instance_profile.name
  key_name             = "elcio" # Key pair name
  user_data            = <<-EOF
              #!/bin/bash
              echo "ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config
              yum update -y
              yum install -y amazon-ecs-agent
              systemctl enable amazon-ecs
              systemctl start amazon-ecs
              EOF
}

resource "aws_autoscaling_group" "this" {
  launch_configuration = aws_launch_configuration.this.id
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
  vpc_zone_identifier  = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  name                 = "ecs-worker"
  depends_on           = [aws_launch_configuration.this]
}

# ECS Service with dynamic port mapping
resource "aws_ecs_service" "frontend" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.frontend.arn
  launch_type     = "EC2"
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_alb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 3000
  }
  tags       = local.default_tags
  depends_on = [aws_alb.this]
}

resource "aws_ecs_service" "backend" {
  name            = "backend-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.backend.arn
  launch_type     = "EC2"
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_alb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 5500
  }
  tags       = local.default_tags
  depends_on = [aws_alb.this]
}



