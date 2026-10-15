import importlib.util
import sys
sys.dont_write_bytecode = True
import json
import os
from pathlib import Path
import plistlib
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('local_ai', Path(__file__).resolve().parents[1] / 'scripts/local-ai.py')
service = importlib.util.module_from_spec(spec)
spec.loader.exec_module(service)


class LocalAITests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.cfg = service.settings()
        self.cfg['home'] = str(self.root / 'runtime')
        executable = service.home(self.cfg) / '.venv/bin/vllm'
        executable.parent.mkdir(parents=True)
        executable.touch()
        service.snapshot(self.cfg).mkdir(parents=True)

    def invoke(self, action):
        with patch.object(service, 'settings', return_value=self.cfg), patch.object(service.platform, 'system', return_value='Darwin'), patch.object(service.platform, 'machine', return_value='arm64'), patch('sys.argv', ['local-ai', action]):
            service.main()

    def test_loopback_and_pinned_local_weights(self):
        cmd = service.server_command(self.cfg)
        self.assertEqual(cmd[2], str(service.snapshot(self.cfg)))
        self.assertEqual(cmd[cmd.index('--host') + 1], '127.0.0.1')
        self.assertEqual(cmd[cmd.index('--max-num-seqs') + 1], '4')
        self.assertEqual(cmd[cmd.index('--max-model-len') + 1], '262144')

    def test_login_agent(self):
        with patch.object(service.Path, 'home', return_value=self.root):
            self.invoke('install')
        path = self.root / 'Library/LaunchAgents/com.tysmith.local-ai.plist'
        data = plistlib.loads(path.read_bytes())
        self.assertTrue(data['RunAtLoad'])
        self.assertTrue(data['KeepAlive'])
        self.assertEqual(data['ThrottleInterval'], 30)
        self.assertEqual(data['ProgramArguments'][-1], 'serve')

    def test_inference_starts_offline(self):
        with patch.object(service.os, 'execve') as execute, patch.object(service.os, 'chdir'):
            self.invoke('serve')
        env = execute.call_args.args[2]
        self.assertEqual(env['HF_HUB_OFFLINE'], '1')
        self.assertEqual(env['TRANSFORMERS_OFFLINE'], '1')
        self.assertEqual(env['VLLM_NO_USAGE_STATS'], '1')

    def test_missing_model_never_downloads_in_serve(self):
        self.cfg['revision'] = 'not-installed'
        with patch.object(service.os, 'execve') as execute, self.assertRaises(SystemExit):
            self.invoke('serve')
        execute.assert_not_called()


if __name__ == '__main__':
    unittest.main()
