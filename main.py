from __future__ import annotations

from logger import applog


def main() -> None:
    applog("アプリ開始")
    applog("これは警告レベルの動作確認です", level="WARNING")
    applog("これはエラーレベルの動作確認です（例外なし）", level="ERROR")

    # try/except 内の applog 呼び出しは自動でスタックトレース付きになる
    try:
        raise RuntimeError("意図的に発生させた例外")
    except RuntimeError:
        applog("例外をキャッチしたので記録します", level="ERROR")

    applog("アプリ終了")


if __name__ == "__main__":
    main()
