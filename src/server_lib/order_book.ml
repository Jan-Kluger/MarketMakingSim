open Types_lib.Types

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
  val all_bids   : t -> order list
  val all_asks   : t -> order list
  val find_order : t -> orderId -> order option

  (** [trade_history book]  
      Read the full trade log out of [book.db], returning
      a list of (timestamp, aggressor_id, passive_id, price, qty). *)
  val trade_history : t -> (string * orderId * orderId * float * int) list
end

module Make
  (Log : Log_book.LOG_BOOK)
  (W   : Wallet_store.WALLET_STORE)
  : ORDER_BOOK = struct

  exception Insufficient_funds of userId

  type t = {
    bids : order list;
    asks : order list;
    db   : Sqlite3.db;
  }

  let create (db: Sqlite3.db) : t =
    Log.reset_tables db;
    { bids = []; asks = []; db }

  let restore_from_db (db: Sqlite3.db) : t =
    create db

  (** Check if [incoming] can match a resting order at [resting_price] *)
  let is_match (incoming: order) (resting_price: float option) : bool =
    match incoming.side, incoming.price, resting_price with
    | Invalid, _, _ -> false
    | Buy, None, Some _ -> true
    | Sell, None, Some _ -> true
    | Buy, Some p, Some rp -> rp <= p
    | Sell, Some p, Some rp -> rp >= p
    | _ -> false

  (* Repeatedly match [incoming] until its quantity is exhausted or no more matches.
      Returns remaining qty, list of fills, and the updated book. *)
  let rec match_loop
    (incoming: order)
    (remaining: int)
    (book: t)
    (acc: (orderId * float * int) list)
    : int * (orderId * float * int) list * t =
    if remaining = 0 then (remaining, List.rev acc, book)
    else
      match incoming.side with
      | Buy ->
        (match book.asks with
         | ask :: rest when is_match incoming ask.price ->
           
           let fill_qty = min remaining ask.quantity in
           let fill_price = Option.value ~default:0.0 ask.price in
           
           Log.update_fill book.db incoming.id fill_qty;
           Log.update_fill book.db ask.id fill_qty;
           
           ignore @@ W.withdraw_funds book.db incoming.user_id (float_of_int fill_qty *. fill_price);
           ignore @@ W.deposit_funds  book.db ask.user_id      (float_of_int fill_qty *. fill_price);
           
           let updated_ask =
             { ask with quantity = ask.quantity - fill_qty }
           in
           
           let new_asks = if updated_ask.quantity > 0 then
               updated_ask :: rest
             else
               rest
           in
           
           let new_book =
             { book with asks = new_asks }
           in
           
           match_loop incoming (remaining - fill_qty) new_book ((ask.id, fill_price, fill_qty) :: acc)
             
         | _ -> (remaining, List.rev acc, book))
      | Sell ->
        (match book.bids with
         | bid :: rest when is_match incoming bid.price ->
           
           let fill_qty = min remaining bid.quantity in
           let fill_price = Option.value ~default:0.0 bid.price in
           
           Log.update_fill book.db incoming.id fill_qty;
           Log.update_fill book.db bid.id fill_qty;
           
           ignore @@ W.deposit_funds  book.db incoming.user_id (float_of_int fill_qty *. fill_price);
           ignore @@ W.withdraw_funds book.db bid.user_id      (float_of_int fill_qty *. fill_price);
           
           let updated_bid =
             { bid with quantity = bid.quantity - fill_qty }
           in
           
           let new_bids = if updated_bid.quantity > 0
             then updated_bid :: rest
             else rest
           in
           
           let new_book =
             { book with bids = new_bids }
           in
           
           match_loop incoming (remaining - fill_qty) new_book ((bid.id, fill_price, fill_qty) :: acc)
             
         | _ -> (remaining, List.rev acc, book))
      | Invalid -> (remaining, List.rev acc, book)

  let place_order (book: t) (ord: order) : t * (orderId * float * int) list =
    (* Limit buy funds check *)
    (match ord.side, ord.price with
     | Buy, Some p ->
       let cost = p *. float_of_int ord.quantity in
       
       (match W.get_wallet book.db ord.user_id with
        | Some bal when bal >= cost -> ()
        | _ -> raise (Insufficient_funds ord.user_id))
     | _ -> ());
    
    ignore @@ Log.log_order book.db ord;
    
    let rem, fills, interim = match_loop ord ord.quantity book [] in
    let updated_book =
      if rem > 0 then
        let residual = { ord with quantity = rem } in
        (match ord.side with
         | Buy  -> { interim with bids = interim.bids @ [residual] }
         | Sell -> { interim with asks = interim.asks @ [residual] }
         | Invalid -> interim)
      else interim
    in
    (updated_book, fills)

  let cancel_order (book: t) (id: orderId) : t * int option =
    let ack_opt =
      try Some (Log.log_cancel book.db { order_id = id; user_id = "" })
      with _ -> None in
    
    let remove lst = List.filter (fun o -> o.id <> id) lst in
    
    let new_bids = remove book.bids in
    let new_asks = remove book.asks in
    
    ({ book with
       bids = new_bids;
       asks = new_asks
     },
     
     Option.map (fun a -> a.amount_canceled) ack_opt)

let all_bids (book: t) : order list =
  book.bids

let all_asks (book: t) : order list =
  book.asks

  let find_order (book: t) (id: orderId) : order option =
    List.find_opt (fun o -> o.id = id) (book.bids @ book.asks)

  let trade_history (book: t) : (string * orderId * orderId * float * int) list =
    Log.get_trade_history book.db
end
