iex --sname node -S mix mnesia.init
MIX_ENV=prod elixir --detached -S mix phoenix.server



