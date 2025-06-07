[@@@ warning "-33"]

open Server_lib
open Sqlite3
open Types_lib.Types
    
module WS = Wallet_store.WALLET_STORE_impl
module LB = Log_book.Log_book
module OB = Order_book.Make (LB) (WS)
module OM = Order_manager.Order_manager_impl (LB) (WS) (OB)
module G = Server.Gateway(OM)

let get_db_path () : string =
  let src_dir = Filename.dirname __FILE__ in
  Filename.concat src_dir "/../db/data.db"

(* let print_table (db : db) (table_name : string) : unit = *)
(*   let sql = Printf.sprintf "SELECT * FROM %s;" table_name in *)
(*   let cb row headers = *)
(*     Array.iteri (fun i cell -> *)
(*       let col = headers.(i) in *)
(*       let v = match cell with Some s -> s | None -> "NULL" in *)
(*       print_endline (col ^ " : " ^ v); *)
(*     ) row; *)
(*     print_endline ""; *)
(*     () *)
(*   in *)
(*   let rc = exec ~cb db sql in *)
(*   if rc <> Rc.OK then *)
(*     failwith ("print_table failed: " ^ Rc.to_string rc) *)

let () =
  let db = db_open (get_db_path ()) in

  WS.reset_table db;
  LB.reset_tables db;  


  G.start 8080;

  let _ = db_close db in

  
  () 
