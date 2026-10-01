"""Small utilities under scripts/utils, fed canned input (no cluster access)."""

import json

from test_rollback import REPO, Sandbox


class ViewSecretsTests(Sandbox):
    def setUp(self):
        super().setUp()
        # The script only reads stdin; fail loudly if it ever calls kubectl.
        self.mock("kubectl", "echo 'unexpected kubectl call' >&2; exit 1\n")

    def view(self, secret):
        return self.command(
            ["/bin/bash", str(REPO / "scripts/utils/view-secrets")],
            input=json.dumps(secret),
        )

    def test_decodes_secret_data(self):
        result = self.view({"kind": "Secret", "data": {"user": "YWRtaW4="}})
        self.assertEqual(json.loads(result.stdout), {"user": "admin"})

    def test_secret_without_data_prints_no_values(self):
        result = self.view({"kind": "Secret", "metadata": {"name": "empty"}})
        self.assertEqual(json.loads(result.stdout), {})
        self.assertEqual(result.stderr, "")
