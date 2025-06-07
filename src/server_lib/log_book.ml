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

[@@@ocaml.warning "-27"]

open Sqlite3
open Types_lib.Types

exception Order_not_found of orderId
exception Cancel_not_found of orderId

module Log_book : LOG_BOOK = struct

  (* --------- *)
  
  let init_tables db =
    let sql =
      "BEGIN;
      CREATE TABLE IF NOT EXISTS orders (
        order_id     TEXT PRIMARY KEY,
        user_id      TEXT NOT NULL,
        side         CHAR(1) NOT NULL,
        price        REAL,
        quantity     INTEGER NOT NULL,
        timestamp    TEXT NOT NULL
      );
      CREATE TABLE IF NOT EXISTS cancels (
        cancel_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id     TEXT NOT NULL,
        user_id      TEXT NOT NULL,
        timestamp    TEXT NOT NULL
      );
      CREATE TABLE IF NOT EXISTS fills (
        fill_id      INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id     TEXT NOT NULL,
        filled_qty   INTEGER NOT NULL,
        fill_price   REAL NOT NULL,
        timestamp    TEXT NOT NULL
      );
      COMMIT;"
    in

    match exec db sql with
    | Rc.OK -> ()
    | rc    -> failwith ("init_tables failed: " ^ Rc.to_string rc)

  (* --------- *)

  let log_order db ord =
    init_tables db;
    let stmt = prepare db
        "INSERT INTO orders (order_id,user_id,side,price,quantity,timestamp) VALUES (?1,?2,?3,?4,?5,?6);" in
    
    ignore @@ bind stmt 1 (Data.TEXT ord.id);
    ignore @@ bind stmt 2 (Data.TEXT ord.user_id);
    ignore @@ bind stmt 3 (Data.TEXT (String.make 1 (side_to_char ord.side)));
    
    (
      match ord.price with
      | Some p -> ignore @@ bind stmt 4 (Data.FLOAT p)
      | None -> ignore @@ bind stmt 4 Data.NULL);
    
    ignore @@ bind stmt 5 (Data.INT (Int64.of_int ord.quantity));
    ignore @@ bind stmt 6 (Data.TEXT ord.timestamp);
    (
      match step stmt with
      | Rc.DONE -> ()
      | rc -> failwith ("log_order error: " ^ Rc.to_string rc));
    
    ignore @@ reset stmt;
    ignore @@ finalize stmt;
    
    {
      alive = true;
      cancelled = false;
      side = ord.side;
      order_amount = ord.quantity;
      fill_amount = 0;
      timestamp = ord.timestamp;
      error_code = 0;
      price = ord.price
    }

  (* --------- *)
  
  let log_cancel db (req : cancelReq) =
    init_tables db;
    let check = prepare db "SELECT 1 FROM orders WHERE order_id = ?1;" in
    
    ignore @@ bind check 1 (Data.TEXT req.order_id);
    
    if step check <> Rc.ROW then
      (ignore @@ finalize check; raise (Order_not_found req.order_id));
    
    ignore @@ reset check; ignore @@ finalize check;
    
    let stmt = prepare db
        "INSERT INTO cancels (order_id,user_id,timestamp) VALUES (?1,?2,?3);" in
    
    ignore @@ bind stmt 1 (Data.TEXT req.order_id);
    ignore @@ bind stmt 2 (Data.TEXT req.user_id);
    ignore @@ bind stmt 3 (Data.TEXT (string_of_float (Unix.gettimeofday ())));
    
    (
      match step stmt with
      | Rc.DONE -> ()
      | rc -> failwith ("log_cancel error: " ^ Rc.to_string rc));
    
    ignore @@ reset stmt;
    ignore @@ finalize stmt;
    
    { order_id = req.order_id; user_id = req.user_id;
      order_quantity = 0; amount_canceled = 0 }
    
  (* --------- *)
  
  let update_fill db order_id qty =
    init_tables db;
    let check = prepare db "SELECT 1 FROM orders WHERE order_id = ?1;" in
    
    ignore @@ bind check 1 (Data.TEXT order_id);
    
    if step check <> Rc.ROW then
      (ignore @@ finalize check; raise (Order_not_found order_id));
    
    ignore @@ reset check;
    ignore @@ finalize check;
    
    let stmt = prepare db
        "INSERT INTO fills (order_id,filled_qty,fill_price,timestamp) VALUES (?1,?2,?3,?4);" in
    
    ignore @@ bind stmt 1 (Data.TEXT order_id);
    ignore @@ bind stmt 2 (Data.INT (Int64.of_int qty));
    ignore @@ bind stmt 3 (Data.FLOAT 0.0);
    ignore @@ bind stmt 4 (Data.TEXT (string_of_float (Unix.gettimeofday ())));
    
    (
      match step stmt with
      | Rc.DONE -> ()
      | rc -> failwith ("update_fill error: " ^ Rc.to_string rc));
    
    ignore @@ reset stmt;
    ignore @@ finalize stmt

  (* --------- *)

  let get_alive_ack db id =
  init_tables db;
  let stmt = prepare db
      "SELECT side, price, quantity, timestamp \
       FROM orders WHERE order_id = ?1;" in
  ignore (bind stmt 1 (Data.TEXT id));
  if step stmt <> Rc.ROW then begin
    ignore (finalize stmt);
    None
  end else begin
    let side_char = match column stmt 0 with Data.TEXT s -> s.[0] | _ -> 'I' in
    let side      = if side_char = 'B' then Buy else Sell in
    let price     = match column stmt 1 with Data.FLOAT f -> Some f | _ -> None in
    let amount    =
      match column stmt 2 with
      | Data.INT i   -> Int64.to_int i
      | Data.FLOAT f -> int_of_float f
      | _            -> 0
    in
    let ts        = match column stmt 3 with Data.TEXT s -> s | _ -> "" in
    ignore (reset stmt);
    ignore (finalize stmt);

    let stmt2 = prepare db
        "SELECT SUM(filled_qty) FROM fills WHERE order_id = ?1;" in
    ignore (bind stmt2 1 (Data.TEXT id));
    let filled = match step stmt2 with
      | Rc.ROW ->
        (match column stmt2 0 with Data.INT i -> Int64.to_int i | _ -> 0)
      | _ -> 0
    in
    ignore (reset stmt2);
    ignore (finalize stmt2);

    Some {
      alive        = (filled < amount);
      cancelled    = false;
      side;
      order_amount = amount;
      fill_amount  = filled;
      timestamp    = ts;
      error_code   = 0;
      price        = price;
    }
  end


  (* --------- *)

  let reset_tables db =
    ignore @@ exec db "DROP TABLE IF EXISTS orders; DROP TABLE IF EXISTS cancels; DROP TABLE IF EXISTS fills;";
    init_tables db

  (* --------- *)

  let get_trade_history db =
    init_tables db;
    let stmt = prepare db
        "SELECT timestamp,order_id,order_id,fill_price,filled_qty FROM fills ORDER BY fill_id;" in
    let rec loop acc =
      match step stmt with
      | Rc.ROW ->
        let ts = ( match column stmt 0 with
            | Data.TEXT s -> s
            | _ -> "" )
        in
        let a = ( match column stmt 1 with
            | Data.TEXT s -> s
            | _ -> "" )
        in
        let p = (match column stmt 2 with
            | Data.TEXT s -> s
            | _ -> "")
        in
        let price = (match column stmt 3 with
            | Data.FLOAT f -> f
            | _ -> 0.0)
        in
        let qty = (match column stmt 4 with
            | Data.INT i -> Int64.to_int i
            | _ -> 0)
        in
        loop ((ts,a,p,price,qty)::acc)
      | _ -> ignore @@ finalize stmt; List.rev acc
    in
    loop []
end
