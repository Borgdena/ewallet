defmodule EWallet.TransactionRequestGate do
  @moduledoc """
  Business logic to manage transaction requests. This module is responsible
  for creating new requests, retrieving existing ones and handles the logic
  of picking the right balance when inserting a new request.

  It is basically an interface to the EWalletDB.TransactionRequest schema.
  """
  alias EWallet.BalanceFetcher
  alias EWalletDB.{TransactionRequest, User, Balance, MintedToken, Account}

  @doc """
  Creates a transaction request based on the given attributes.

  Returns `{:ok, transaction_request}` on successful creation.
  Returns `{:error, code}` on error.
  """
  @spec create_from_attrs(Map.t) :: {:ok, TransactionRequest.t} | {:error, Atom.t}
  def create_from_attrs(attrs) do
    case attrs_to_balance(attrs) do
      {:ok, balance}      -> create(balance, attrs)
      {:error, _} = error -> error
    end
  end

  defp attrs_to_balance(%{"account_id" => account_id, "address" => address}) do
    case Account.get(account_id) do
      %Account{} = account -> BalanceFetcher.get(account, address)
      _                    -> {:error, :account_id_not_found}
    end
  end
  defp attrs_to_balance(%{"provider_user_id" => provider_user_id, "address" => address}) do
    case User.get_by_provider_user_id(provider_user_id) do
      %User{} = user -> BalanceFetcher.get(user, address)
      _              -> {:error, :provider_user_id_not_found}
    end
  end
  defp attrs_to_balance(%{"account_id" => _} = attrs) do
    attrs
    |> Map.put("address", nil)
    |> attrs_to_balance()
  end
  defp attrs_to_balance(%{"provider_user_id" => _} = attrs) do
    attrs
    |> Map.put("address", nil)
    |> attrs_to_balance()
  end
  defp attrs_to_balance(%{"address" => address}), do: BalanceFetcher.get(nil, address)
  defp attrs_to_balance(_), do: {:error, :invalid_parameter}

  @doc """
  Creates a transaction based on the given `Balance` or `User`,
  along with other attributes.

  Returns `{:ok, transaction_request}` on successful creation.
  Returns `{:error, code}` on error.
  """
  @spec create(User.t | Balance.t, Map.t) :: {:ok, TransactionRequest.t} | {:error, Atom.t}
  def create(%User{} = user, %{"address" => address} = attrs) do
    case BalanceFetcher.get(user, address) do
      {:ok, balance} -> create(balance, attrs)
      error          -> error
    end
  end
  def create(%Balance{} = balance, %{
    "type" => _,
    "correlation_id" => _,
    "amount" => _,
    "token_id" => token_id
  } = attrs) do
    with %MintedToken{} = minted_token <- MintedToken.get(token_id) ||
                                          {:error, :minted_token_not_found},
         {:ok, transaction_request}    <- insert(minted_token, balance, attrs)
    do
      get(transaction_request.id, preload: [:minted_token, :user, :balance])
    else
      error -> error
    end
  end
  def create(_, _attrs), do: {:error, :invalid_parameter}

  defp insert(minted_token, balance, attrs) do
    TransactionRequest.insert(%{
      type: attrs["type"],
      correlation_id: attrs["correlation_id"],
      amount: attrs["amount"],
      user_id: balance.user_id,
      account_id: balance.account_id,
      minted_token_id: minted_token.id,
      balance_address: balance.address
    })
  end

  @doc """
  Retrieves the transaction request with the given ID.

  Returns {:ok, transaction_request} on success.
  Returns {:error, :transaction_request_not_found} if the given ID could not be found.
  """
  @spec get(UUID.t) :: {:ok, TransactionRequest.t} | {:error, :transaction_request_not_found}
  def get(id) do
    case TransactionRequest.get(id) do
      nil     -> {:error, :transaction_request_not_found}
      request -> {:ok, request}
    end
  end
end
