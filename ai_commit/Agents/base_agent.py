from abc import ABC, abstractmethod
from typing import Dict, Any, Optional

# we will create an abstract class for the base agent. any agent should inherit from this

class BaseAgent(ABC):
    @abstractmethod
    def run(self, **kwargs)-> None:
        """run the agent with the provided arguments"""

        pass
    