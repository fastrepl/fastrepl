Mox.defmock(Fastrepl.Cache.Mock, for: Fastrepl.Cache)
Application.put_env(:fastrepl, :cache, Fastrepl.Cache.Mock)

Mox.defmock(Fastrepl.Retrieval.Embedding.Mock, for: Fastrepl.Retrieval.Embedding)
Application.put_env(:fastrepl, :embedding, Fastrepl.Retrieval.Embedding.Mock)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Fastrepl.Repo, :manual)
