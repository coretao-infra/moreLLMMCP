# file: registry.py
# description: Handler registry and resolver
# version: 0.1.0
# last updated: 2025-06-24

from handlers.azure_oai import AzureOpenAIHandler

class HandlerRegistry:
    def __init__(self):
        self._handlers = {
            'azure': AzureOpenAIHandler(),
            # Add other providers here
        }

    def resolve_handler(self, request):
        # For now, always return AzureOpenAIHandler
        # In the future, inspect request for provider selection
        return self._handlers['azure']

registry = HandlerRegistry()
