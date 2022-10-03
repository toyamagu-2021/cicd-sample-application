// oidc provider
resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_oidc_provider_github ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  depends_on = [
    resource.aws_iam_openid_connect_provider.github[0]
  ]
}

// role
data "aws_iam_policy_document" "trusted_github_oidc" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = length(var.github_oidc_repos) == 1 ? "StringLike" : "ForAnyValue:StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for repo in var.github_oidc_repos : "repo:${repo.owner}/${repo.repository}:*"]
    }
  }
}

data "aws_iam_policy_document" "github_actions" {
  // allow running `aws sts get-caller-identity`
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions" {
  name        = "cicd-sample-application"
  path        = "/"
  description = "Policy for GitHub Actions"
  policy      = data.aws_iam_policy_document.github_actions.json
}

resource "aws_iam_role" "github_actions" {
  name               = "githubactions-oidc-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.trusted_github_oidc.json
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}

resource "aws_ecr_repository" "foo" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }
}
