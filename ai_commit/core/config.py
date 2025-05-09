import os
from typing import Dict, Any, Optional

class Config:
    """ config manager for api keys and validation """

    def __init__(self):
        self.api_key = os.environ.get("AI_API_KEY", "")
        self.api_url = os.environ.get("AI_API_URL", "")
        self.common_models = ["llama2", "llama3", "llama-coder", "vicuna"]

    def validate_api_credentials(self) -> bool:
        return self.api_key and self.api_url

    def get_api_credentials(self) -> Dict[str, str]:
        return {
            "url": self.api_url,
            "key": self.api_key
        }


config = Config()