#!/usr/bin/env python3
"""Manage an explicitly local, offline inference service on macOS."""
import argparse
import json
import os
from pathlib import Path
import platform
import plistlib
import pwd
import re
import shutil
import subprocess
import sys
import urllib.request

REPO = Path(__file__).resolve().parents[1]
LABEL = 'com.tysmith.local-ai'


def settings(*, invoking_user=False):
    cfg = json.loads((REPO / 'config/local-ai.json').read_text())
    user_home = Path.home()
    if invoking_user and os.geteuid() == 0 and 'SUDO_UID' in os.environ:
        user_home = Path(pwd.getpwuid(int(os.environ['SUDO_UID'])).pw_dir)
    override = user_home / '.config/local-ai.local.json'
    if override.exists():
        cfg.update(json.loads(override.read_text()))
    return cfg


def home(cfg):
    return Path(cfg.get('home', '~/.local/share/local-ai')).expanduser().resolve()


def snapshot(cfg):
    return home(cfg) / 'cache/huggingface/hub' / ('models--' + cfg['model'].replace('/', '--')) / 'snapshots' / cfg['revision']


def server_command(cfg):
    return [str(home(cfg) / '.venv/bin/vllm'), 'serve', str(snapshot(cfg)),
            '--host', '127.0.0.1', '--port', str(cfg['port']),
            '--served-model-name', cfg['alias'], '--language-model-only',
            '--max-model-len', str(cfg['context_length']),
            '--max-num-seqs', str(cfg['max_num_seqs']),
            '--max-num-batched-tokens', str(cfg['max_num_batched_tokens']),
            '--gpu-memory-utilization', str(cfg['gpu_memory_utilization']),
            '--enable-auto-tool-choice', '--tool-call-parser', cfg['tool_call_parser'],
            '--reasoning-parser', cfg['reasoning_parser']]


def run_launchctl(*args, check=True):
    return subprocess.run(['/bin/launchctl', *args], text=True, capture_output=True, check=check)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['install', 'serve', 'start', 'stop', 'restart', 'status', 'url', 'home', 'hosts'])
    args = parser.parse_args()
    cfg = settings(invoking_user=args.action == 'hosts')
    root = home(cfg)
    url = f"http://{cfg['hostname']}:{cfg['port']}/v1"
    if args.action == 'home':
        print(root)
        return
    if args.action == 'url':
        print(url)
        return
    if args.action == 'hosts':
        if os.geteuid() != 0:
            raise SystemExit('Run the hosts action with sudo; it appends only the localhost alias.')
        hostname = cfg['hostname']
        if not re.fullmatch(r'[a-zA-Z0-9.-]+', hostname):
            raise SystemExit('Invalid hostname')
        path = Path('/etc/hosts')
        text = path.read_text()
        for line in text.splitlines():
            fields = line.split('#', 1)[0].split()
            if hostname in fields[1:]:
                if fields[0] != '127.0.0.1':
                    raise SystemExit('Hostname already maps elsewhere; hosts file unchanged')
                print('Localhost alias already installed')
                return
        with path.open('a') as f:
            f.write(('' if text.endswith('\n') else '\n') + f'\n# Local inference service\n127.0.0.1 {hostname}\n')
        print('Installed localhost alias:', hostname)
        return
    if platform.system() != 'Darwin' or platform.machine() != 'arm64':
        raise SystemExit('This service requires Apple Silicon macOS')
    agent = Path.home() / 'Library/LaunchAgents' / (LABEL + '.plist')
    domain = f'gui/{os.getuid()}'
    target = domain + '/' + LABEL
    if args.action == 'install':
        if not Path(server_command(cfg)[0]).is_file() or not snapshot(cfg).is_dir():
            raise SystemExit('Run scripts/install-local-ai.sh to install the environment and model first')
        logs = root / 'artifacts'
        logs.mkdir(parents=True, exist_ok=True)
        agent.parent.mkdir(parents=True, exist_ok=True)
        data = {'Label': LABEL,
                'ProgramArguments': [shutil.which('python3') or sys.executable, str(Path(__file__).resolve()), 'serve'],
                'WorkingDirectory': str(root), 'RunAtLoad': True, 'KeepAlive': True,
                'ThrottleInterval': 30, 'ProcessType': 'Interactive',
                'LimitLoadToSessionType': 'Aqua',
                'StandardOutPath': str(logs / 'launchd.log'),
                'StandardErrorPath': str(logs / 'launchd.log')}
        with agent.open('wb') as f:
            plistlib.dump(data, f)
        agent.chmod(0o644)
        print('Installed login agent:', agent)
        return
    if args.action == 'serve':
        if not snapshot(cfg).is_dir():
            raise SystemExit('Pinned model cache is missing; run scripts/install-local-ai.sh')
        env = dict(os.environ, HF_HOME=str(root / 'cache/huggingface'),
                   VLLM_CACHE_ROOT=str(root / 'cache/vllm'), XDG_CACHE_HOME=str(root / 'cache'),
                   HF_HUB_OFFLINE='1', TRANSFORMERS_OFFLINE='1',
                   VLLM_METAL_MEMORY_FRACTION='auto', VLLM_NO_USAGE_STATS='1',
                   DO_NOT_TRACK='1', PATH='/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin')
        command = server_command(cfg)
        os.chdir(root)
        os.execve(command[0], command, env)
        return
    if args.action == 'status':
        result = run_launchctl('print', target, check=False)
        if result.returncode:
            print('Stopped (starts automatically at next login)')
            return
        pid = re.search(r'^\s*pid = (\d+)', result.stdout, re.MULTILINE)
        print(f"Loaded: PID {pid.group(1) if pid else 'pending'}, {url}")
        try:
            with urllib.request.urlopen(f"http://127.0.0.1:{cfg['port']}/health", timeout=3) as r:
                print('API healthy' if r.status == 200 else 'API not ready')
        except OSError:
            print('API starting or unavailable; see artifacts/launchd.log')
        return
    if args.action in ('stop', 'restart'):
        result = run_launchctl('bootout', target, check=False)
        if result.returncode and run_launchctl('print', target, check=False).returncode == 0:
            raise SystemExit(result.stderr)
        if args.action == 'stop':
            print('Stopped until next login or local-ai start')
            return
    if not agent.exists():
        raise SystemExit('Run local-ai install first')
    if run_launchctl('print', target, check=False).returncode == 0:
        print('Already loaded:', url)
        return
    run_launchctl('enable', target)
    run_launchctl('bootstrap', domain, str(agent))
    print('Starting:', url)


if __name__ == '__main__':
    main()
