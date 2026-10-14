import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]


class GitIdentityTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.home = Path(self.directory.name)
        self.env = {
            key: value
            for key, value in os.environ.items()
            if not key.startswith("GIT_")
        }
        self.env.update(HOME=str(self.home), GIT_CONFIG_NOSYSTEM="1")
        shutil.copy(ROOT / ".gitconfig", self.home / ".gitconfig")
        shutil.copytree(ROOT / ".config/git", self.home / ".config/git")

    def git(self, *args):
        return subprocess.check_output(
            ["git", *map(str, args)], env=self.env, text=True
        ).strip()

    def assert_identity(self, repo, account, email, key):
        expected = {
            "user.name": account,
            "user.email": email,
            "user.signingkey": f"~/.ssh/{key}.pub",
            "github.user": account,
            "gpg.format": "ssh",
            "commit.gpgsign": "true",
            "tag.gpgsign": "true",
            "core.sshCommand": f"ssh -F ~/.config/git/ssh-{'work' if account == 'hanselse' else 'personal'}",
        }
        for setting, value in expected.items():
            with self.subTest(repo=repo, setting=setting):
                self.assertEqual(
                    self.git("-C", repo, "config", "--get", setting), value
                )

    def test_folder_identity_for_regular_bare_and_linked_repositories(self):
        for folder, account, email, key in [
            ("g", "handshou", "handshou@users.noreply.github.com", "id_ed25519"),
            (
                "Developer",
                "hanselse",
                "190053598+hanselse@users.noreply.github.com",
                "id_ed25519_work",
            ),
        ]:
            regular = self.home / folder / "regular"
            self.git("init", "-q", regular)
            self.assert_identity(regular, account, email, key)
            canonical = self.home / folder / "canonical"
            bare = canonical / ".bare"
            self.git("init", "-q", "--bare", bare)
            (canonical / ".git").write_text("gitdir: ./.bare\n")
            linked = canonical / "main"
            self.git("-C", canonical, "worktree", "add", "--orphan", "-q", linked)
            self.git(
                "-C",
                linked,
                "-c",
                "commit.gpgsign=false",
                "commit",
                "--allow-empty",
                "-m",
                "seed",
            )
            for repo in [canonical, bare, linked]:
                self.assert_identity(repo, account, email, key)

    def test_home_dotfiles_repository_is_personal(self):
        self.git("init", "-q", "--bare", self.home / ".cfg")
        self.assert_identity(
            self.home / ".cfg",
            "handshou",
            "handshou@users.noreply.github.com",
            "id_ed25519",
        )

    def test_config_alias_with_explicit_git_directory(self):
        self.git("init", "-q", "--bare", self.home / ".cfg")
        for suffix in ["", "/"]:
            self.assertEqual(
                self.git(
                    f"--git-dir={self.home}/.cfg{suffix}",
                    f"--work-tree={self.home}",
                    "config",
                    "--get",
                    "core.sshCommand",
                ),
                "ssh -F ~/.config/git/ssh-personal",
            )

    def test_unmapped_directory_keeps_existing_defaults(self):
        repo = self.home / "Developer-other" / "repo"
        self.git("init", "-q", repo)
        self.assertEqual(
            self.git("-C", repo, "config", "--get", "user.name"), "handshou"
        )
        result = subprocess.run(
            ["git", "-C", str(repo), "config", "--get", "core.sshCommand"],
            env=self.env,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 1)

    def test_repository_overrides_win(self):
        repo = self.home / "Developer" / "override"
        self.git("init", "-q", repo)
        overrides = {
            "user.name": "custom-author",
            "user.email": "custom@example.test",
            "user.signingkey": "custom.pub",
            "core.sshCommand": "ssh -i custom",
            "commit.gpgsign": "false",
            "tag.gpgsign": "false",
        }
        for setting, value in overrides.items():
            self.git("-C", repo, "config", "--local", setting, value)
            self.assertEqual(self.git("-C", repo, "config", "--get", setting), value)

    def test_github_ssh_aliases_offer_only_selected_identity(self):
        for profile, key in [("personal", "id_ed25519"), ("work", "id_ed25519_work")]:
            for host in [
                "github.com",
                "work.github.com",
                "github-public",
                "github-personal",
            ]:
                output = subprocess.check_output(
                    ["ssh", "-G", "-F", str(ROOT / f".config/git/ssh-{profile}"), host],
                    text=True,
                    stderr=subprocess.DEVNULL,
                )
                settings = output.splitlines()
                self.assertIn("hostname github.com", settings)
                self.assertIn("user git", settings)
                self.assertIn("identitiesonly yes", settings)
                self.assertEqual(
                    [line for line in settings if line.startswith("identityfile ")],
                    [f"identityfile ~/.ssh/{key}"],
                )

    def test_non_github_ssh_configuration_is_preserved(self):
        def settings(*args):
            output = subprocess.check_output(
                ["ssh", "-G", *args, "example.test"],
                text=True,
                stderr=subprocess.DEVNULL,
            )
            return output.splitlines()

        for profile in ["personal", "work"]:
            self.assertEqual(
                settings(),
                settings("-F", str(ROOT / f".config/git/ssh-{profile}")),
            )


if __name__ == "__main__":
    unittest.main()
