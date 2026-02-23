output "dk_vpc_id" {
  value = aws_vpc.dk_production_network.id
}

output "dk_internet_gateway_id" {
  value = aws_internet_gateway.dk_production_igw.id
}
