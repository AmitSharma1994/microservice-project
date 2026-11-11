@echo off
REM Remove all EKS module managed resources from terraform state
REM The cluster already exists with Auto Mode — we'll use a data source instead
echo.
echo === Removing EKS cluster module resources from state ===
terraform state rm "module.eks.aws_eks_cluster.this[0]"
terraform state rm "module.eks.aws_iam_openid_connect_provider.oidc_provider[0]"
terraform state rm "module.eks.aws_eks_access_entry.this[\"cluster_creator\"]"
terraform state rm "module.eks.aws_eks_access_policy_association.this[\"cluster_creator_admin\"]"
terraform state rm "module.eks.aws_cloudwatch_log_group.this[0]"
terraform state rm "module.eks.aws_iam_policy.custom[0]"
terraform state rm "module.eks.aws_iam_policy.cluster_encryption[0]"
terraform state rm "module.eks.aws_iam_role.this[0]"
terraform state rm "module.eks.aws_iam_role_policy_attachment.this[\"AmazonEKSClusterPolicy\"]"
terraform state rm "module.eks.aws_iam_role_policy_attachment.this[\"AmazonEKSVPCResourceController\"]"
terraform state rm "module.eks.aws_iam_role_policy_attachment.custom[0]"
terraform state rm "module.eks.aws_iam_role_policy_attachment.cluster_encryption[0]"
terraform state rm "module.eks.aws_security_group.cluster[0]"
terraform state rm "module.eks.aws_security_group.node[0]"
terraform state rm "module.eks.aws_security_group_rule.cluster[\"ingress_nodes_443\"]"
terraform state rm "module.eks.aws_security_group_rule.node[\"egress_all\"]"
terraform state rm "module.eks.aws_security_group_rule.node[\"ingress_cluster_443\"]"
terraform state rm "module.eks.aws_security_group_rule.node[\"ingress_cluster_4443_webhook\"]"
terraform state rm "module.eks.aws_security_group_rule.node[\"ingress_cluster_6443_webhook\"]"
terraform state rm "module.eks.aws_security_group_rule.node[\"ingress_cluster_8443_webhook\"]"
terraform state rm "module.eks.aws_security_group_rule.node[\"ingress_cluster_9443_webhook\"]"
terraform state rm "module.eks.aws_security_group_rule.node[\"ingress_cluster_kubelet\"]"
terraform state rm "module.eks.aws_security_group_rule.node[\"ingress_nodes_ephemeral\"]"
terraform state rm "module.eks.aws_security_group_rule.node[\"ingress_self_coredns_tcp\"]"
terraform state rm "module.eks.aws_security_group_rule.node[\"ingress_self_coredns_udp\"]"
terraform state rm "module.eks.module.kms.aws_kms_key.this[0]"
terraform state rm "module.eks.module.kms.aws_kms_alias.this[\"cluster\"]"
terraform state rm "module.eks.aws_ec2_tag.cluster_primary_security_group[\"Environment\"]"
terraform state rm "module.eks.aws_ec2_tag.cluster_primary_security_group[\"ManagedBy\"]"
terraform state rm "module.eks.aws_ec2_tag.cluster_primary_security_group[\"Project\"]"
echo.
echo === Done removing EKS resources from state ===

