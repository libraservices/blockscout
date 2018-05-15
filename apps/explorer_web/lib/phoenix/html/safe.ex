alias Explorer.Chain
alias Explorer.Chain.{Address, Block, Hash, Transaction}

defimpl Phoenix.HTML.Safe, for: [Address, Transaction] do
  def to_iodata(%@for{hash: hash}) do
    @protocol.to_iodata(hash)
  end
end

defimpl Phoenix.HTML.Safe, for: Block do
  def to_iodata(%@for{number: number}) do
    @protocol.to_iodata(number)
  end
end

defimpl Phoenix.HTML.Safe, for: Hash do
  def to_iodata(hash) do
    Chain.hash_to_iodata(hash)
  end
end