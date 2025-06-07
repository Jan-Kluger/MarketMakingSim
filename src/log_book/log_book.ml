
[@@@ocaml.warning "-27"]

open Sqlite3
open Types_lib.Types

module type LOG_BOOK = sig
  (** [log_order db ord]  
      Persist a new incoming [ord] and return its initial aliveAck
      (alive = true, fill_amount = 0, cancelled = false). *)
  val log_order
    :  db
    -> order
    -> aliveAck

  (** [log_cancel db req]  
      Persist a cancel request [req] and return the resulting cancelAck. *)
  val log_cancel
    :  db
    -> cancelReq
    -> cancelAck

  (** [update_fill db order_id qty]  
      Record that [qty] units of [order_id] have been filled.
      Updates any cumulative counters, and may record a trade entry. *)
  val update_fill
    :  db
    -> orderId
    -> int
    -> unit

  (** [get_alive_ack db id]  
      Fetch the latest alive/cancelled/fill status for order [id],
      returning [Some aliveAck] if found or [None] otherwise. *)
  val get_alive_ack
    :  db
    -> orderId
    -> aliveAck option

  (** [reset_tables db]  
      Drop and recreate all log-related tables:
      orders, cancels, fills/trades. *)
  val reset_tables
    :  db
    -> unit

  (** [get_trade_history db]  
      Return the full list of executed trades, each as
      (timestamp, aggressor_id, passive_id, price, quantity). *)
  val get_trade_history
    :  db
    -> (string * orderId * orderId * float * int) list
end

module Log_book : LOG_BOOK = struct

  let log_order db ord =
    failwith "TODO: implement log_order"

  let log_cancel db req =
    failwith "TODO: implement log_cancel"

  let update_fill db order_id qty =
    failwith "TODO: implement update_fill"

  let get_alive_ack db id =
    failwith "TODO: implement get_alive_ack"

  let reset_tables db =
    failwith "TODO: implement reset_tables"

  let get_trade_history db =
    failwith "TODO: implement get_trade_history"
end
