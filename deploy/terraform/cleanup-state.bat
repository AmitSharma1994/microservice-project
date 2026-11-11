@echo off
REM Remove orphaned manual node group resources from terraform state
REM (EKS Auto Mode manages compute - manual node group IAM role no longer needed)
echo.
echo === Removing orphaned manual node group IAM resources from state ===
terraform state rm "module.eks.module.eks_managed_node_group[\"general\"].aws_iam_role.this[0]"
terraform state rm "module.eks.module.eks_managed_node_group[\"general\"].aws_iam_role_policy_attachment.this[\"AmazonEC2ContainerRegistryReadOnly\"]"
terraform state rm "module.eks.module.eks_managed_node_group[\"general\"].aws_iam_role_policy_attachment.this[\"AmazonEKSWorkerNodePolicy\"]"
terraform state rm "module.eks.module.eks_managed_node_group[\"general\"].aws_iam_role_policy_attachment.this[\"AmazonEKS_CNI_Policy\"]"
terraform state rm "module.eks.module.eks_managed_node_group[\"general\"].data.aws_caller_identity.current"
terraform state rm "module.eks.module.eks_managed_node_group[\"general\"].data.aws_iam_policy_document.assume_role_policy[0]"
terraform state rm "module.eks.module.eks_managed_node_group[\"general\"].data.aws_partition.current"
echo.
echo === Done. Now run: terraform apply -auto-approve ===

