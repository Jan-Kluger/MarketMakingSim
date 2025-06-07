
[@@@ocaml.warning "-27"]
[@@@ocaml.warning "-33"]


open Types_lib.Types
open Sqlite3

module type ORDER_BOOK = sig
  (** The in-memory book plus its backing DB handle. *)
  type t = {
    bids : order list;
    asks : order list;
    db   : Sqlite3.db;
  }

  (** [create db]  
      Open (or reuse) [db] and return a fresh, empty book that will log into it. *)
  val create : Sqlite3.db -> t

  (** [restore_from_db db]  
      Replay all persisted events in [db] to reconstruct both the
      in-memory bids/asks and the internal handle. *)
  val restore_from_db : Sqlite3.db -> t

  (** [place_order book ord]  
      Insert [ord], match fills, log submission & fills into [book.db],
      returning (updated_book, fills).  
      Each fill is (matched_order_id, fill_price, fill_quantity). *)
  val place_order
    :  t
    -> order
    -> t * (orderId * float * int) list

  (** [cancel_order book id]  
      Remove resting order [id], log the cancellation into [book.db],
      returning (updated_book, Some cancelled_qty) if found or (book, None) otherwise. *)
  val cancel_order
    :  t
    -> orderId
    -> t * int option

  (** Pure, in-memory inspectors—none of these touch the DB. *)
  val best_bid   : t -> (float * int) option
  val best_ask   : t -> (float * int) option
  val all_bids   : t -> order list
  val all_asks   : t -> order list
  val depth_at   : t -> price:float -> (int * int)
  val find_order : t -> orderId -> order option

  (** [trade_history book]  
      Read the full trade log out of [book.db], returning
      a list of (timestamp, aggressor_id, passive_id, price, qty). *)
  val trade_history : t -> (string * orderId * orderId * float * int) list
end


module Make
  (Log : Log_book.LOG_BOOK)
  (W : Wallet_store.WALLET_STORE)
  : ORDER_BOOK = struct
  
    type t = {
    bids : order list;
    asks : order list;
    db   : Sqlite3.db;
  }

  let create db =
    { bids = []; asks = []; db }

  let restore_from_db db =
    failwith "TODO: implement restore_from_db"

  let place_order book ord =
    failwith "TODO: implement place_order"

  let cancel_order book id =
    failwith "TODO: implement cancel_order"

  let best_bid book =
    failwith "TODO: implement best_bid"

  let best_ask book =
    failwith "TODO: implement best_ask"

  let all_bids book =
    failwith "TODO: implement all_bids"

  let all_asks book =
    failwith "TODO: implement all_asks"

  let depth_at book ~price =
    failwith "TODO: implement depth_at"

  let find_order book id =
    failwith "TODO: implement find_order"

  let trade_history book =
    failwith "TODO: implement trade_history"
end
