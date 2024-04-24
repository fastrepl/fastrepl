defmodule Fastrepl.Repo do
  use Ecto.Repo,
    otp_app: :fastrepl,
    adapter: Ecto.Adapters.Postgres
end
