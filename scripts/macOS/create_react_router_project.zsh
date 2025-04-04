#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Creating new React Router Framework mode project...$reset_color

read "project_name?What will be the name of the React project? "
echo $fg[yellow]A new React Router Framework mode project named $project_name will be created.$reset_color

read "node_js_runtime?What version of Node.js do you want to use? "
echo $fg[yellow]Node.js version $node_js_runtime will be used.$reset_color

# Create the React Router Framework mode project
npx create-react-router@latest $project_name
cd ./$project_name

# Add the Node.js runtime version
touch .nvmrc
echo $node_js_runtime >./.nvmrc

# Add vitest and React Testing Library dependencies
echo $fg[yellow]Installing Vitest and React Testing Library...$reset_color
npm install -D happy-dom vitest @vitest/ui @testing-library/react @testing-library/jest-dom @testing-library/user-event

# Add eslint and fix issues with bootstrapped project files
echo $fg[yellow]Installing and configuring eslint...$reset_color
npm install -D eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin eslint-plugin-react eslint-plugin-react-hooks eslint-plugin-import eslint-plugin-jsx-a11y eslint-import-resolver-typescript eslint-config-prettier eslint-plugin-vitest nodemon
touch ./.eslint.config.mjs
cat ~/.dotfiles/templates/eslint/eslint.config.mjs >./.eslint.config.mjs

# Add Prettier
echo $fg[yellow]Installing and configuring Prettier...$reset_color
npm install -D prettier eslint-config-prettier eslint-plugin-prettier
touch ./.prettierrc.mjs
cat ~/.dotfiles/templates/prettier/.prettierrc.mjs >./.prettierrc.mjs
touch ./.prettierignore
cat ~/.dotfiles/templates/prettier/.prettierignore >./.prettierignore

~/.dotfiles/scripts/macOS/add-storybook.zsh

# Add Rollup bundle visualizer
echo $fg[yellow]Installing and configuring Rollup bundle visualizer...$reset_color
npm install -D rollup-plugin-visualizer
cat ~/.dotfiles/templates/vite/vite.config.ts >./vite.config.ts

# Fix any issues with eslint
echo $fg[yellow]Running eslint to fix any issues...$reset_color
npx eslint --fix ./src

# Reformat files with Prettier
echo $fg[yellow]Running Prettier to reformat files...$reset_color
npx prettier . --write
