resource "aws_vpc" "student01" {
  cidr_blcok = "10.0.0.0/16"
  default_security_group_id="student01"
}

resource "aws_subnet" "student01-priv" {
  vpc_id = "${aws_vpc.student01.id}"
  cidr_block = "10.0.0.0/28"
  tags {
    Name = "Private Network"
  }
}

resource "aws_subnet" "student02-pub" {
  vpc_id = "${aws_vpc.student01.id}"
  cidr_block = "10.0.1.0/28"
  tags {
    Name = "Public Network"
  }
}

resource "aws_internet_gateway" "student01-gw" {
  vpc_id = "${aws_vpc.student01.id}"
  tags {
    Name = "Internet Gateway"
  }
}

resource "aws_route_table" "student01-rt" {
  vpc_id = "${aws_vpc.stduent01.id}"
  route {
    cidr_block = "10.0.1.0/28"
    gateway_id = "${aws_internet_gateway.student01-gw.id}"
  }
  tags {
    Name = "Public Network Routing"
  }
}
