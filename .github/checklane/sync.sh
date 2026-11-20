#!/usr/bin/env bash
# Builds the next commit of a branch of this fork from an upstream ref of
# shivammathur/setup-php: upstream's tree with Checklane runners allowed to
# opt in to the builds cache, and the fork notice at the top of the README.
#
#   .github/checklane/sync.sh <upstream ref> <branch>
#
# Prints the new commit when the branch would change, nothing when it would
# not. The commit's parent is the branch as it is on origin, so pushing it is
# a fast-forward, and upstream's history (with its workflow changes, which the
# workflow's token may not push) stays out of it.
#
# Upstream's workflows are left out: main keeps this fork's own .github/workflows
# and .github/checklane from the commit this script runs from, every other
# branch has no workflows at all.
set -euo pipefail

upstream_ref=$1
branch=$2
self=$(git rev-parse HEAD)
upstream=$(git rev-parse "$upstream_ref^{commit}")
current=$(git rev-parse -q --verify "refs/remotes/origin/$branch^{commit}" || true)

GIT_INDEX_FILE=$(mktemp -u)
export GIT_INDEX_FILE
trap 'rm -f "$GIT_INDEX_FILE"' EXIT

git read-tree "$upstream"
git rm -r -q --cached --ignore-unmatch .github/workflows .github/dependabot.yml
if [[ $branch = main ]]; then
  git read-tree --prefix=.github/workflows/ "$self:.github/workflows"
  git read-tree --prefix=.github/checklane/ "$self:.github/checklane"
fi

replace() {
  local path=$1 content=$2 mode
  mode=$(git ls-files -s -- "$path" | cut -d' ' -f1)
  git update-index --cacheinfo "$mode,$(git hash-object -w --stdin <<<"$content"),$path"
}

# The change upstream declined until more people ask for it: checklane joins
# the runner name prefixes that may use the builds cache.
unix=src/scripts/unix.sh
script=$(git show "$upstream:$unix")
if ! grep -q 'checklane' <<<"$script"; then
  script=$(sed -E 's/\^\((blacksmith\|depot[^)]*)\)-/^(\1|checklane)-/g' <<<"$script")
  if [[ $(grep -c '|checklane)-' <<<"$script") != 2 ]]; then
    echo "$unix in $upstream_ref changed shape: the checklane prefix did not go in twice" >&2
    exit 1
  fi
  bash -n <<<"$script"
  replace "$unix" "$script"
fi

replace README.md "$(git show "$self:.github/checklane/notice.md")

$(git show "$upstream:README.md")"

tree=$(git write-tree)
if [[ -n $current && $tree = $(git rev-parse "$current^{tree}") ]]; then
  exit 0
fi

git commit-tree "$tree" ${current:+-p "$current"} \
  -m "chore: sync $branch with shivammathur/setup-php@${upstream:0:7}" \
  -m "Upstream: https://github.com/shivammathur/setup-php/commit/$upstream"
