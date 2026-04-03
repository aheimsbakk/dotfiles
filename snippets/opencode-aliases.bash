#
# Aliases for https://github.com/aheimsbakk/container-opencode
# Uses podman name to ensure that only one opencode runs at the time
#

if which podman > /dev/null; then
    alias oc='podman run -e OPENCODE_CONFIG=/home/opencode/opencode.json --hostname vibe --name opencode --rm --userns=keep-id -ti -v opencode:/home/opencode -v "$PWD":/work -v "$HOME"/.gitconfig:/home/opencode/.gitconfig opencode:latest'
    alias ocw='podman run -e OPENCODE_CONFIG=/home/opencode/opencode.json --hostname vibe --name opencode --rm --userns=keep-id -ti -p 4096:4096 -v opencode:/home/opencode -v "$PWD":/work -v "$HOME"/.gitconfig:/home/opencode/.gitconfig opencode:latest opencode-cli web --hostname 0.0.0.0'
fi
