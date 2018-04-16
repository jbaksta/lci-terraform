resource "aws_security_group" "student01" {
  name = "student01"
  ingress {
    from_port = "all"
    to_port = "22"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
