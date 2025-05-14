open Types_lib.Types

module type WALLET_STORE = sig
  val get_wallet : userId -> int option

  val register_user : userId -> int option
      
  val deposit_funds : userId -> int option
end

module WALLET_STORE_impl : WALLET_STORE = struct
  let get_wallet (_uid : userId) : int option =
    failwith "todo"

  let register_user (_uid : userId) : int option =
    failwith "todo"

  let deposit_funds (_uid : userId) : int option =
    failwith "todo"
end
