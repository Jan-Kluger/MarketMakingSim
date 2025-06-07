open Types_lib.Types
open Sqlite3

module type WALLET_STORE = sig
  (** [get_wallet db uid]  
      Retrieve the current balance for [uid], or [None] if not found. *)
  val get_wallet     : db -> userId -> float option

  (** [deposit_funds db uid amount]  
      Add [amount] to [uid]’s balance (no-op if negative).
      Returns the new balance or [None] if [uid] doesn’t exist. *)
  val deposit_funds  : db -> userId -> float -> float option

  (** [withdraw_funds db uid amount]  
      Subtract [amount] from [uid]’s balance (no-op if negative).
      Returns the new balance or [None] if [uid] doesn’t exist. *)
  val withdraw_funds : db -> userId -> float -> float option

  (** [register_user db uid]  
      Create a new wallet for [uid] with zero balance.
      Returns [true] on success or [false] if [uid] already existed. *)
  val register_user  : db -> userId -> bool

  (** [reset_table db]  
      Drop and recreate the wallets table for fresh tests. *)
  val reset_table    : db -> unit
end


module WALLET_STORE_impl : WALLET_STORE = struct

  let get_wallet (db : db) (uid : userId) : float option =
    let stmt = prepare db
      "SELECT balance FROM wallets WHERE user_id = ?1;"
    in
    ignore (bind stmt 1 (Data.INT (Int64.of_string uid)));
    let result =
      match step stmt with
      | Rc.ROW ->
        let bal_data = column stmt 0 in
        let balance =
          match bal_data with
          | Data.FLOAT f -> f
          | Data.INT i   -> Int64.to_float i
          | _            -> 0.0
        in
        Some balance
    | Rc.DONE ->
        None
    | rc ->
        failwith ("get_balance SQL error: " ^ Rc.to_string rc)
  in
  ignore (reset stmt);
  ignore (finalize stmt);
  result

  let deposit_funds (db : db) (uid : userId) (amount : float) : float option =
    let amt = if amount < 0.0 then 0.0 else amount in
    match get_wallet db uid with
    | None -> None
    | Some bal_old ->
        let new_bal = bal_old +. amt in
        let stmt = prepare db
          "UPDATE wallets SET balance = ?1 WHERE user_id = ?2;"
        in
        ignore (bind stmt 1 (Data.FLOAT new_bal));
        ignore (bind stmt 2 (Data.INT (Int64.of_string uid)));
        (match step stmt with
         | Rc.DONE -> ()
         | rc -> failwith ("deposit_funds error: " ^ Rc.to_string rc));
        ignore (reset stmt);
        ignore (finalize stmt);
        Some new_bal

  let withdraw_funds (db : db) (uid : userId) (amount : float) : float option =
    let amt = if amount < 0.0 then 0.0 else amount in
    match get_wallet db uid with
    | None -> None
    | Some bal_old ->
        let new_bal = bal_old -. amt in
        let stmt = prepare db
          "UPDATE wallets SET balance = ?1 WHERE user_id = ?2;"
        in
        ignore (bind stmt 1 (Data.FLOAT new_bal));
        ignore (bind stmt 2 (Data.INT (Int64.of_string uid)));
        (match step stmt with
         | Rc.DONE -> ()
         | rc -> failwith ("withdraw_funds error: " ^ Rc.to_string rc));
        ignore (reset stmt);
        ignore (finalize stmt);
        Some new_bal

  let register_user (db : db) (uid : userId) : bool =
    (* Check existence *)
    let stmt_check = prepare db
      "SELECT 1 FROM wallets WHERE user_id = ?1 LIMIT 1;"
    in
    ignore (bind stmt_check 1 (Data.INT (Int64.of_string uid)));
    let exists =
      match step stmt_check with
      | Rc.ROW -> true
      | Rc.DONE -> false
      | rc -> failwith ("register_user check error: " ^ Rc.to_string rc)
    in
    ignore (reset stmt_check);
    ignore (finalize stmt_check);
    if exists then false
    else begin
      let stmt_ins = prepare db
        "INSERT INTO wallets (user_id,balance) VALUES (?1,?2);"
      in
      ignore (bind stmt_ins 1 (Data.INT (Int64.of_string uid)));
      ignore (bind stmt_ins 2 (Data.FLOAT 0.0));
      (match step stmt_ins with
       | Rc.DONE -> ()
       | rc -> failwith ("register_user insert error: " ^ Rc.to_string rc));
      ignore (reset stmt_ins);
      ignore (finalize stmt_ins);
      true
    end
  
  let reset_table (db : db) : unit =
    let _ = exec db "DROP TABLE IF EXISTS wallets;" in
    let create_sql ="
      CREATE TABLE wallets (
      user_id       INTEGER PRIMARY KEY,
      balance  DOUBLE
      );"
    in
    let rc = exec db create_sql in
    if rc <> Rc.OK then
      failwith ("reset_wallets_table failed: " ^ Rc.to_string rc)
end
