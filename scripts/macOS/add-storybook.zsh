#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Adding Storybook and addons to current React project...$reset_color

npx storybook@latest init --no-dev
npm install -D @storybook/addon-essentials
npm install -D @storybook/test-runner jest @storybook/react-vite @vitejs/plugin-react @babel/preset-env @babel/preset-typescript @babel/preset-react npx install @chromatic-com/storybook
npm install -D @storybook/addon-measure @storybook/addon-outline @storybook/addon-actions @storybook/addon-actions @storybook/addon-links @storybook/addon-a11y @storybook/addon-controls @storybook/addon-viewport @storybook/addon-backgrounds @storybook/addon-toolbars @storybook/addon-knobs
npm install -D storybook-addon-performance

# Add MSW to Storybook
echo $fg[yellow]Installing and configuring Mock Service Worker...$reset_color
npm install -D msw@latest msw-storybook-addon@latest
npx msw init public/ --save
