#!/usr/bin/env bash
# ============================================================
# Application Insights 削除スクリプト
# ============================================================
# 使い方:
#   bash destroy.sh
#
# 削除内容:
#   - Log Analytics Workspace（ソフトデリート後にパージまで実施）
#   - リソースグループ全体
#
# 前提:
#   - Azure CLI でログイン済み (az login)
# ============================================================

set -euo pipefail

# ----- ユーザー調整パラメータ -----
RESOURCE_GROUP_NAME="rg-appinsights-baseline"

echo "=== リソースグループ '$RESOURCE_GROUP_NAME' を完全削除します ==="
read -r -p "本当に削除しますか？ (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "キャンセルしました。"
    exit 0
fi

# リソースグループが存在しない場合は早期終了
if [ "$(az group exists --name "$RESOURCE_GROUP_NAME")" != "true" ]; then
    echo "リソースグループ '$RESOURCE_GROUP_NAME' は存在しません。終了します。"
    exit 0
fi

# Log Analytics Workspace をパージ削除（ソフトデリート状態を残さない）
echo ""
echo "=== Log Analytics Workspace をパージ削除 ==="
WORKSPACE_NAMES=$(az monitor log-analytics workspace list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query "[].name" -o tsv 2>/dev/null || echo "")

if [ -n "$WORKSPACE_NAMES" ]; then
    while IFS= read -r WS_NAME; do
        echo "  - $WS_NAME を削除..."
        az monitor log-analytics workspace delete \
            --resource-group "$RESOURCE_GROUP_NAME" \
            --workspace-name "$WS_NAME" \
            --force true --yes --output none
    done <<< "$WORKSPACE_NAMES"
else
    echo "  対象なし"
fi

# リソースグループ削除（非同期）
echo ""
echo "=== リソースグループを削除 ==="
az group delete --name "$RESOURCE_GROUP_NAME" --yes --no-wait

echo ""
echo "削除リクエストを送信しました（非同期実行中）。"
echo "完了確認: az group exists --name $RESOURCE_GROUP_NAME"
