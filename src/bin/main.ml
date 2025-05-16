open Order_manager_lib
open Gateway_lib
open Wallet_store_lib
open Sqlite3

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

  (* Wallet_store.WALLET_STORE_impl.reset_table db; *)
  (* print_table db "wallets"; *)
  
  (* let _ = Wallet_store.WALLET_STORE_impl.register_user db "0" in *)
  (* print_table db "wallets"; *)

  (* let _ = Wallet_store.WALLET_STORE_impl.deposit_funds db "0" 10.0 in *)
  (* print_table db "wallets"; *)

  (* let _ = Wallet_store.WALLET_STORE_impl.withdraw_funds db "0" 10.0 in *)
  (* print_table db "wallets"; *)

  let _ = db_close db in

  G.start 8080;
  
  () 
