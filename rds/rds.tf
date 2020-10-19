##################################
# DB Parameter Group
##################################

# MySQL
# my.cnfに定義するDB設定は、DBパラメータグループに記述。
resource "aws_db_parameter_group" "example" {
  name   = "example"
  family = "mysql5.7"

  # 文字コードの設定
  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
}

#################
# DB Option Group
#################

# MariaDB監査プラグイン:
# ユーザーのログオンや実行したクエリなどのアクティヴィティを記録するためのプラグイン
resource "aws_db_option_group" "example" {
  name                 = "example"
  engine_name          = "mysql"
  major_engine_version = "5.7"

  option {
    option_name = "MARIADB_AUDIT_PLUGIN"
  }
}

##################################
# DB Subnet Group
##################################

resource "aws_db_subnet_group" "example" {
  name = "example"
  subnet_ids = [
    aws_subnet.private_1a.id,
    aws_subnet.private_1c.id
  ]
}

module "mysql_sg" {
  source      = "./security_group"
  name        = "mysql-sg"
  vpc_id      = aws_vpc.example.id
  port        = 3306
  cidr_blocks = [aws_vpc.example.cidr_block]
}

##################################
# DB Instance
##################################

resource "aws_db_instance" "example" {
  identifier            = "example"
  engine                = "mysql"
  engine_version        = "5.7.25"
  instance_class        = "db.t3.small"
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.example.arn
  username              = "admin"

  # 下記コマンドから初期パスワードの変更を行う
  # $ aws rds modify-db-instance --db-instance-identifier 'example' --master-user-password 'NewMasterPassword!'
  password = "initial_password"

  multi_az                   = true
  publicly_accessible        = false # false: vpc外からのアクセス遮断
  backup_window              = "09:10-09:40"
  backup_retention_period    = 30 # バックアップ期間
  maintenance_window         = "mon:10:10-mon:10:40"
  auto_minor_version_upgrade = false
  deletion_protection        = false # for Development
  #   deletion_protection        = true # for Production
  skip_final_snapshot    = true
  port                   = 3306
  apply_immediately      = false
  vpc_security_group_ids = [module.mysql_sg.security_group_id]
  parameter_group_name   = aws_db_parameter_group.example.name
  option_group_name      = aws_db_option_group.example.name
  db_subnet_group_name   = aws_db_subnet_group.example.name

  lifecycle {
    ignore_changes = [password]
  }
}
