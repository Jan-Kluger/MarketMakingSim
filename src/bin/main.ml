open Sqlite3
open Order_manager_lib
open Gateway_lib
open Wallet_store_lib

module WS = Wallet_store.WALLET_STORE_impl
module OM = Order_manager.ORDER_MANAGER_impl(WS)
module G = Server.Gateway(OM)

let get_db_path () : string =
  let src_dir = Filename.dirname __FILE__ in
  Filename.concat src_dir "/../db/data.db"


let () =
  let db = db_open (get_db_path ()) in
  
  G.start 8080;
  
  let _ = db_close db in
  ()
