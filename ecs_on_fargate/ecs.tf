##################################
# ECS Cluster
##################################
# ※ ECSクラスタ:
# Dockerコンテナを実行するホストサーバーを論理的に束ねるリソース

resource "aws_ecs_cluster" "example" {
  name = "example"
}

##################################
# Task Definition
##################################

resource "aws_ecs_task_definition" "example" {
  family                   = "example"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("./container_definitions.json")

  # Logging Docker to CloudWatch Logs
  execution_role_arn = module.ecs_task_execution_role.iam_role_arn
}

##################################
# ECS Service
##################################

resource "aws_ecs_service" "example" {
  name            = "example"
  cluster         = aws_ecs_cluster.example.arn
  task_definition = aws_ecs_task_definition.example.arn

  # 本番環境では2以上推奨
  #   1の場合、コンテナの異常終了時にESCサービスがタスクを再起動するまでアクセスできなくなるため
  desired_count = 2
  launch_type   = "FARGATE"

  # LATESTは最新バージョンとは限らないため、明示的に指定すること
  platform_version                  = "1.3.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false # public: true, private: false
    security_groups  = [module.nginx_sg.security_group_id]

    subnets = [
      aws_subnet.private_1a.id,
      aws_subnet.private_1c.id,
    ]
  }

  load_balancer {

    # コンテナ定義に複数のコンテナがある場合は、
    # 最初にロードバランサーからリクエストを受け取るコンテナの値を指定

    target_group_arn = aws_lb_target_group.example.arn
    container_name   = "example" # = container_definition.json:name
    container_port   = 80        # = container_definition.json:portMappings.containerPort
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

##################################
# ECS Security Group
##################################

module "nginx_sg" {
  source      = "./security_group"
  name        = "nginx-sg"
  vpc_id      = aws_vpc.example.id
  port        = 80
  cidr_blocks = [aws_vpc.example.cidr_block]
}

