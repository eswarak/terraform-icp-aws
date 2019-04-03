resource "aws_iam_role" "icpmaster_ec2_iam_role" {
  count = "${var.existing_ec2_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.ec2_iam_role_name}m-${random_id.clusterid.hex}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "icpmaster_s3_policy" {
  count = "${var.existing_ec2_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.ec2_iam_role_name}m-s3policy-${random_id.clusterid.hex}"
  role = "${aws_iam_role.icpmaster_ec2_iam_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [ "s3:ListBucket", "s3:GetObject", "s3:PutObject" ],
      "Resource": [
         "${aws_s3_bucket.icp_binaries.arn}",
         "${aws_s3_bucket.icp_binaries.arn}/*",
         "${aws_s3_bucket.icp_config_backup.arn}",
         "${aws_s3_bucket.icp_config_backup.arn}/*",
         "${aws_s3_bucket.icp_registry.arn}",
         "${aws_s3_bucket.icp_registry.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "icpmaster_ec2mesg_policy" {
  count = "${var.existing_ec2_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.ec2_iam_role_name}m-ec2mesgp-${random_id.clusterid.hex}"
  role = "${aws_iam_role.icpmaster_ec2_iam_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [ "ec2messages:GetMessages"],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "icpmaster_ssmaccess_policy" {
  count = "${var.existing_ec2_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.ec2_iam_role_name}m-ssmaccessp-${random_id.clusterid.hex}"
  role = "${aws_iam_role.icpmaster_ec2_iam_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [ "ssm:PutParameter", "ssm:GetParameter", "ssm:DeleteParameters", "ssm:UpdateInstanceInformation", "ssm:ListAssociations", "ssm:ListInstanceAssociations"],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "icpmaster_autoscale_policy" {
  count = "${var.existing_ec2_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.ec2_iam_role_name}m-autoscalep-${random_id.clusterid.hex}"
  role = "${aws_iam_role.icpmaster_ec2_iam_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [ "autoscaling:DescribeAutoScalingGroups", "autoscaling:DescribeLaunchConfigurations", "autoscaling:DescribeTags" ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "icpmaster_ec2access_policy" {
  count = "${var.existing_ec2_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.ec2_iam_role_name}m-ec2policy-${random_id.clusterid.hex}"
  role = "${aws_iam_role.icpmaster_ec2_iam_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [ "ec2:AttachVolume", "ec2:AuthorizeSecurityGroupIngress", "ec2:CreateRoute",
                  "ec2:CreateSecurityGroup", "ec2:CreateTags", "ec2:CreateVolume",
                  "ec2:DeleteRoute", "ec2:DeleteSecurityGroup", "ec2:DeleteVolume",
                  "ec2:DescribeInstances", "ec2:DescribeRegions", "ec2:DescribeRouteTables",
                  "ec2:DescribeSecurityGroups", "ec2:DescribeSubnets", "ec2:DescribeVolumes",
                  "ec2:DescribeVpcs", "ec2:DetachVolume", "ec2:ModifyInstanceAttribute",
                  "ec2:ModifyVolume", "ec2:RevokeSecurityGroupIngress" ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "icpmaster_elb_policy" {
  count = "${var.existing_ec2_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.ec2_iam_role_name}m-elbpolicy-${random_id.clusterid.hex}"
  role = "${aws_iam_role.icpmaster_ec2_iam_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [ "elasticloadbalancing:AddTags", "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
                  "elasticloadbalancing:AttachLoadBalancerToSubnets", "elasticloadbalancing:ConfigureHealthCheck",
                  "elasticloadbalancing:CreateListener", "elasticloadbalancing:CreateLoadBalancer",
                  "elasticloadbalancing:CreateLoadBalancerPolicy", "elasticloadbalancing:CreateLoadBalancerListeners",
                  "elasticloadbalancing:CreateTargetGroup", "elasticloadbalancing:DeleteListener",
                  "elasticloadbalancing:DeleteLoadBalancer", "elasticloadbalancing:DeleteLoadBalancerListeners",
                  "elasticloadbalancing:DeleteTargetGroup", "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                  "elasticloadbalancing:DescribeListeners", "elasticloadbalancing:DescribeLoadBalancers",
                  "elasticloadbalancing:DescribeLoadBalancerAttributes", "elasticloadbalancing:DescribeTargetGroups",
                  "elasticloadbalancing:DescribeTargetHealth", "elasticloadbalancing:DetachLoadBalancerFromSubnets",
                  "elasticloadbalancing:ModifyListener", "elasticloadbalancing:ModifyLoadBalancerAttributes",
                  "elasticloadbalancing:ModifyTargetGroup", "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                  "elasticloadbalancing:RegisterTargets", "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
                  "elasticloadbalancing:SetLoadBalancerPoliciesOfListener" ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "icpmaster_iam_policy" {
  count = "${var.existing_ec2_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.ec2_iam_role_name}m-iampolicy-${random_id.clusterid.hex}"
  role = "${aws_iam_role.icpmaster_ec2_iam_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [ "iam:CreateServiceLinkedRole" ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "icp_ec2_master_profile" {
  count = "${var.existing_ec2_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.ec2_iam_role_name}-master-profile-${random_id.clusterid.hex}"
  role = "${aws_iam_role.icpmaster_ec2_iam_role.name}"
}

resource "aws_iam_role" "icpnode_ec2_iam_role" {
  count = "${var.existing_ec2_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.ec2_iam_role_name}n-${random_id.clusterid.hex}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "icpnode_s3_policy" {
  count = "${var.existing_ec2_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.ec2_iam_role_name}n-s3policy-${random_id.clusterid.hex}"
  role = "${aws_iam_role.icpnode_ec2_iam_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [ "s3:ListBucket", "s3:GetObject" ],
      "Resource": [
         "${aws_s3_bucket.icp_binaries.arn}",
         "${aws_s3_bucket.icp_binaries.arn}/*",
         "${aws_s3_bucket.icp_config_backup.arn}",
         "${aws_s3_bucket.icp_config_backup.arn}/*",
         "${aws_s3_bucket.icp_registry.arn}",
         "${aws_s3_bucket.icp_registry.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "icpnode_ec2mesg_policy" {
  count = "${var.existing_ec2_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.ec2_iam_role_name}n-ec2mesgp-${random_id.clusterid.hex}"
  role = "${aws_iam_role.icpnode_ec2_iam_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [ "ec2messages:GetMessages"],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "icpnode_ssmaccess_policy" {
  count = "${var.existing_ec2_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.ec2_iam_role_name}n-ssmaccessp-${random_id.clusterid.hex}"
  role = "${aws_iam_role.icpnode_ec2_iam_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [ "ssm:PutParameter", "ssm:GetParameter", "ssm:DeleteParameters", "ssm:UpdateInstanceInformation", "ssm:ListAssociations", "ssm:ListInstanceAssociations"],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "icpnode_ec2access_policy" {
  count = "${var.existing_ec2_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.ec2_iam_role_name}n-ec2policy-${random_id.clusterid.hex}"
  role = "${aws_iam_role.icpnode_ec2_iam_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [ 
                  "ec2:DescribeInstances", "ec2:DescribeRegions"
       ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "icp_ec2_node_profile" {
  count = "${var.existing_ec2_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.ec2_iam_role_name}-node-profile-${random_id.clusterid.hex}"
  role = "${aws_iam_role.icpnode_ec2_iam_role.name}"
}

