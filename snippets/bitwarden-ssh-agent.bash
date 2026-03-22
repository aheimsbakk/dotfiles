_set_bitwarden_ssh() {
    if [ -S "$HOME/.bitwarden-ssh-agent.sock" ]; then
        export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
    elif [ -S "$HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock" ]; then
        export SSH_AUTH_SOCK="$HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock"
    fi
}

if [ -z "$SSH_CONNECTION" ]; then
    # Local session: Always try to use Bitwarden
    _set_bitwarden_ssh
elif [ -z "$SSH_AUTH_SOCK" ] || [ ! -S "$SSH_AUTH_SOCK" ]; then
    # SSH session: Only use Bitwarden if no agent was forwarded
    _set_bitwarden_ssh
fi
