#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Adding Storybook and addons to current React project...$reset_color

npx storybook@latest init --no-dev
npm install -D @storybook/addon-essentials
npm install -D @storybook/test-runner jest @storybook/react-vite @vitejs/plugin-react @babel/preset-env @babel/preset-typescript @babel/preset-react npx install @chromatic-com/storybook
npm install -D @storybook/addon-measure
npm install -D @storybook/addon-outline
npm install -D @storybook/addon-actions
npm install -D @storybook/addon-links
npm install -D @storybook/addon-a11y
npm install -D @storybook/addon-controls
npm install -D @storybook/addon-viewport
npm install -D @storybook/addon-backgrounds
npm install -D @storybook/addon-toolbars
#npm install -D @storybook/addon-knobs
#npm install -D storybook-addon-performance
npm install -D msw-storybook-addon@latest

# Add MSW to Storybook
echo $fg[yellow]Installing and configuring Mock Service Worker...$reset_color
npm install -D msw@latest msw-storybook-addon@latest
npx msw init public/ --save
