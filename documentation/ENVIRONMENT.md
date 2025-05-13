# Environment Configuration

This project uses environment variables for configuration. You can set these variables in one of the following files:

## Environment Files

1. **`.env`** - Main environment file for local development and testing
2. **`.env.unified`** - Alternative environment file (for when you need different configurations)
3. **`.env.example`** - Template with placeholders (do not use directly)

## Setting Up Your Environment

1. Copy `.env.example` to `.env` or `.env.unified`:
   ```bash
   cp .env.example .env
   ```

2. Edit the file and replace placeholder values with your actual configuration.

## GitHub Actions Configuration

For GitHub Actions deployment, the environment variables are configured as repository secrets. Make sure to add the following secrets to your GitHub repository:

- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`
- `MONGODB_USERNAME`
- `MONGODB_PASSWORD`
- `JWT_SECRET`

## Verifying Your Configuration

You can verify that your environment configuration is correct by running:

```bash
./scripts/verify-secrets.sh
```

This will check that all required environment variables are properly set.
