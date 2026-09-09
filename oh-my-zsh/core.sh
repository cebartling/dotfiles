# oh-my-zsh configuration sourced before $ZSH/oh-my-zsh.sh.
# Prompt is handled by starship (configured in ~/.zshrc), so the
# oh-my-zsh theme is intentionally empty to skip its setup work.

ZSH_THEME=""

plugins=(git git-extras git-flow)

# Never prompt to update oh-my-zsh on shell startup. `disabled` also skips the
# background check entirely, which keeps startup inside its ~150ms budget.
# Update deliberately with `omz update`.
zstyle ':omz:update' mode disabled
