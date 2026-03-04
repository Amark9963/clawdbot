#!/bin/bash
# Deployment script for Clawdbot VPS configuration
# Usage: ./deploy.sh [pull|push]

VPS_USER="amar"
VPS_HOST="46.62.139.120"
VPS_PORT="2266"
VPS="$VPS_USER@$VPS_HOST"
SSH="ssh -p $VPS_PORT"
SCP="scp -P $VPS_PORT"

VPS_CONFIG="/home/amar/.openclaw/openclaw.json"
VPS_AUTH="/home/amar/.openclaw/agents/main/agent/auth-profiles.json"
VPS_SERVICE="/etc/systemd/system/clawdbot.service"

case "$1" in
  pull)
    echo "📥 Pulling configuration from VPS..."
    $SCP $VPS:$VPS_CONFIG clawdbot.json
    $SCP $VPS:$VPS_AUTH auth-profiles.json
    $SSH $VPS "sudo cat $VPS_SERVICE" > clawdbot.service
    echo "✅ Configuration pulled from VPS"
    echo "⚠️  Remember: auth-profiles.json contains secrets (in .gitignore)"
    ;;

  push)
    echo "📤 Pushing configuration to VPS..."
    $SCP clawdbot.json $VPS:$VPS_CONFIG
    echo "🔄 Restarting Clawdbot service..."
    $SSH $VPS 'sudo systemctl restart clawdbot.service'
    sleep 5
    echo "📊 Service status:"
    $SSH $VPS 'sudo systemctl status clawdbot.service --no-pager -l'
    ;;

  *)
    echo "Usage: $0 {pull|push}"
    echo ""
    echo "  pull  - Download current config from VPS"
    echo "  push  - Upload local config to VPS and restart service"
    exit 1
    ;;
esac
