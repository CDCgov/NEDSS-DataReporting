# Docker GHCR Authentication

The below steps will allow Docker to pull images from the private `cdcent` GitHub Container Registry.

1.  **Generate a GitHub Personal Access Token (Classic):** You must create a "Classic" PAT.
    - Go to [Developer Settings -> Personal access tokens -> Tokens (classic)](https://github.com/settings/tokens).
    - Generate a new token.
    - **Scopes:** Select `read:packages`.
    - Click "Generate token"
    - Copy the generated token
2.  **Docker Login:** To allow Docker to use the generated token to authenticate, use one of the two options below.

    ```bash
    # Using the token directly (paste when prompted for a password)
    docker login ghcr.io -u <YOUR_GITHUB_USERNAME>
    ```

    ```bash
    # OR piping the token for security (if saved in a file or variable)
    cat my_pat.txt | docker login ghcr.io -u <YOUR_GITHUB_USERNAME> --password-stdin
    ```

3.  Validation (Optional)
    Once the Docker Login is complete, the NEDSSDB image can be pulled using the following command
    ```bash
    docker pull --platform linux/amd64 ghcr.io/cdcent/nedssdb:latest
    ```
