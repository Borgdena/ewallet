defmodule EWallet.Web.V1.BalanceSerializer do
  @moduledoc """
  Serializes balance data into V1 JSON response format.
  """
  alias EWallet.Web.V1.MintedTokenSerializer

  def serialize(balance) do
    %{
      object: "balance",
      minted_token: MintedTokenSerializer.serialize(balance.minted_token),
      amount: balance.amount
    }
  end
end
