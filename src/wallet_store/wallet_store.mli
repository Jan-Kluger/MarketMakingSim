open Types_lib.Types
open Sqlite3

module type WALLET_STORE = sig
  val get_wallet     : db -> userId -> float option
  val deposit_funds  : db -> userId -> float -> float option
  val withdraw_funds : db -> userId -> float -> float option
  val register_user  : db -> userId -> bool
  val reset_table    : db   -> unit
end

module WALLET_STORE_impl : WALLET_STORE
