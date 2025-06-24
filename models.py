# file: models.py
# description: Pydantic models for MCP request/response
# version: 0.1.0
# last updated: 2025-06-24

from pydantic import BaseModel
from typing import Any, Dict

class MCPRequest(BaseModel):
    # Define fields as needed for your MCP spec
    input: str
    parameters: Dict[str, Any] = {}

class MCPResponse(BaseModel):
    # Define fields as needed for your MCP spec
    result: Any
    usage: Dict[str, Any] = {}
