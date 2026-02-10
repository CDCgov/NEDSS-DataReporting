# Docker GHCR Authentication

The below steps will allow Docker to pull images from the private `cdcent` GitHub Container Registry.

1.  **GitHub Personal Access Token (Classic):** You must create a "Classic" PAT.
    - **Note:** Fine-grained tokens are **not** currently supported because they lack the necessary `read:packages` scope for GHCR and cannot be authorized for SSO with the `cdcent` organization.
    - Go to [Developer Settings -> Personal access tokens -> Tokens (classic)](https://github.com/settings/tokens).
    - Generate a new token.
    - **Scopes:** Select `read:packages`.
    - Copy the generated token
2.  **SSO Authorization (CRITICAL):**
    - After creating the token, you **must authorize it for SSO usage** with the `cdcent` organization.
    - Click "Configure SSO" next to your token name in the list.
    - Click "Authorize" next to `cdcent`.
    - _If you skip this step, you will get an `invalid token` or `403 Forbidden` error._

### Docker Login

Once you have your authorized PAT, log in to the registry:

```bash
# Using the token directly (paste when prompted for a password)
docker login ghcr.io -u <YOUR_GITHUB_USERNAME>

# OR piping the token for security (if saved in a file or variable)
cat my_pat.txt | docker login ghcr.io -u <YOUR_GITHUB_USERNAME> --password-stdin
```

### Validation (Optional)

Once the Docker Login is complete, the NEDSSDB image can be pulled using the following command

```sh
docker pull --platform linux/amd64 ghcr.io/cdcent/nedssdb:latest
```
