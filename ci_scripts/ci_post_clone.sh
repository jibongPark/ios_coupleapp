#!/bin/sh
set -e
cd ..

commit_message=$(git log -1 --pretty=%B)

echo "❗️ commit : $commit_message"

#if [[ "$CI_WORKFLOW" = "Default" && "$commit_message" != "[archive]"* ]]; then
#    echo "[archive] 키워드가 없으므로 빌드를 중단합니다."
#    exit 1
#fi


curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

# Output the current PATH for debugging
echo "❗️Current PATH: $PATH"

echo "❗️mise version"
mise --version
echo "❗️mise install"
mise install # Installs the version from .mise.toml
eval "$(mise activate bash --shims)"

echo "❗️mise doctor"
mise doctor # verify the output of mise is correct on CI
echo "❗️tuist install"
tuist install
echo "❗️tuist generate"
tuist generate # Generate the Xcode Project using Tuist
