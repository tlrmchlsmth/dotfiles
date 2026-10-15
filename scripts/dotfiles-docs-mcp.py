#!/usr/bin/env python3
"""Read-only local documentation for this dotfiles repository and local AI."""
import importlib.util
import sys
sys.dont_write_bytecode = True
import json
from pathlib import Path
import urllib.request

from mcp.server.mcpserver import MCPServer
from mcp.server.mcpserver.exceptions import ToolError
from mcp.types import ToolAnnotations

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('local_ai_service', ROOT / 'scripts/local-ai.py')
service = importlib.util.module_from_spec(spec)
spec.loader.exec_module(service)
server = MCPServer('dotfiles-docs', instructions='Local, read-only dotfiles and inference documentation. No external requests or service mutations.')
READ_ONLY = ToolAnnotations(read_only_hint=True, destructive_hint=False, open_world_hint=False)


def documents():
    # An explicit allowlist avoids exposing credentials, overrides, or arbitrary files.
    return {
        'dotfiles-readme': ROOT / 'README.md',
        'dotfiles-guidance': ROOT / 'CLAUDE.md',
        'local-ai-defaults': ROOT / 'config/local-ai.json',
        'local-ai-commands': ROOT / 'scripts/local-ai.py',
        'local-ai-installation': ROOT / 'scripts/install-local-ai.sh',
    }


@server.tool(annotations=READ_ONLY)
def list_docs() -> dict:
    """List the available local documentation and configuration documents."""
    return {'documents': [{'name': name, 'uri': f'dotfiles://docs/{name}'} for name in documents()]}


@server.tool(annotations=READ_ONLY)
def read_doc(name: str) -> str:
    """Read an allowlisted dotfiles or local AI document by its list_docs name."""
    sources = documents()
    if name not in sources:
        raise ToolError('Unknown document; use list_docs')
    path = sources[name].resolve()
    if not path.is_relative_to(ROOT):
        raise ToolError('Document points outside the dotfiles repository')
    return path.read_text()


@server.resource('dotfiles://docs/{name}', mime_type='text/plain')
def document_resource(name: str) -> str:
    return read_doc(name)


@server.tool(annotations=READ_ONLY)
def search_docs(query: str) -> dict:
    """Search local documentation by literal text, returning up to 30 line matches."""
    if not query.strip():
        raise ToolError('Provide a nonempty query')
    matches = []
    for name in documents():
        for number, line in enumerate(read_doc(name).splitlines(), 1):
            if query.casefold() in line.casefold():
                matches.append({'document': name, 'line': number, 'text': line})
                if len(matches) == 30:
                    return {'matches': matches, 'truncated': True}
    return {'matches': matches, 'truncated': False}


@server.tool(annotations=READ_ONLY)
def local_ai_status() -> dict:
    """Report public local AI settings and health; probes only IPv4 loopback."""
    cfg = service.settings()
    port = int(cfg['port'])
    if not 1 <= port <= 65535:
        raise ToolError('Invalid local port')
    result = {k: cfg[k] for k in ['model', 'revision', 'alias', 'hostname', 'port', 'context_length', 'max_num_seqs']}
    result['numeric_api_url'] = f'http://127.0.0.1:{port}/v1'
    result['named_api_url'] = f"http://{cfg['hostname']}:{port}/v1"
    # Disable environment proxies and redirects so the probe stays on loopback.
    class NoRedirect(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, *args, **kwargs):
            return None
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), NoRedirect())
    try:
        with opener.open(f'http://127.0.0.1:{port}/health', timeout=3) as response:
            result['healthy'] = response.status == 200
    except OSError:
        result['healthy'] = False
    return result


if __name__ == '__main__':
    server.run(transport='stdio')
