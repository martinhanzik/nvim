#!/usr/bin/env bash
# Install a private Node runtime for Mason's npm-backed language servers
# (bashls, yamlls, dockerls) on hosts that have no system node.
#
# Everything lands inside Neovim's data dir - no system packages, no writes to
# $HOME outside the nvim dirs, nothing added to your shell PATH (init.lua picks
# it up on its own). Uninstall with: rm -rf "$(nvim --headless -c 'echo stdpath("data")' -c q 2>&1)/node"
#
# Usage: ./install-node.sh [node-major-version]   (default: 22)
#
# The target is Neovim's data dir, resolved from NVIM_APPNAME + $XDG_DATA_HOME.
# If this host uses a non-default appname, either export NVIM_APPNAME first or
# override the whole thing with NVIM_DATA=<path from `:echo stdpath('data')`>.

set -euo pipefail

major="${1:-22}"

data_dir="${NVIM_DATA:-$(NVIM_APPNAME="${NVIM_APPNAME:-nvim/kickstart}" nvim --clean --headless -c 'echo stdpath("data")' -c 'q' 2>&1 | tr -d '\r\n')}"
[ -n "$data_dir" ] || { echo "could not determine nvim's data dir" >&2; exit 1; }
dest="$data_dir/node"

case "$(uname -s)" in
  Linux) os=linux ;;
  Darwin) os=darwin ;;
  *) echo "unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

case "$(uname -m)" in
  x86_64 | amd64) arch=x64 ;;
  aarch64 | arm64) arch=arm64 ;;
  *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;;
esac

if command -v xz >/dev/null 2>&1; then
  ext=tar.xz
  decompress="xz -dc"
else
  ext=tar.gz
  decompress="gzip -dc"
fi

base="https://nodejs.org/dist/latest-v${major}.x"
file=$(curl -fsSL "$base/" | grep -o "node-v[0-9.]*-$os-$arch\.$ext" | head -1)
[ -n "$file" ] || { echo "no node build for $os-$arch at $base" >&2; exit 1; }

echo "installing $file -> $dest"
rm -rf "$dest"
mkdir -p "$dest"
# Decompress explicitly - older GNU tar won't auto-detect compression on a pipe
curl -fsSL "$base/$file" | $decompress | tar -x -C "$dest" --strip-components=1

"$dest/bin/node" --version
echo "done - restart nvim and run :MasonToolsUpdate"
