# Read the last entries into memory
HISTSIZE=1000

# Set history file size to something large
HISTFILESIZE=100000

# Append history to file when closing
shopt -s histappend

# Store history in realtime
#export PROMPT_COMMAND='history -a; history -n'

# Set history format
HISTTIMEFORMAT='| %F %T | '

# Ignore duplicates and commands starting with space
HISTCONTROL=ignoreboth
