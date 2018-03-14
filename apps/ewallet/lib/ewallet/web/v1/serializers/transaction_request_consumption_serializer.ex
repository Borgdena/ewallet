defmodule EWallet.Web.V1.TransactionRequestConsumptionSerializer do
  @moduledoc """
  Serializes transaction request consumption data into V1 JSON response format.
  """
  alias EWallet.Web.V1.MintedTokenSerializer
  alias EWallet.Web.Date

  def serialize(consumption) do
    %{
      object: "transaction_request_consumption",
      id: consumption.id,
      status: consumption.status,
      approved: consumption.approved,
      amount: consumption.amount,
      minted_token: MintedTokenSerializer.serialize(consumption.minted_token),
      correlation_id: consumption.correlation_id,
      idempotency_token: consumption.idempotency_token,
      transaction_id: consumption.transfer_id,
      user_id: consumption.user_id,
      account_id: consumption.account_id,
      transaction_request_id: consumption.transaction_request_id,
      transfer_id: consumption.transfer_id,
      address: consumption.balance_address,
      created_at: Date.to_iso8601(consumption.inserted_at),
      updated_at: Date.to_iso8601(consumption.updated_at),
      finalized_at: Date.to_iso8601(consumption.finalized_at)
    }
  end
end
