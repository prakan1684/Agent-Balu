import os

from urllib3 import response 
import ollama
import requests
import json
from typing import Dict, Any, Optional, Literal, override


class LLMProvider:
    """
    This is the base class for llm provider (ollama and openai for noiw)
    """

    def generate_response(self, prompt: str, context: str, **kwargs) -> str:
        #generate  a response from llms
        raise NotImplementedError("Subclasses must implement this method")

class LocalLLMProvider(LLMProvider):
    """
    provider for local llm models using ollama

    """

    def __init__(self, model_name:str):
        self.model_name = model_name


    def generate_response(self, prompt: str, context: str, **kwargs) -> str:
        try:
            print(f"Using local model: {self.model_name}")
            print("Generating response from Ollama...")
            
            # Format the prompt properly for the model
            formatted_prompt = f"{prompt}\n\nHere are the changes:\n\n{context}"
            
            # Set streaming to False to get the full response at once
            response = ollama.generate(
                model=self.model_name,
                prompt=formatted_prompt,
                options={
                    "temperature": 0.7,
                    "top_p": 0.9,
                    "stream": False,
                    **kwargs.get("options", {})
                }
            )
            
            # Debug the response
            if not response or "response" not in response:
                print("❌ Error: Empty response from Ollama")
                print(f"Response data: {response}")
                return "Failed to generate commit message"
                
            result = response.get("response", "")
            print(f"Response generated successfully ({len(result)} characters)")
            return result
        except Exception as e:
            print(f"❌ Error generating response from local model: {e}")
            import traceback
            traceback.print_exc()
            return "Failed to generate commit message due to an error"

class RemoteLLMProvider(LLMProvider):
    """Provider for remote API-based LLM models"""
    def __init__(self):
        self.api_url = os.environ.get("AI_API_URL", "")
        self.api_key = os.environ.get("AI_API_KEY", "")
        # Default model to use with OpenAI
        self.default_model = "gpt-3.5-turbo"

    def validate_credentials(self) -> bool:
        """Check if API credentials are valid"""
        if not self.api_url:
            print("❌ Error: AI_API_URL environment variable is not set.")
            print("Please set it using: export AI_API_URL='your-api-url'")
            return False
        
        if not self.api_key:
            print("❌ Error: AI_API_KEY environment variable is not set.")
            print("Please set it using: export AI_API_KEY='your-api-key'")
            return False
            
        return True
        
    def generate_response(self, prompt: str, context: str, **kwargs) -> str:
        """Generate a response using a remote LLM API"""

        if not self.validate_credentials():
            return ""

        try:
            if not self.api_url.startswith(("http://", "https://")):
                self.api_url = f"https://{self.api_url}"
                
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.api_key}"
            }
            
            # Check if this is OpenAI API
            is_openai = "openai.com" in self.api_url
            
            if is_openai:
                # Format for OpenAI API
                data = {
                    "model": kwargs.get("model", self.default_model),
                    "messages": [
                        {"role": "system", "content": prompt},
                        {"role": "user", "content": context}
                    ],
                    "temperature": kwargs.get("temperature", 0.7),
                    "max_tokens": kwargs.get("max_tokens", 500)
                }
                print(f"Using OpenAI model: {data['model']}")
            else:
                # Generic API format
                data = {
                    "prompt": prompt,
                    "context": context,
                    **kwargs
                }
            
            response = requests.post(
                self.api_url,
                headers=headers,
                data=json.dumps(data)
            )
            
            if response.status_code == 200:
                response_json = response.json()
                if is_openai:
                    # Extract content from OpenAI response format
                    try:
                        return response_json["choices"][0]["message"]["content"]
                    except (KeyError, IndexError) as e:
                        print(f"❌ Error parsing OpenAI response: {e}")
                        print(f"Response: {response_json}")
                        return ""
                else:
                    return response_json.get("response", "")
            else:
                print(f"❌ Error: API returned status code {response.status_code}")
                if response.text:
                    print(f"Response: {response.text}")
                return ""
        except requests.exceptions.RequestException as e:
            print(f"❌ Error connecting to API: {e}")
            return ""
        except Exception as e:
            print(f"❌ Error generating response from remote API: {e}")
            import traceback
            traceback.print_exc()
            return ""
            
def get_llm_provider(use_local: bool = False, model_name: str= "") -> LLMProvider:
    if use_local and model_name:
        return LocalLLMProvider(model_name)
    return RemoteLLMProvider()

def generate_response(prompt: str, context:str, use_local: bool = False, model_name:str = "", **kwargs) -> str:
    provider = get_llm_provider(use_local, model_name)
    return provider.generate_response(prompt, context, **kwargs)