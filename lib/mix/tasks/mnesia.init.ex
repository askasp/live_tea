defmodule Mix.Tasks.Mnesia.Init do
#     use Mix.Task
#     def run(_) do
#         nodes = [ node() ]

#     # Create the schema
#         Memento.stop
#         Memento.Schema.create(nodes)
#         Memento.start
#         Memento.Table.create!(ChatReadModel.Model, disc_copies: nodes)
#     end

# end



  use Mix.Task

  @shortdoc "Sends a greeting to us from Hello Phoenix"

  @moduledoc """
  This is where we would put any long form documentation or doctests.
  """

  def run(_args) do
    Mix.shell().info("Greetings from the Hello Phoenix Application!")
  end

  # We can define other functions as needed here.
end
