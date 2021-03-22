defmodule Mix.Tasks.Mnesia.Init do
    use Mix.Task
    def run(_) do
        nodes = [ node() ]

    # Create the schema
        Memento.stop
        Memento.Schema.create(nodes)
        Memento.start
        Memento.Table.create(ChatReadModel.Model, disc_copies: nodes)
    end

end

