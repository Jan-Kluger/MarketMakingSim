open Types_lib.Types

(* module type ORDER_MANAGER = sig *)
(*   val submit_order    : order             -> submitAck *)
(*   val cancel_order    : cancelReq         -> cancelAck *)
(*   val get_wallet      : orderId           -> walletAck *)
(*   val order_info     : orderId            -> aliveAck *)
(*   val get_market_data : marketDataRequest -> marketDataAck *)
(*   val register_user   : userId            -> int option *)
(*   val get_new_id      : unit              -> userId *)
(* end *)

module type ORDER_MANAGER = sig
  (**
   Submit a new order.  
   *Generates a fresh, unpredictable orderId.*  
   Checks buyer balance (for limit buys), logs & matches the order,  
   and returns a [submitAck] with the assigned ID.
  **)
  val submit_order
    : order
    -> submitAck

  (**
   Cancel an existing order.  
   Removes it from the book, logs the cancellation,  
   and returns a [cancelAck] with the quantity actually cancelled.
  **)
  val cancel_order
    : cancelReq
    -> cancelAck

  (**
   Look up a user’s wallet balance.  
   Returns a [walletAck] with current balance or error code if missing.
  **)
  val get_wallet
    : userId
    -> walletAck

  (**
   Fetch the live/cancelled/filled status of a specific order.  
   Returns [Some aliveAck] if the order exists, or [None] otherwise.
  **)
  val order_info
    : orderId
    -> aliveAck

  (**
   Return the full order book.  
   Two lists of (price, remaining_quantity) for bids and for asks,  
   so the client can compute best bid/ask, depth, charts, etc.
  **)
  val get_book
    : unit
    -> (float * int) list * (float * int) list

  (**
   Stream raw trade events for analysis.  
   Given a time window [time_from..time_to], returns a list of  
   (timestamp, aggressor_id, passive_id, price, quantity).
  **)
  val get_market_data
    : marketDataRequest
    -> (string * orderId * orderId * float * int) list

  (**
   Register a brand-new user.  
   Generates a collision-resistant UUID, persists it in wallets,  
   and returns the [userId].
  **)
  val register_user
    : unit
    -> userId

  (**
   Generate a fresh UUID for external use.  
   Rarely needed if you always go through [submit_order] or [register_user].
  **)
  val get_new_id
    : unit
    -> userId
end

module Order_manager_impl
  (Log : Log_book.LOG_BOOK)
  (W   : Wallet_store.WALLET_STORE)
  (OB  : Order_book.ORDER_BOOK)
  : ORDER_MANAGER = struct

  let db    = Sqlite3.db_open "db/data.db"
  let state = ref (OB.create db)

  let gen_uuid () : string =
  let buf = Bytes.init 16 (fun _ -> Char.chr (Random.int 256)) in
  Uuidm.v4 buf |> Uuidm.to_string

  let register_user () : userId =
    let rec loop () =
      let uid = gen_uuid () in
      if W.register_user db uid then uid else loop ()
    in
    loop ()

  let get_new_id () : userId =
    let u = gen_uuid () in
    let _ = W.register_user db u in
    let _ = W.deposit_funds db u 10000.0 in
    u

  let submit_order (ord : order) : submitAck =
    let new_id = gen_uuid () in
    let ord = { ord with id = new_id } in

    try (

    let updated_book, _ = OB.place_order !state ord in
    state := updated_book;

    { order_id   = ord.id;
      timestamp  = ord.timestamp;
      status     = "ACCEPTED";
      error_code = 0 }
  ) with Order_book.Insufficient_funds _ ->
      { order_id   = "-1";
      timestamp  = "";
      status     = "DECLINED";
      error_code = 600 }

  let cancel_order (req : cancelReq) : cancelAck =
    let new_book, qty_opt = OB.cancel_order !state req.order_id in
    state := new_book;
    let res =
    match qty_opt with
    | Some q ->
      { order_id = req.order_id;
        user_id = req.user_id;
        order_quantity = q;
        amount_canceled = q }
    | None   -> 
      { order_id = "-1";
        user_id = "-1";
        order_quantity = -1;
        amount_canceled = -1
      }
    in
    res

  let get_wallet (uid : userId) : walletAck =
    match W.get_wallet db uid with
    | Some bal -> { user_id = uid; balance = bal; error_code = 0 }
    | None     -> { user_id = uid; balance = 0.0; error_code = 404 }

  let order_info (oid : orderId) : aliveAck =
    match OB.find_order !state oid with
    | Some o ->
      { alive        = true
      ; cancelled    = false
      ; price        = o.price
      ; side         = o.side
      ; order_amount = o.quantity
      ; fill_amount  = 0
      ; timestamp    = o.timestamp
      ; error_code   = 0
      }
    | None ->
      begin match Log.get_alive_ack db oid with
        | Some ack -> ack
        | None ->
          { alive        = false
          ; cancelled    = false
          ; price        = None
          ; side         = Invalid
          ; order_amount = 0
          ; fill_amount  = 0
          ; timestamp    = ""
          ; error_code   = 404
          }
      end


  let get_book () : (float * int) list * (float * int) list =
    let tstate = !state in
    let bids, asks = (OB.all_bids tstate, OB.all_asks tstate) in
    let proj (o: order) = (Option.value ~default:0.0 o.price, o.quantity) in
    (List.map proj bids, List.map proj asks)

  let get_market_data (req : marketDataRequest)
    : (string * orderId * orderId * float * int) list =
    Log.get_trade_history db
    |> List.filter (fun (ts,_,_,_,_) -> ts >= req.time_from && ts <= req.time_to)

end
