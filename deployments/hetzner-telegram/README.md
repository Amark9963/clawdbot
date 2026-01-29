# Clawdbot VPS Configuration - Hetzner + Telegram

**VPS**: 46.62.139.120 (Hetzner)
**Bot**: @Homeiai_bot (Telegram)
**Model**: MiniMax M2 via OpenRouter ($0.20/$1.00 per 1M tokens)
**Deployment**: Direct install (npm global) + systemd service

## 📁 Configuration Files

- [clawdbot.json](clawdbot.json) - Main Clawdbot configuration
- `auth-profiles.json` - API key authentication (OpenRouter) - **NOT committed to git**
  - See [auth-profiles.json.template](auth-profiles.json.template) for format
- `clawdbot.service` - Systemd service configuration - **NOT committed to git**
  - See [clawdbot.service.template](clawdbot.service.template) for format
- [deploy.sh](deploy.sh) - Deployment script for push/pull

## 🚀 Deployment Workflow

### Edit & Deploy Configuration

1. Edit [clawdbot.json](clawdbot.json) locally in this directory
2. Commit changes to git: `git add clawdbot.json && git commit -m "Update config"`
3. Deploy to VPS:
   ```bash
   ./deploy.sh push
   ```

### Pull Current Configuration from VPS

```bash
./deploy.sh pull
```

### Manual Deployment (without script)

```bash
# Push config
scp clawdbot.json root@46.62.139.120:/root/.clawdbot/clawdbot.json
ssh root@46.62.139.120 'systemctl restart clawdbot.service'

# Pull config
scp root@46.62.139.120:/root/.clawdbot/clawdbot.json .
scp root@46.62.139.120:/root/.clawdbot/agents/main/agent/auth-profiles.json .
scp root@46.62.139.120:/etc/systemd/system/clawdbot.service .
```

## 🤖 Model Configuration

**Current**: MiniMax M2 (OpenRouter)
- Provider: `openrouter`
- Model: `minimax/minimax-m2`
- Cost: $0.20 input / $1.00 output per 1M tokens
- Context: 192k tokens
- Features: Tool use, function calling
- Session pruning: Enabled (prevents timeouts from large sessions)

**Previously tested:**
- Claude Opus 4.5: $15/$75 per 1M tokens (too expensive)
- DeepSeek V3: $0.27/$1.10 per 1M tokens (works well)

## 🔒 Security Configuration

### Firewall (UFW)
```bash
ssh root@46.62.139.120 'ufw status verbose'
```

**Current Rules:**
- SSH (22): Open to all IPs - protected by fail2ban
- HTTP (80): Open for nginx
- HTTPS (443): Open for nginx
- Clawdbot ports (18789, 18791): Bound to localhost only (secure)

### fail2ban
```bash
# Check status
ssh root@46.62.139.120 'fail2ban-client status sshd'

# Unban IP
ssh root@46.62.139.120 'fail2ban-client set sshd unbanip IP_ADDRESS'
```

**Settings:**
- Max retries: 3 failed attempts
- Ban time: 1 hour
- Find time: 10 minutes

### Clawdbot Ports (Secure)
- Gateway (18789): Localhost only (`127.0.0.1:18789`)
- Browser (18791): Localhost only (`127.0.0.1:18791`)
- **NOT exposed** to internet - no authentication needed

## 🔑 API Keys & Secrets

**⚠️ NEVER commit actual API keys to git!**

Store secrets in:
- `auth-profiles.json` (in .gitignore) - see [auth-profiles.json.template](auth-profiles.json.template)
- `clawdbot.service` (in .gitignore) - see [clawdbot.service.template](clawdbot.service.template)

**First-time setup:**
```bash
# Copy templates and add your actual API keys
cp auth-profiles.json.template auth-profiles.json
cp clawdbot.service.template clawdbot.service

# Edit with your real API keys
nano auth-profiles.json
nano clawdbot.service
```

Current API keys (stored on VPS only):
- `TELEGRAM_BOT_TOKEN`: Telegram bot authentication
- `ANTHROPIC_API_KEY`: Claude API (backup, not used)
- `OPENROUTER_API_KEY`: OpenRouter authentication

## 📊 Monitoring & Logs

```bash
# Service status
ssh root@46.62.139.120 'systemctl status clawdbot.service'

# Live logs
ssh root@46.62.139.120 'journalctl -u clawdbot.service -f'

# Recent logs
ssh root@46.62.139.120 'journalctl -u clawdbot.service -n 50'

# Check model status
ssh root@46.62.139.120 'cd /root/clawdbot && node dist/entry.js models status'

# Check channel status
ssh root@46.62.139.120 'cd /root/clawdbot && node dist/entry.js channels status'
```

## 🔧 Common Operations

### Restart Service
```bash
ssh root@46.62.139.120 'systemctl restart clawdbot.service'
```

### Change Model
```bash
# Edit clawdbot.json locally
# Then deploy:
./deploy.sh push
```

### Clear Session (if bot stops responding)
```bash
ssh root@46.62.139.120 'rm /root/.clawdbot/agents/main/sessions/*.jsonl && systemctl restart clawdbot.service'
```

### Update Clawdbot
```bash
ssh root@46.62.139.120 'npm update -g @anthropic-ai/clawdbot && systemctl restart clawdbot.service'
```

## ⚠️ Important Notes

1. **Dynamic IP**: SSH is open to all IPs (secured by SSH keys + fail2ban)
2. **SSH Key Auth**: SSH uses key-based authentication only (password auth disabled)
   - SSH key location: `~/.ssh/id_ed25519` (local machine)
   - Emergency restore: `ssh root@46.62.139.120 'cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config && systemctl restart ssh'`
3. **Running as Root**: Clawdbot runs as root (acceptable since ports not exposed)
4. **Config Sync**: Always commit configuration changes to this repo
5. **Secrets**: Never commit actual API keys - use templates

## 🐛 Troubleshooting

### Bot Not Responding
1. Check service: `systemctl status clawdbot.service`
2. Check errors: `journalctl -u clawdbot.service -n 100`
3. Session too large (timeout):
   - Session pruning is enabled to prevent this automatically
   - If it still happens, clear session manually: `ssh root@46.62.139.120 'rm /root/.clawdbot/agents/main/sessions/*.jsonl && systemctl restart clawdbot.service'`

### Model Errors
- "Unknown model": Check `models status` and [auth-profiles.json](auth-profiles.json)
- "404 No endpoints": Model doesn't support tool use
- Timeout: Model too slow (switch to DeepSeek V3)

### Locked Out (IP Changed)
Contact Hetzner support or use console access to add new IP

## 📝 Change History

- 2026-01-26: Initial deployment with MiniMax M2
- 2026-01-26: Enabled UFW firewall + fail2ban
- 2026-01-26: Opened SSH for dynamic IP support
- 2026-01-27: Created this deployment configuration in main repo

## 🔗 Useful Links

- [Clawdbot Docs](https://docs.clawd.bot/)
- [OpenRouter Models](https://openrouter.ai/models)
- [MiniMax M2 Pricing](https://openrouter.ai/minimax/minimax-m2)
