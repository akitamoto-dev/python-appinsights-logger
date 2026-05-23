# Python アプリログを Application Insights に送信するサンプル

Python アプリケーションのログを Entra ID 認証で Application Insights に送信するためのサンプルコードとインフラ一式

## 構成

```
python-appinsights-logger/
├── .env.example          # 環境変数テンプレート
├── logger.py             # 標準出力 + Application Insights へ送るロガー
├── main.py               # 動作確認用のサンプル
├── requirements.txt      # Python 依存関係
└── infra/
    ├── deploy.sh         # リソース作成
    ├── destroy.sh        # リソース削除
    ├── main.bicep        # リソースグループスコープの Bicep テンプレート
    └── main.bicepparam   # Bicep 用パラメータ
```

## デプロイされるリソース

- Log Analytics Workspace（PerGB2018、保持 30 日）
- Application Insights（ワークスペースベース、`DisableLocalAuth=true`）
- 実行ユーザーへの「Monitoring Metrics Publisher」ロール割当（Application Insights スコープ）

## 前提

- Azure CLI でログイン済み（`az login` / `az account set -s <id>`）
- Python 3.10 以上

## デプロイ

```bash
bash infra/deploy.sh
```

完了時に Application Insights の接続文字列が表示される。リソースグループ名やリージョンを変更したい場合は [`infra/deploy.sh`](infra/deploy.sh) 冒頭のユーザー調整パラメータを編集する。

## アプリ実行

1. `.env.example` を `.env` にコピーして、接続文字列を貼り付け、`LOG_TO_APPINSIGHTS=true` に設定する

    ```bash
    cp .env.example .env
    ```

2. 依存関係をインストール

    ```bash
    pip install -r requirements.txt
    ```

3. 実行

    ```bash
    python main.py
    ```

標準出力にログが出るとともに、数十秒〜2 分程度で Application Insights に反映される。


## 削除

```bash
bash infra/destroy.sh
```

Log Analytics Workspace のソフトデリートまでパージしたうえで、リソースグループを削除する。

## 環境変数

| 変数 | 説明 |
|---|---|
| `LOG_TO_STDOUT` | 標準出力に出力するか（`true`/`false`） |
| `LOG_TO_APPINSIGHTS` | Application Insights に送信するか（`true`/`false`） |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | 送信先の接続文字列 |
| `LOG_SERVICE_NAME` | Application Insights 上の `AppRoleName` として表示される識別名 |
| `LOG_LEVEL` | 出力レベル閾値（`DEBUG`/`INFO`/`WARNING`/`ERROR`/`CRITICAL`） |

