# Mini Cloud Launcher

This is my solution for a mini-cloud launcher for Bitnami Wordpress AMIs.

## Features

* Launch Wordpress Instances in a new Security Group.
* List instances created with the cloud launcher
* Start and stop instances from the list of managed instances

## Installation

* Run `bundle install --without development`
* Create a `.env` file to configure your session secret, containing the following:

      SESSION_SECRET=someRandomData
* Run `bundle exec ruby app.rb`
* Visit `localhost:4567` and enter your credentials

## IAM Policy
The launcher takes your AWS credentials as login, a fairly minimal IAM policy that can be used is below, this could possibly be minimised further:

    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "Stmt1393701208000",
          "Effect": "Allow",
          "Action": [
            "ec2:AttachVolume",
            "ec2:CreateTags",
            "ec2:CreateVolume",
            "ec2:DeleteTags",
            "ec2:DeleteVolume",
            "ec2:DescribeImageAttribute",
            "ec2:DescribeImages",
            "ec2:DescribeInstanceAttribute",
            "ec2:DescribeInstanceStatus",
            "ec2:DescribeInstances",
            "ec2:DescribeTags",
            "ec2:DescribeVolumeAttribute",
            "ec2:DescribeVolumeStatus",
            "ec2:DescribeVolumes",
            "ec2:DisassociateAddress",
            "ec2:GetPasswordData",
            "ec2:ImportKeyPair",
            "ec2:RunInstances",
            "ec2:StartInstances",
            "ec2:StopInstances",
            "ec2:TerminateInstances",
            "ec2:CreateSecurityGroup",
            "ec2:DescribeSecurityGroups",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:AuthorizeSecurityGroupEgress"
          ],
          "Resource": "*"
        }
      ]
    }

