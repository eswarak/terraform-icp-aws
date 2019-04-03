#resource "random_id" "clusterid" {
#  byte_length = "2"
#}

resource "aws_s3_bucket" "icp_binaries" {
  count         = "${var.image_location != "" && substr(var.image_location, 0, min(2, length(var.image_location))) != "s3" ? 1 : 0}"
  bucket        = "icpbinaries-${random_id.clusterid.hex}"
  acl           = "private"
  #force_destroy = true

  tags =
    "${merge(
      var.default_tags,
      map("Name", "icp-install-binaries-${random_id.clusterid.hex}"),
      map("icp_instance", var.instance_name ))}"

}

resource "null_resource" "icp_install_package" {
  count         = "${var.image_location != "" && substr(var.image_location, 0, min(2, length(var.image_location))) != "s3" ? 1 : 0}"

  depends_on = [
    "null_resource.install_aws_cli"
  ]
  # due to AWS provider not supporting multi-part uploads,
  # we have to use the AWS CLI to upload the binary instead

  provisioner "local-exec" {
    command = <<EOF
${path.module}/awscli/bin/aws s3 cp ${var.image_location}  s3://${aws_s3_bucket.icp_binaries.id}/${var.image_name}
EOF

    # AWS credentials?
    environment = {

    }
  }
}

resource "null_resource" "update_bootstrap" {
  provisioner "local-exec" {
    command = "sed -i -e 's/ibm-cloud-private-x86_64-3.1.0.tar.gz/${var.image_name}/g' scripts/bootstrap.sh"
  }
}

# upload binaries to created s3 bucket
resource "aws_s3_bucket_object" "docker_install_package" {
  count  = "${var.docker_package_location != "" && substr(var.docker_package_location, 0, min(2, length(var.docker_package_location))) != "s3" ? 1 : 0}"
  bucket = "${aws_s3_bucket.icp_binaries.id}"
  key    = "icp-docker.bin"
  source = "${var.docker_package_location}"
}

# allow my VPC to download the binaries
resource "aws_s3_bucket_policy" "icp_binaries_allow_vpc" {
  count  = "${var.docker_package_location != "" && substr(var.docker_package_location, 0, min(2, length(var.docker_package_location))) != "s3" ? 1 : 0}"
  bucket = "${aws_s3_bucket.icp_binaries.id}"
  policy =<<POLICY
{
  "Version": "2012-10-17",
  "Id": "icp_binaries_vpc-${random_id.clusterid.hex}",
  "Statement": [
    {
      "Sid": "Access-to-terraform-user",
      "Action": [ 
         "s3:GetObject", "s3:PutObject", "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
         "${aws_s3_bucket.icp_binaries.arn}",
         "${aws_s3_bucket.icp_binaries.arn}/*"
      ],
      "Principal": {
          "AWS": "${data.aws_caller_identity.current.arn}"
      }
    },
    {
      "Sid": "Access-from-icp-vpc",
      "Action": [ 
         "s3:GetObject", "s3:PutObject", "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Principal": "*",
      "Resource": ["${aws_s3_bucket.icp_binaries.arn}",
                   "${aws_s3_bucket.icp_binaries.arn}/*"],
      "Condition": {
        "StringEquals": {
          "aws:sourceVpc": "${aws_vpc.icp_vpc.id}"
        }
      }
    }
  ]
}
POLICY
}


# configuration backup s3 bucket
resource "aws_s3_bucket" "icp_config_backup" {
  depends_on    = [ "null_resource.update_bootstrap" ]
  bucket        = "icpbackup-${random_id.clusterid.hex}"
  acl           = "private"
  force_destroy = true # Set to false to keep the backup even if we do a terraform destroy

  tags =
    "${merge(
      var.default_tags,
      map("Name", "icp-backup-${random_id.clusterid.hex}"),
      map("icp_instance", var.instance_name ))}"
}

# upload scripts to config backup bucket
resource "aws_s3_bucket_object" "bootstrap" {
  bucket = "${aws_s3_bucket.icp_config_backup.id}"
  key    = "scripts/bootstrap.sh"
  source = "${path.module}/scripts/bootstrap.sh"
}

resource "aws_s3_bucket_object" "create_client_cert" {
  bucket = "${aws_s3_bucket.icp_config_backup.id}"
  key    = "scripts/create_client_cert.sh"
  source = "${path.module}/scripts/create_client_cert.sh"
}

resource "aws_s3_bucket_object" "functions" {
  bucket = "${aws_s3_bucket.icp_config_backup.id}"
  key    = "scripts/functions.sh"
  source = "${path.module}/scripts/functions.sh"
}

resource "aws_s3_bucket_object" "start_install" {
  bucket = "${aws_s3_bucket.icp_config_backup.id}"
  key    = "scripts/start_install.sh"
  source = "${path.module}/scripts/start_install.sh"
}

# lock down bucket access to just my VPC and terraform user
resource "aws_s3_bucket_policy" "icp_config_backup_policy_allow_vpc" {
  bucket = "${aws_s3_bucket.icp_config_backup.id}"
  policy =<<POLICY
{
  "Version": "2012-10-17",
  "Id": "icp_config_backup_vpc-${random_id.clusterid.hex}",
  "Statement": [
     {
       "Sid": "Access-to-terraform-user",
       "Action": [ 
          "s3:GetObject", "s3:PutObject", "s3:ListBucket"
       ],
       "Effect": "Allow",
       "Resource": ["${aws_s3_bucket.icp_config_backup.arn}",
                    "${aws_s3_bucket.icp_config_backup.arn}/*"],
       "Principal": {
         "AWS": [
           "${data.aws_caller_identity.current.arn}"
         ]
       }
     },
     {
       "Sid": "Access-to-icp-vpc",
       "Action": [ 
          "s3:GetObject", "s3:PutObject", "s3:ListBucket"
       ],
       "Effect": "Allow",
       "Resource": ["${aws_s3_bucket.icp_config_backup.arn}",
                    "${aws_s3_bucket.icp_config_backup.arn}/*"],
       "Principal": "*",
       "Condition": {
         "StringEquals": {
           "aws:sourceVpc": "${aws_vpc.icp_vpc.id}"
         }
       }
     }
   ]
}
POLICY
}

resource "aws_s3_bucket" "icp_registry" {
  bucket        = "icpregistry-${random_id.clusterid.hex}"
  acl           = "private"
  #force_destroy = true

  tags =
    "${merge(
      var.default_tags,
      map("Name", "icp-registry-${random_id.clusterid.hex}"))}"
}

resource "aws_s3_bucket_policy" "icp_registry_policy_allow_vpc" {
  bucket = "${aws_s3_bucket.icp_registry.id}"
  policy =<<POLICY
{
  "Version": "2012-10-17",
  "Id": "icp_config_backup_vpc-${random_id.clusterid.hex}",
  "Statement": [
     {
       "Sid": "Access-to-terraform-user",
       "Action": [
          "s3:GetObject", "s3:PutObject", "s3:ListBucket"
       ],
       "Effect": "Allow",
       "Resource": ["${aws_s3_bucket.icp_registry.arn}",
                    "${aws_s3_bucket.icp_registry.arn}/*"],
       "Principal": {
         "AWS": [
           "${data.aws_caller_identity.current.arn}"
         ]
       }
     },
     {
       "Sid": "Access-to-icp-vpc",
       "Action": [
          "s3:GetObject", "s3:PutObject", "s3:ListBucket"
       ],
       "Effect": "Allow",
       "Resource": ["${aws_s3_bucket.icp_registry.arn}",
                    "${aws_s3_bucket.icp_registry.arn}/*"],
       "Principal": "*",
       "Condition": {
         "StringEquals": {
           "aws:sourceVpc": "${aws_vpc.icp_vpc.id}"
         }
       }
     }
   ]
}
POLICY
}
