output "cluster_id" {
  value = aws_eks_cluster.awsclass.id
}

output "node_group_id" {
  value = aws_eks_node_group.awsclass.id
}

output "vpc_id" {
  value = aws_vpc.awsclass_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.awsclass_subnet[*].id
}

