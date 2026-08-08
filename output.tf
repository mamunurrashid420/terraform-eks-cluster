output "cluster_id" {
  value = aws_eks_cluster.aws-prac.id
}

output "node_group_id" {
  value = aws_eks_node_group.aws-prac.id
}

output "vpc_id" {
  value = aws_vpc.aws-prac_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.aws-prac_subnet[*].id
}

