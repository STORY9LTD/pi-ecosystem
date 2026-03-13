# Pi Authentication System

Pi uses **OAuth tokens** (Claude subscription), not raw API keys.

## Local Development
- Auth stored in: `~/.pi/agent/auth.json`
- Format: `{ "anthropic": { "type": "oauth", "access": "...", "refresh": "...", "expires": ... } }`
- The `ANTHROPIC_API_KEY` env var is actually the OAuth access token — not a standard sk-ant-... API key
- Pi auto-refreshes expired tokens using the refresh token

## GitHub Actions / Cloud Runners
- Cannot use ANTHROPIC_API_KEY env var alone
- Must store entire auth.json as base64-encoded secret:
  ```bash
  base64 < ~/.pi/agent/auth.json | gh secret set PI_AUTH_JSON -R STORY9LTD/<repo>
  ```
- In workflow, decode and write to ~/.pi/agent/auth.json before running pi:
  ```yaml
  echo "$PI_AUTH_JSON" | base64 --decode > ~/.pi/agent/auth.json
  ```

## Auth Priority (from pi source)
1. Runtime override (CLI `--api-key`)
2. API key from auth.json (type "api_key")
3. OAuth token from auth.json (type "oauth", auto-refreshed)
4. Environment variable
5. Fallback resolver (models.json custom providers)

## Debugging Auth Issues
1. Check if auth.json exists and is valid JSON
2. Log credential length/prefix (don't log full token!)
3. Test with pi CLI locally first before trying in cloud
4. OAuth tokens expire — refresh tokens handle renewal automatically

## Common Mistakes
- ❌ Assuming ANTHROPIC_API_KEY is a raw API key
- ❌ Only passing access token without refresh token
- ❌ Not base64-encoding the JSON for GitHub secrets
- ❌ Trying to clone pi-ecosystem as private repo (GITHUB_TOKEN can't access other repos)
- ❌ Setting timeout too short (need 60 min for agent blueprints, not 30)
