#!/usr/bin/env bash
# Configure git for work repos - reads from SSH key, no hardcoded values

work_key="$HOME/.ssh/id_ed25519_work.pub"

if [ ! -f "$work_key" ]; then
  echo "Error: Work SSH key not found at $work_key"
  exit 1
fi

# Extract email from SSH key comment (3rd field)
work_email=$(awk '{print $3}' "$work_key")

# Extract username from email
# GitHub noreply format: "ID+username@users.noreply.github.com" → extract after +
# Regular email: "name@domain.com" → extract before @
case "$work_email" in
  *+*@users.noreply.github.com)
    work_user=$(echo "$work_email" | sed 's/.*+\(.*\)@.*/\1/')
    ;;
  *)
    work_user=$(echo "$work_email" | cut -d@ -f1)
    ;;
esac

echo "Setting up git for work:"
echo "  user.name: $work_user"
echo "  user.email: $work_email"

git config user.name "$work_user"
git config user.email "$work_email"
git config gpg.format ssh
git config user.signingkey "$work_key"
git config commit.gpgsign true
