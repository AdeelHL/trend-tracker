# cicd.tf — lets GitHub Actions deploy to AWS WITHOUT any stored secret keys.
# This is the "OIDC" keyless trust: AWS trusts short-lived tokens that GitHub
# issues, but only for our specific repository.

# 1) Register GitHub as a trusted identity provider in our AWS account.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# 2) The "guest list" — who is allowed to assume the deploy role.
#    Only GitHub Actions runs FROM our repo can get in.
data "aws_iam_policy_document" "gha_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # The token's audience must be AWS STS.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # The token must come from OUR repo (any branch).
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

# 3) The role GitHub Actions assumes when deploying.
resource "aws_iam_role" "gha_deploy" {
  name               = "${var.project_name}-gha-deploy"
  assume_role_policy = data.aws_iam_policy_document.gha_assume.json
}

# Helpers to build ARNs without hard-coding the account id.
data "aws_caller_identity" "current" {}

# 4) What the deploy role can do — SCOPED to this project (least privilege).
data "aws_iam_policy_document" "gha_deploy_perms" {
  # (a) Full control of the app services we manage. These services aren't
  #     privilege-escalation vectors, so we allow their actions broadly.
  statement {
    sid    = "AppServices"
    effect = "Allow"
    actions = [
      "lambda:*",
      "apigateway:*", # covers API Gateway v2 (HTTP API)
      "dynamodb:*",
      "logs:*",
    ]
    resources = ["*"]
  }

  # (b) IAM — limited to roles/policies named trend-tracker-*.
  #     The role can create/manage ONLY this project's roles, not arbitrary
  #     admin identities. PassRole is likewise limited to our roles.
  statement {
    sid    = "ProjectIamRoles"
    effect = "Allow"
    actions = [
      "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy", "iam:TagRole", "iam:UntagRole", "iam:ListRoleTags",
      "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy", "iam:ListRolePolicies",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole", "iam:PassRole",
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"]
  }

  # (c) IAM — manage ONLY the GitHub OIDC provider resource.
  statement {
    sid    = "GithubOidcProvider"
    effect = "Allow"
    actions = [
      "iam:GetOpenIDConnectProvider", "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider", "iam:UpdateOpenIDConnectProviderThumbprint",
      "iam:AddClientIDToOpenIDConnectProvider", "iam:RemoveClientIDFromOpenIDConnectProvider",
      "iam:TagOpenIDConnectProvider", "iam:UntagOpenIDConnectProvider", "iam:ListOpenIDConnectProviderTags",
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
  }

  # (d) S3 — only the Terraform state bucket (read/write state + lock file).
  statement {
    sid     = "TerraformStateBucket"
    effect  = "Allow"
    actions = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      "arn:aws:s3:::trend-tracker-tfstate-${data.aws_caller_identity.current.account_id}",
      "arn:aws:s3:::trend-tracker-tfstate-${data.aws_caller_identity.current.account_id}/*",
    ]
  }

  # (e) S3 — full control of ONLY the dashboard website bucket.
  statement {
    sid     = "DashboardBucket"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${var.project_name}-site-${data.aws_caller_identity.current.account_id}",
      "arn:aws:s3:::${var.project_name}-site-${data.aws_caller_identity.current.account_id}/*",
    ]
  }
}

resource "aws_iam_role_policy" "gha_deploy_perms" {
  name   = "${var.project_name}-gha-deploy-perms"
  role   = aws_iam_role.gha_deploy.id
  policy = data.aws_iam_policy_document.gha_deploy_perms.json
}
