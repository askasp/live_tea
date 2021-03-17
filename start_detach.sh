
lsof -i:4002 | grep beam | awk '{print $2}' | head -n 1 | xargs kill -9
MIX_ENV=prod elixir --detached -S mix startup



