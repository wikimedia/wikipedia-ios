# Install the git pre-commit hook
if [[ -z "./.git" ]]; then
  echo "No git directory detected."
  exit 2
fi

echo "Installing the git pre-commit hook"
GIT_PRECOMMIT_HOOK_INSTALL_PATH="./.git/hooks/pre-commit"
GIT_PRECOMMIT_HOOK_SCRIPT_PATH="./scripts/pre-commit.sh"
GIT_PRECOMMIT_HOOK_SCRIPT_PATH_REL_HOOKS="../../$GIT_PRECOMMIT_HOOK_SCRIPT_PATH"

if [[ -L "$GIT_PRECOMMIT_HOOK_INSTALL_PATH" ]]; then
  echo "Backed up previous commit-hook"
  mv -f "$GIT_PRECOMMIT_HOOK_INSTALL_PATH" "${GIT_PRECOMMIT_HOOK_INSTALL_PATH}.bak"
fi

ln -s "$GIT_PRECOMMIT_HOOK_SCRIPT_PATH_REL_HOOKS" "$GIT_PRECOMMIT_HOOK_INSTALL_PATH"
echo "Installed pre-commit hook at $GIT_PRECOMMIT_HOOK_INSTALL_PATH"
