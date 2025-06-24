# file: handlers/base.py
# description: Abstract base class for LLM handlers
# version: 0.1.0
# last updated: 2025-06-24

from abc import ABC, abstractmethod

class AbstractLLMHandler(ABC):
    @abstractmethod
    def chat_completion(self, request):
        pass

    @abstractmethod
    def completion(self, request):
        pass

    @abstractmethod
    def embeddings(self, request):
        pass
