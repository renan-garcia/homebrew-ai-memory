#!/usr/bin/env bash
set -euo pipefail

upstream_repo="${AI_MEMORY_UPSTREAM_REPO:-akitaonrails/ai-memory}"
formula_path="${1:-Formula/ai-memory.rb}"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

hash_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    echo "Missing required command: shasum or sha256sum" >&2
    exit 1
  fi
}

need_cmd awk
need_cmd curl
need_cmd ruby

if [[ ! -f "$formula_path" ]]; then
  echo "Formula not found: $formula_path" >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

api_url="https://api.github.com/repos/${upstream_repo}/releases/latest"
release_json="$(curl -fsSL \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "$api_url")"

tag="$(
  RELEASE_JSON="$release_json" ruby -rjson -e '
    release = JSON.parse(ENV.fetch("RELEASE_JSON"))
    tag = release.fetch("tag_name")
    abort("latest release is a draft") if release["draft"]
    abort("latest release is a prerelease") if release["prerelease"]
    puts tag
  '
)"
version="${tag#v}"

if [[ -z "$version" || "$version" == "$tag" && "$tag" != v* ]]; then
  echo "Unexpected release tag: $tag" >&2
  exit 1
fi

aarch64_url="https://github.com/${upstream_repo}/releases/download/${tag}/ai-memory-macos-aarch64.tar.gz"
x86_64_url="https://github.com/${upstream_repo}/releases/download/${tag}/ai-memory-macos-x86_64.tar.gz"
aarch64_tarball="${tmpdir}/ai-memory-macos-aarch64.tar.gz"
x86_64_tarball="${tmpdir}/ai-memory-macos-x86_64.tar.gz"

echo "Latest ai-memory release: ${tag}"
echo "Downloading Apple Silicon artifact..."
curl -fL --retry 3 --output "$aarch64_tarball" "$aarch64_url"
echo "Downloading Intel artifact..."
curl -fL --retry 3 --output "$x86_64_tarball" "$x86_64_url"

aarch64_sha256="$(hash_file "$aarch64_tarball")"
x86_64_sha256="$(hash_file "$x86_64_tarball")"

AI_MEMORY_VERSION="$version" \
AI_MEMORY_TAG="$tag" \
AI_MEMORY_REPO="$upstream_repo" \
AI_MEMORY_AARCH64_SHA256="$aarch64_sha256" \
AI_MEMORY_X86_64_SHA256="$x86_64_sha256" \
AI_MEMORY_FORMULA="$formula_path" \
ruby <<'RUBY'
path = ENV.fetch("AI_MEMORY_FORMULA")
version = ENV.fetch("AI_MEMORY_VERSION")
tag = ENV.fetch("AI_MEMORY_TAG")
repo = ENV.fetch("AI_MEMORY_REPO")
aarch64_sha256 = ENV.fetch("AI_MEMORY_AARCH64_SHA256")
x86_64_sha256 = ENV.fetch("AI_MEMORY_X86_64_SHA256")

aarch64_url = "https://github.com/#{repo}/releases/download/#{tag}/ai-memory-macos-aarch64.tar.gz"
x86_64_url = "https://github.com/#{repo}/releases/download/#{tag}/ai-memory-macos-x86_64.tar.gz"

text = File.read(path)
text.sub!(/version "[^"]+"/, %(version "#{version}")) or abort("version line not found")
text.sub!(
  /if Hardware::CPU\.arm\?\n\s+url "[^"]+"\n\s+sha256 "[a-f0-9]+"/,
  %(if Hardware::CPU.arm?\n      url "#{aarch64_url}"\n      sha256 "#{aarch64_sha256}"),
) or abort("Apple Silicon URL/SHA block not found")
text.sub!(
  /elsif Hardware::CPU\.intel\?\n\s+url "[^"]+"\n\s+sha256 "[a-f0-9]+"/,
  %(elsif Hardware::CPU.intel?\n      url "#{x86_64_url}"\n      sha256 "#{x86_64_sha256}"),
) or abort("Intel URL/SHA block not found")
File.write(path, text)
RUBY

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "version=${version}"
    echo "tag=${tag}"
    echo "aarch64_sha256=${aarch64_sha256}"
    echo "x86_64_sha256=${x86_64_sha256}"
  } >>"$GITHUB_OUTPUT"
fi

echo "Formula updated for ai-memory ${version}"
echo "aarch64 sha256: ${aarch64_sha256}"
echo "x86_64 sha256: ${x86_64_sha256}"
