// main.bicep 用パラメータファイル。

using './main.bicep'

// ロール付与先プリンシパル ID
// deploy.sh で az ad signed-in-user show で取得・環境変数化され、間接的にBicep側で取得
param principalId = readEnvironmentVariable('PRINCIPAL_ID', '')


