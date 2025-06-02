(* log_book.mli *)

open Sqlite3
open Types_lib.Types

module type LOG_BOOK = sig
  type interval_bucket = {
    bucket_start     : string;
    bucket_end       : string;
    total_volume     : int;
    highest_bid      : float;
    lowest_ask       : float;
    last_trade_price : float;
  }

  val log_order :
    db ->
    order_id:string ->
    user_id:int ->
    side:side ->
    order_amount:int ->
    price:float ->
    timestamp:string ->
    error_code:int ->
    bool

  val cancel_order :
    db ->
    order_id:string ->
    timestamp:string ->
    error_code:int ->
    aliveAck option

  val update_fill :
    db ->
    order_id:string ->
    filled_quantity:int ->
    fill_price:float ->
    timestamp:string ->
    error_code:int ->
    aliveAck option

  val get_alive_ack :
    db ->
    order_id:string ->
    aliveAck option

  val get_history :
    db ->
    order_id:string ->
    aliveAck list

  val reset_tables :
    db ->
    unit

  val get_interval :
    db ->
    start_ts:string ->
    end_ts:string ->
    granularity_sec:int ->
    max_points:int ->
    interval_bucket list

end

module LOG_BOOK_impl : LOG_BOOK
