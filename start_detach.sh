npm install --prefix assets
npm run deploy --prefix assets

lsof -i:4002 | grep beam | awk '{print $2}' | head -n 1 | xargs kill -9
MIX_ENV=prod elixir --sname node  --detached -S mix startup



