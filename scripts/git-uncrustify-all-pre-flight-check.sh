# To install me from the source root:
#
#     ln -s ../../scripts/uncrustify/pre-commit.sh .git/hooks/pre-commit

SCRIPTS_ROOT="./scripts"
if ! $SCRIPTS_ROOT/uncrustify_all.sh; then
  echo "There were sources that uncrustify modified. Check the git diff and commit any modified sources." 1>&2
  exit 1
fi
