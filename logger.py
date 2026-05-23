import logging
import os
import sys

from azure.identity import DefaultAzureCredential
from azure.monitor.opentelemetry import configure_azure_monitor
from dotenv import load_dotenv
from opentelemetry.sdk.resources import SERVICE_NAME, Resource

load_dotenv()

_SERVICE_NAME = os.getenv("LOG_SERVICE_NAME", "python-app-baseline")
_LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
_TO_STDOUT = os.getenv("LOG_TO_STDOUT", "true").lower() == "true"
_TO_APPINSIGHTS = os.getenv("LOG_TO_APPINSIGHTS", "false").lower() == "true"
_CONNECTION_STRING = os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")

# 二重出力を避けるためルートロガーへの伝播は切る
_logger = logging.getLogger(_SERVICE_NAME)
_logger.setLevel(_LOG_LEVEL)
_logger.propagate = False

if _TO_STDOUT:
    _handler = logging.StreamHandler()
    _handler.setFormatter(
        logging.Formatter("%(asctime)s [%(levelname)s] %(name)s - %(message)s")
    )
    _logger.addHandler(_handler)

if _TO_APPINSIGHTS:
    if _CONNECTION_STRING:
        configure_azure_monitor(
            connection_string=_CONNECTION_STRING,
            credential=DefaultAzureCredential(),
            logger_name=_SERVICE_NAME,
            resource=Resource.create({SERVICE_NAME: _SERVICE_NAME}),
        )
    else:
        _logger.warning(
            "LOG_TO_APPINSIGHTS=true ですが APPLICATIONINSIGHTS_CONNECTION_STRING が"
            "未設定のため、Application Insights への送信はスキップします。"
        )


def applog(message, *args, level="INFO", **kwargs):
    """
    print の代替として使うログ関数。level は "INFO" / "WARNING" / "ERROR" など。
    例外情報を自動で付与するため、try/except 内で呼び出すとスタックトレースも送信される。
    """
    # try/except 内で呼ばれた場合は自動でスタックトレースを付与
    if "exc_info" not in kwargs and sys.exc_info()[0] is not None:
        kwargs["exc_info"] = True
    getattr(_logger, level.lower())(message, *args, **kwargs)
