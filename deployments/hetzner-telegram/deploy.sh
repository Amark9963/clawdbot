#!/bin/bash
# Deployment script for Clawdbot VPS configuration
# Usage: ./deploy.sh [pull|push]

VPS="root@46.62.139.120"
VPS_CONFIG="/root/.clawdbot/clawdbot.json"
VPS_AUTH="/root/.clawdbot/agents/main/agent/auth-profiles.json"
VPS_SERVICE="/etc/systemd/system/clawdbot.service"

case "$1" in
  pull)
    echo "📥 Pulling configuration from VPS..."
    scp $VPS:$VPS_CONFIG clawdbot.json
    scp $VPS:$VPS_AUTH auth-profiles.json
    scp $VPS:$VPS_SERVICE clawdbot.service
    echo "✅ Configuration pulled from VPS"
    echo "⚠️  Remember: auth-profiles.json contains secrets (in .gitignore)"
    ;;

  push)
    echo "📤 Pushing configuration to VPS..."
    scp clawdbot.json $VPS:$VPS_CONFIG
    echo "🔄 Restarting Clawdbot service..."
    ssh $VPS 'systemctl restart clawdbot.service'
    sleep 3
    echo "📊 Service status:"
    ssh $VPS 'systemctl status clawdbot.service --no-pager -l'
    ;;

  *)
    echo "Usage: $0 {pull|push}"
    echo ""
    echo "  pull  - Download current config from VPS"
    echo "  push  - Upload local config to VPS and restart service"
    exit 1
    ;;
esac
