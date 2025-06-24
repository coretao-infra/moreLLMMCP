# file: mcp_sse/__init__.py
# description: MCP SSE endpoint for Azure Function App
# version: 0.1.0
# last updated: 2025-06-24

import azure.functions as func
import logging
from registry import registry
from models import MCPRequest, MCPResponse
import json

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Received request at MCP SSE endpoint.")
    try:
        data = req.get_json()
        mcp_request = MCPRequest(**data)
    except Exception as e:
        logging.error(f"Invalid request: {e}")
        return func.HttpResponse("Invalid request body", status_code=400)

    handler = registry.resolve_handler(req)
    result = handler.chat_completion(mcp_request)
    response = MCPResponse(result=result)
    return func.HttpResponse(
        response.json(),
        status_code=200,
        mimetype="application/json"
    )
