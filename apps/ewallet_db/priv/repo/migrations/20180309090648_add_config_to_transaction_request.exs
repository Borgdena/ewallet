defmodule EWalletDB.Repo.Migrations.AddConfigToTransactionRequest do
  use Ecto.Migration

  def change do
    alter table(:transaction_request) do
      add :confirmable, :boolean, null: false, default: false
      add :max_consumptions, :integer
      add :expiration_date, :naive_datetime
      add :expired_at, :naive_datetime
      add :metadata, :map
      add :encrypted_metadata, :binary
      add :encryption_version, :binary
    end

    create index(:transaction_request, [:metadata], using: "gin")
    create index(:transaction_request, [:encryption_version])
  end
end
