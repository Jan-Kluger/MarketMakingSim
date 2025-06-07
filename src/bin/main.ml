[@@@ warning "-33"]

open Server_lib
open Sqlite3
open Types_lib.Types
    
module WS = Wallet_store.WALLET_STORE_impl
module OM = Order_manager.ORDER_MANAGER_impl(WS)
module G = Server.Gateway(OM)

let get_db_path () : string =
  let src_dir = Filename.dirname __FILE__ in
  Filename.concat src_dir "/../db/data.db"

let print_table (db : db) (table_name : string) : unit =
  let sql = Printf.sprintf "SELECT * FROM %s;" table_name in
  let cb row headers =
    Array.iteri (fun i cell ->
      let col = headers.(i) in
      let v = match cell with Some s -> s | None -> "NULL" in
      print_endline (col ^ " : " ^ v);
    ) row;
    print_endline "";
    ()
  in
  let rc = exec ~cb db sql in
  if rc <> Rc.OK then
    failwith ("print_table failed: " ^ Rc.to_string rc)

let () =
  let db = db_open (get_db_path ()) in

  WS.reset_table db;
  
  (* 3. Print initial state of relevant tables *)
  print_table db "wallets";
  print_table db "orders";
  print_table db "trades";

  (* 4. Register a user "0" and deposit some funds so we can submit an order *)
  let _ = WS.register_user db "0" in
  let _ = WS.deposit_funds db "0" 100.0 in

  print_endline "*** After registering user \"0\" and depositing 100.0 ***\n";
  print_table db "wallets";



  print_table db "wallets";
  print_table db "orders";
  print_table db "trades";


  let _ = db_close db in

  G.start 8080;
  
  () 
