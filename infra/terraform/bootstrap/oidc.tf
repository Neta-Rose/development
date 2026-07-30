# GitHub Actions → AWS via OIDC, so CI holds no long-lived access keys.

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # AWS stopped verifying thumbprints for well-known IdPs like GitHub's in 2023 — the
  # value is retained only because the API still accepts it. A stale entry here does not
  # break token exchange, so this never needs rotating.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}
