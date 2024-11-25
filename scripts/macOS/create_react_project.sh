#!/bin/zsh

autoload colors
colors

export NODE_JS_RUNTIME="lts/jod"

echo $fg[cyan]Creating new React/Vite project...$reset_color

read "project_name?What will be the name of the React project? "

npm create vite@latest $project_name -- --template react-ts
cd ./$project_name

echo $fg[yellow]Setting the default Node.js runtime to $NODE_JS_RUNTIME.$reset_color
touch .nvmrc
echo $NODE_JS_RUNTIME >./.nvmrc

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

# Add Storybook
echo $fg[yellow]Installing and configuring Storybook...$reset_color
npx storybook@latest init --no-dev
npm install -D @storybook/test-runner jest @storybook/react-vite @vitejs/plugin-react @babel/preset-env @babel/preset-typescript @babel/preset-react @storybook/addon-links @storybook/addon-a11y

# Add MSW to Storybook
echo $fg[yellow]Installing and configuring Mock Service Worker...$reset_color
npm install -D msw@latest msw-storybook-addon@latest
npx msw init public/ --save

echo $fg[yellow]Running eslint to fix any issues...$reset_color
npx eslint --fix ./src

echo $fg[yellow]Running Prettier to reformat files...$reset_color
npx prettier . --write
