
defmodule LiveTea.App do
  use Commanded.Application, otp_app: :live_tea
  router ChatRouter

end
