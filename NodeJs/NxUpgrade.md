npx nx migrate latest
npx nx migrate --run-migrations

### take actions based on the migration output
#### e.g. change vite configure file, convert the js file, etc.....

npm i
npm ci
npx nx serve <AppName>
npx nx build <AppName>
npx serve dist/<AppName>

npx nx test <AppName>
npx nx lint <AppName>

npx nx storybook <StoryBookName>
npx nx build <StoryBookName>
npx serve dist/storybook/<StoryBookName>
npx nx lint <StoryBookName>