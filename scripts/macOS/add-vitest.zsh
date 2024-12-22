#!/bin/zsh

autoload colors
colors

echo $fg[yellow]Installing Vitest and React Testing Library...$reset_color
npm install -D jsdom vitest @vitest/ui @testing-library/react @testing-library/jest-dom @testing-library/user-event vitest-axe@1.0.0-pre.3

touch ./vitest.config.ts
cat ~/.dotfiles/templates/vitest/vitest.config.ts >./vitest.config.ts
