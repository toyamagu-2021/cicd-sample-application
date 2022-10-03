variable "github_oidc_repos" {
  description = "GitHub OIDC repositories"
  type = list(object({
    owner      = string
    repository = string
    })
  )
}
variable "ecr_repo_name" {
  description = "ECR repository name"
  type        = string
}

variable "create_oidc_provider_github" {
  description = "Flag to create OIDC provider for GitHub"
  type        = bool
  default     = false
}
