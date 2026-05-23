#!/usr/bin/env bash
# ============================================================
# Application Insights デプロイスクリプト
# ============================================================
# 使い方:
#   bash deploy.sh
#
# 前提:
#   - Azure CLI でログイン済み (az login)
#   - 対象サブスクリプションが選択済み (az account set -s <id>)
# ============================================================

set -euo pipefail

# ----- ユーザー調整パラメータ -----
RESOURCE_GROUP_NAME="rg-appinsights-baseline"
LOCATION="japaneast"
DEPLOYMENT_NAME="appinsights"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# main.bicepparam が readEnvironmentVariable('PRINCIPAL_ID') で参照する
export PRINCIPAL_ID="${PRINCIPAL_ID:-$(az ad signed-in-user show --query id -o tsv)}"

echo "=== Azure ログイン状態 ==="
az account show --query "{subscription:name, id:id, user:user.name}" -o table
echo ""
echo "リソースグループ: $RESOURCE_GROUP_NAME ($LOCATION)"
echo "ロール付与先プリンシパル ID: $PRINCIPAL_ID"

echo ""
echo "=== リソースグループを作成/確認 ==="
az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION" --output none

echo ""
echo "=== Bicep デプロイを開始 ==="
az deployment group create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$DEPLOYMENT_NAME" \
    --template-file "$SCRIPT_DIR/main.bicep" \
    --parameters "$SCRIPT_DIR/main.bicepparam" \
    --output none

# 出力された接続文字列を取得
CONNECTION_STRING=$(az deployment group show \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$DEPLOYMENT_NAME" \
    --query properties.outputs.connectionString.value -o tsv)

echo ""
echo "==================== デプロイ完了 ===================="
echo "以下の接続文字列を .env の APPLICATIONINSIGHTS_CONNECTION_STRING に設定してください:"
echo ""
echo "$CONNECTION_STRING"
echo ""
echo "再表示したい場合:"
echo "  az deployment group show -g $RESOURCE_GROUP_NAME -n $DEPLOYMENT_NAME --query properties.outputs.connectionString.value -o tsv"
echo "======================================================"
