open Sqlite3
open Unix
open Types_lib.Types

(* Helper functions *)

let unix_to_iso8601 sec =
  let tm = localtime sec in
  Printf.sprintf "%04d-%02d-%02dT%02d:%02d:%02d"
    (1900 + tm.tm_year)
    (tm.tm_mon + 1)
    tm.tm_mday
    tm.tm_hour
    tm.tm_min
    tm.tm_sec

let iso8601_to_unix s : int =
  Scanf.sscanf s "%04d-%02d-%02dT%02d:%02d:%02d"
    (fun y m d hh mm ss ->
       let tm = {
         tm_sec = ss;
         tm_min = mm;
         tm_hour = hh;
         tm_mday = d;
         tm_mon = m - 1;
         tm_year = y - 1900;
         tm_wday = 0;
         tm_yday = 0;
         tm_isdst = false;
       } in
       int_of_float (fst (mktime tm)))

let int_to_bool = function 0L -> false | _ -> true

let side_to_string = function
  | Buy  -> "B"
  | Sell -> "S"
  | _ -> "I"

let string_to_side = function
  | "B" -> Buy
  | "S" -> Sell
  | s   -> failwith ("Unknown side: " ^ s)

let row_to_alive_ack stmt =
  let side_str =
    match Sqlite3.column stmt 2 with Sqlite3.Data.TEXT s -> s | _ -> ""
  in
  let order_amount =
    match Sqlite3.column stmt 3 with Sqlite3.Data.INT i -> Int64.to_int i | _ -> 0
  in
  let fill_amount =
    match Sqlite3.column stmt 4 with Sqlite3.Data.INT i -> Int64.to_int i | _ -> 0
  in
  let alive =
    match Sqlite3.column stmt 5 with Sqlite3.Data.INT i -> int_to_bool i | _ -> false
  in
  let cancelled =
    match Sqlite3.column stmt 6 with Sqlite3.Data.INT i -> int_to_bool i | _ -> false
  in
  let timestamp =
    match Sqlite3.column stmt 8 with Sqlite3.Data.TEXT s -> s | _ -> ""
  in
  let error_code =
    match Sqlite3.column stmt 9 with Sqlite3.Data.INT i -> Int64.to_int i | _ -> 0
  in
  {
    alive        = alive;
    cancelled    = cancelled;
    side         = string_to_side side_str;
    order_amount = order_amount;
    fill_amount  = fill_amount;
    timestamp    = timestamp;
    error_code   = error_code;
  }

(* Can sometimes be useful to get most recent row *)
let get_latest_order_row db order_id =
  let sql = {|
    SELECT order_id, user_id, side,
           order_amount, fill_amount, alive, cancelled,
           price, timestamp, error_code
      FROM orders
     WHERE order_id = ?1
     ORDER BY timestamp DESC
     LIMIT 1;
  |} in
  let stmt = Sqlite3.prepare db sql in
  ignore (Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT order_id));
  let res =
    match Sqlite3.step stmt with
    | Sqlite3.Rc.ROW ->
      let ack = row_to_alive_ack stmt in
      Some ack
    | Sqlite3.Rc.DONE -> None
    | rc -> failwith ("get_latest_order_row: " ^ Sqlite3.Rc.to_string rc)
  in
  ignore (Sqlite3.reset stmt);
  ignore (Sqlite3.finalize stmt);
  res

(* Log book signature *)

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

(**********************************)
(* IMPLEMENTATION                 *)
(**********************************)

module LOG_BOOK_impl : LOG_BOOK = struct

  type interval_bucket = {
    bucket_start     : string;
    bucket_end       : string;
    total_volume     : int;
    highest_bid      : float;
    lowest_ask       : float;
    last_trade_price : float;
  }

  (* ------- Log Order Function ------- *)

  let log_order db
      ~(order_id: string)
      ~(user_id: int)
      ~(side : side)
      ~(order_amount : int)
      ~(price : float)
      ~(timestamp : string)
      ~(error_code : int)
    : bool =
    let sql =
      {|
        INSERT INTO orders (order_id, user_id, side, order_amount,
                            fill_amount, alive, cancelled, price,
                            timestamp, error_code)
        VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10);
      |}
    in
    let stmt = Sqlite3.prepare db sql in

    ignore (Sqlite3.bind stmt 1  (TEXT order_id));
    ignore (Sqlite3.bind stmt 2  (INT  (Int64.of_int user_id)));
    ignore (Sqlite3.bind stmt 3  (TEXT (side_to_string side)));
    ignore (Sqlite3.bind stmt 4  (INT  (Int64.of_int order_amount)));
    ignore (Sqlite3.bind stmt 5  (INT  Int64.zero));
    ignore (Sqlite3.bind stmt 6  (INT  (Int64.of_int 1)));
    ignore (Sqlite3.bind stmt 7  (INT  (Int64.of_int 0)));
    ignore (Sqlite3.bind stmt 8  (FLOAT price));
    ignore (Sqlite3.bind stmt 9  (TEXT  timestamp));
    ignore (Sqlite3.bind stmt 10 (INT  (Int64.of_int error_code)));

    let rc = step stmt in

    ignore (reset stmt);
    ignore (finalize stmt);
    rc = Sqlite3.Rc.DONE

  (* ------- Cancel Order Function ------- *)
           
  let cancel_order db ~(order_id : string) ~(timestamp : string) ~(error_code : int) =
    match get_latest_order_row db order_id with
    | None -> None
    | Some _ ->
      let fetch_sql =
        {|
          SELECT user_id, side, order_amount, fill_amount, price
            FROM orders
           WHERE order_id = ?1
           ORDER BY timestamp DESC
           LIMIT 1;
        |}
      in
      let fetch_stmt = prepare db fetch_sql in
      ignore (Sqlite3.bind fetch_stmt 1 (Sqlite3.Data.TEXT order_id));
      let (user_id_int, side_str, ord_amt, fill_amt, pr) =
        match step fetch_stmt with
        | ROW ->
          let uid = match column fetch_stmt 0 with
            | INT i -> Int64.to_int i
            | _ -> 0
          in
          let s = match column fetch_stmt 1 with
            | TEXT t -> t
            | _ -> ""
          in
          let oa = match column fetch_stmt 2 with
            | INT i -> Int64.to_int i
            | _ -> 0 in
          let fa = match column fetch_stmt 3 with
            | INT i -> Int64.to_int i
            | _ -> 0 in
          let p =
            match column fetch_stmt 4 with
            | FLOAT f -> f
            | INT i   -> Int64.to_float i
            | _ -> 0.0
          in
          (uid, s, oa, fa, p)
        | DONE -> (0, "", 0, 0, 0.0)
        | rc -> failwith ("cancel_order fetch: " ^ Sqlite3.Rc.to_string rc)
      in
      ignore (reset fetch_stmt);
      ignore (finalize fetch_stmt);

      let sql =
        {|
          INSERT INTO orders (
            order_id, user_id, side,
            order_amount, fill_amount,
            alive, cancelled, price,
            timestamp, error_code
          ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10);
        |}
      in
      
      let stmt = Sqlite3.prepare db sql in
      ignore (Sqlite3.bind stmt 1  (TEXT order_id));
      ignore (Sqlite3.bind stmt 2  (INT  (Int64.of_int user_id_int)));
      ignore (Sqlite3.bind stmt 3  (TEXT side_str));
      ignore (Sqlite3.bind stmt 4  (INT  (Int64.of_int ord_amt)));
      ignore (Sqlite3.bind stmt 5  (INT  (Int64.of_int fill_amt)));
      ignore (Sqlite3.bind stmt 6  (INT  (Int64.of_int 0)));
      ignore (Sqlite3.bind stmt 7  (INT  (Int64.of_int 1)));
      ignore (Sqlite3.bind stmt 8  (FLOAT pr));
      ignore (Sqlite3.bind stmt 9  (TEXT  timestamp));
      ignore (Sqlite3.bind stmt 10 (INT  (Int64.of_int error_code)));
      
      let rc = Sqlite3.step stmt in
      
      ignore (reset stmt);
      ignore (finalize stmt);
      
      if rc <> DONE then
        None
      else
        get_latest_order_row db order_id

  (* ------- Update Fill Function ------- *)

  let update_fill db ~order_id ~filled_quantity ~fill_price ~timestamp ~error_code =
    match get_latest_order_row db order_id with
    | None -> None
    | Some prev ->
      let prev_fill = prev.fill_amount in
      let ord_amt   = prev.order_amount in
      let new_fill  = prev_fill + filled_quantity in
      let alive_int    = if new_fill < ord_amt then 1 else 0 in
      let cancelled_int = 0 in

      let fetch_sql =
        {|
          SELECT user_id, side, price
            FROM orders
          WHERE order_id = ?1
          ORDER BY timestamp DESC
          LIMIT 1;
        |}
      in
      
      let fetch_stmt = prepare db fetch_sql in
      
      ignore (Sqlite3.bind fetch_stmt 1 (TEXT order_id));
      
      let (user_id_int, side_str, pr) =
        match Sqlite3.step fetch_stmt with
        | ROW ->
          let uid = match column fetch_stmt 0 with
                   | INT i -> Int64.to_int i
                   | _ -> 0 in
          let s = match column fetch_stmt 1 with
            | TEXT t -> t
            | _ -> ""
          in
          let p = match column fetch_stmt 2 with
            | FLOAT f -> f
            | INT i   -> Int64.to_float i
            | _ -> 0.0
          in
          (uid, s, p)
        | DONE -> (0, "", 0.0)
        | rc -> failwith ("update_fill fetch: " ^ Sqlite3.Rc.to_string rc)
      in
      ignore (reset fetch_stmt);
      ignore (finalize fetch_stmt);

      let sql1 =
        {|
          INSERT INTO orders (
            order_id, user_id, side,
            order_amount, fill_amount,
            alive, cancelled, price,
            timestamp, error_code
          ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10);
        |}
      in
      let stmt1 = prepare db sql1 in

      ignore (Sqlite3.bind stmt1 1  (TEXT order_id));
      ignore (Sqlite3.bind stmt1 2  (INT  (Int64.of_int user_id_int)));
      ignore (Sqlite3.bind stmt1 3  (TEXT side_str));
      ignore (Sqlite3.bind stmt1 4  (INT  (Int64.of_int ord_amt)));
      ignore (Sqlite3.bind stmt1 5  (INT  (Int64.of_int new_fill)));
      ignore (Sqlite3.bind stmt1 6  (INT  (Int64.of_int alive_int)));
      ignore (Sqlite3.bind stmt1 7  (INT  (Int64.of_int cancelled_int)));
      ignore (Sqlite3.bind stmt1 8  (FLOAT pr));
      ignore (Sqlite3.bind stmt1 9  (TEXT  timestamp));
      ignore (Sqlite3.bind stmt1 10 (INT  (Int64.of_int error_code)));
      
      let rc1 = Sqlite3.step stmt1 in
      
      ignore (reset stmt1);
      ignore (finalize stmt1);
      
      if rc1 <> DONE then
        None
      else
        
        let insert_trade_sql =
          {|
            INSERT INTO trades (
              order_id, user_id, side, fill_amount, fill_price, timestamp
            ) VALUES (?1, ?2, ?3, ?4, ?5, ?6);
          |}
        in
        
        let tstmt = prepare db insert_trade_sql in
        ignore (Sqlite3.bind tstmt 1 (TEXT order_id));
        ignore (Sqlite3.bind tstmt 2 (INT  (Int64.of_int user_id_int)));
        ignore (Sqlite3.bind tstmt 3 (TEXT side_str));
        ignore (Sqlite3.bind tstmt 4 (INT  (Int64.of_int filled_quantity)));
        ignore (Sqlite3.bind tstmt 5 (FLOAT fill_price));
        ignore (Sqlite3.bind tstmt 6 (TEXT  timestamp));
        
        let rc2 = Sqlite3.step tstmt in
        
        ignore (reset tstmt);
        ignore (finalize tstmt);
        
        if rc2 <> DONE then
          None
        else
          get_latest_order_row db order_id

  (* ------- Get Alive Function ------- *)
  
  let get_alive_ack db ~order_id = get_latest_order_row db order_id


  (* ------- Get History Function ------- *)

  let get_history db ~order_id =
    let sql =
      {|
        SELECT order_id, user_id, side,
               order_amount, fill_amount, alive, cancelled,
               price, timestamp, error_code
          FROM orders
        WHERE order_id = ?1
        ORDER BY timestamp ASC;
      |}
    in
    
    let stmt = prepare db sql in
    
    ignore (Sqlite3.bind stmt 1 (TEXT order_id));
    
    let rec loop acc =
      match step stmt with
      | ROW ->
        let ack = row_to_alive_ack stmt in
        loop (ack :: acc)
      | DONE -> List.rev acc
      | rc -> failwith ("get_history: " ^ Sqlite3.Rc.to_string rc)
    in
    let res = loop [] in
    
    ignore (Sqlite3.reset stmt);
    ignore (Sqlite3.finalize stmt);
    
    res

  (* ------- Reset tables function ------- *)

  let reset_tables db =
    ignore (Sqlite3.exec db "DROP TABLE IF EXISTS orders;");
    ignore (Sqlite3.exec db "DROP TABLE IF EXISTS trades;");
    ignore (Sqlite3.exec db "DROP TABLE IF EXISTS book_snapshots;");

    let create_orders =
      {|
        CREATE TABLE orders (
          order_id      TEXT      NOT NULL,
          user_id       INTEGER   NOT NULL,
          side          TEXT      NOT NULL,
          order_amount  INTEGER   NOT NULL,
          fill_amount   INTEGER   NOT NULL,
          alive         INTEGER   NOT NULL,
          cancelled     INTEGER   NOT NULL,
          price         REAL      NOT NULL,
          timestamp     TEXT      NOT NULL,
          error_code    INTEGER   NOT NULL,
          PRIMARY KEY (order_id, timestamp)
        );
      |}
    in
    if Sqlite3.exec db create_orders <> Sqlite3.Rc.OK then
      failwith "reset_tables: cannot create orders";

    let create_trades =
      {|
        CREATE TABLE trades (
          trade_id     INTEGER   PRIMARY KEY AUTOINCREMENT,
          order_id     TEXT      NOT NULL,
          user_id      INTEGER   NOT NULL,
          side         TEXT      NOT NULL,
          fill_amount  INTEGER   NOT NULL,
          fill_price   REAL      NOT NULL,
          timestamp    TEXT      NOT NULL
        );
      |}
    in
    if Sqlite3.exec db create_trades <> Sqlite3.Rc.OK then
      failwith "reset_tables: cannot create trades";
    ignore (Sqlite3.exec db "CREATE INDEX idx_trades_ts ON trades(timestamp);");

    let create_snapshots =
      {|
        CREATE TABLE book_snapshots (
          snapshot_id   INTEGER   PRIMARY KEY AUTOINCREMENT,
          timestamp     TEXT      NOT NULL,
          best_bid      REAL      NOT NULL,
          best_bid_size INTEGER   NOT NULL,
          best_ask      REAL      NOT NULL,
          best_ask_size INTEGER   NOT NULL
        );
      |}
    in
    if Sqlite3.exec db create_snapshots <> Sqlite3.Rc.OK then
      failwith "reset_tables: cannot create book_snapshots";
    ignore (Sqlite3.exec db "CREATE INDEX idx_book_snapshots_ts ON book_snapshots(timestamp);")

  (* ------- Interval function ------- *)

  let get_interval db ~start_ts ~end_ts ~granularity_sec ~max_points =
    let start_unix = (iso8601_to_unix start_ts) in
    let end_unix   = (iso8601_to_unix end_ts) in

    if end_unix <= start_unix then []
    else
      let span_sec    = end_unix - start_unix in
      let all_buckets = span_sec / granularity_sec in
      let num_buckets =
        if all_buckets > max_points then max_points else all_buckets
      in

      let vol_sql =
        {|
          SELECT COALESCE(SUM(fill_amount), 0)
            FROM trades
          WHERE timestamp >= ?1 AND timestamp < ?2;
        |}
      in
      let stmt_vol = Sqlite3.prepare db vol_sql in

      let high_bid_sql =
        {|
          SELECT COALESCE(MAX(best_bid), 0.0)
            FROM book_snapshots
          WHERE timestamp >= ?1 AND timestamp < ?2;
        |}
      in
      let stmt_high_bid = Sqlite3.prepare db high_bid_sql in

      let low_ask_sql =
        {|
          SELECT COALESCE(MIN(best_ask), 0.0)
            FROM book_snapshots
          WHERE timestamp >= ?1 AND timestamp < ?2;
        |}
      in
      let stmt_low_ask = Sqlite3.prepare db low_ask_sql in

      let last_price_sql =
        {|
          SELECT fill_price
            FROM trades
          WHERE timestamp >= ?1 AND timestamp < ?2
          ORDER BY timestamp DESC
          LIMIT 1;
        |}
      in
      
      let stmt_last_price = Sqlite3.prepare db last_price_sql in

      (* 3) Build each bucket *)
      let rec build i acc =
        if i >= num_buckets then
          List.rev acc
        else
          let bs_unix = start_unix + (i * granularity_sec) in
          let be_unix = bs_unix + granularity_sec in
          let bs = unix_to_iso8601 (float_of_int bs_unix) in
          let be = unix_to_iso8601 (float_of_int be_unix) in

          (* a) total_volume *)
          ignore (Sqlite3.reset stmt_vol);
          ignore (Sqlite3.bind stmt_vol 1 (Sqlite3.Data.TEXT bs));
          ignore (Sqlite3.bind stmt_vol 2 (Sqlite3.Data.TEXT be));
          let total_volume =
            match Sqlite3.step stmt_vol with
            | Sqlite3.Rc.ROW ->
              (match Sqlite3.column stmt_vol 0 with
               | Sqlite3.Data.INT i   -> Int64.to_int i
               | Sqlite3.Data.FLOAT f -> int_of_float f
               | _ -> 0)
            | Sqlite3.Rc.DONE -> 0
            | rc -> failwith ("vol query error: " ^ Sqlite3.Rc.to_string rc)
          in

          (* b) highest_bid *)
          ignore (Sqlite3.reset stmt_high_bid);
          ignore (Sqlite3.bind stmt_high_bid 1 (Sqlite3.Data.TEXT bs));
          ignore (Sqlite3.bind stmt_high_bid 2 (Sqlite3.Data.TEXT be));
          let highest_bid =
            match Sqlite3.step stmt_high_bid with
            | Sqlite3.Rc.ROW ->
              (match Sqlite3.column stmt_high_bid 0 with
               | Sqlite3.Data.FLOAT f -> f
               | Sqlite3.Data.INT i   -> Int64.to_float i
               | _ -> 0.0)
            | Sqlite3.Rc.DONE -> 0.0
            | rc -> failwith ("high_bid query error: " ^ Sqlite3.Rc.to_string rc)
          in

          (* c) lowest_ask *)
          ignore (Sqlite3.reset stmt_low_ask);
          ignore (Sqlite3.bind stmt_low_ask 1 (Sqlite3.Data.TEXT bs));
          ignore (Sqlite3.bind stmt_low_ask 2 (Sqlite3.Data.TEXT be));
          let lowest_ask =
            match Sqlite3.step stmt_low_ask with
            | Sqlite3.Rc.ROW ->
              (match Sqlite3.column stmt_low_ask 0 with
               | Sqlite3.Data.FLOAT f -> f
               | Sqlite3.Data.INT i   -> Int64.to_float i
               | _ -> 0.0)
            | Sqlite3.Rc.DONE -> 0.0
            | rc -> failwith ("low_ask query error: " ^ Sqlite3.Rc.to_string rc)
          in

          (* d) last_trade_price *)
          ignore (Sqlite3.reset stmt_last_price);
          ignore (Sqlite3.bind stmt_last_price 1 (Sqlite3.Data.TEXT bs));
          ignore (Sqlite3.bind stmt_last_price 2 (Sqlite3.Data.TEXT be));
          let last_trade_price =
            match Sqlite3.step stmt_last_price with
            | Sqlite3.Rc.ROW ->
              (match Sqlite3.column stmt_last_price 0 with
               | Sqlite3.Data.FLOAT f -> f
               | Sqlite3.Data.INT i   -> Int64.to_float i
               | _ -> 0.0)
            | Sqlite3.Rc.DONE -> 0.0
            | rc -> failwith ("last_price query error: " ^ Sqlite3.Rc.to_string rc)
          in

          let bucket = {
            bucket_start     = bs;
            bucket_end       = be;
            total_volume     = total_volume;
            highest_bid      = highest_bid;
            lowest_ask       = lowest_ask;
            last_trade_price = last_trade_price;
          } in
          build (i + 1) (bucket :: acc)
      in

      (* 4) Finalize statements *)
      let result = build 0 [] in
      ignore (Sqlite3.finalize stmt_vol);
      ignore (Sqlite3.finalize stmt_high_bid);
      ignore (Sqlite3.finalize stmt_low_ask);
      ignore (Sqlite3.finalize stmt_last_price);
      result
end
