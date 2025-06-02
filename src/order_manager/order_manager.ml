open Types_lib.Types
open Wallet_store_lib
open Sqlite3

module type ORDER_MANAGER = sig
  val submit_order    : order             -> submitAck
  val cancel_order    : cancelReq         -> cancelAck
  val get_wallet      : orderId           -> walletAck
  val order_info     : orderId           -> aliveAck
  val get_market_data : marketDataRequest -> marketDataAck
  val register_user   : userId            -> int option
  val get_new_id      : unit              -> userId
end

module ORDER_MANAGER_impl (W : Wallet_store.WALLET_STORE) : ORDER_MANAGER = struct

  let get_db_path () : string =
    let src_dir = Filename.dirname __FILE__ in
    Filename.concat src_dir "/../db/data.db"
  
  let a_count = Atomic.make 0
(* LogBook functions *)
  
  let submit_order (order : order) : submitAck =
    (* synchronously print to stdout, then return a resolved promise *)
    Printf.printf "🔔 [mock] submit_order: %s\n%!"
      (show_order order);
    let ack : submitAck =
      {
        order_id = order.id;
        timestamp = order.timestamp;
        status = "REJECTED";
        error_code = 0;
      }
    in
    ack
      
  let cancel_order (_req: cancelReq) : cancelAck =
    failwith "todo"

  let order_info (_user_id : orderId) : aliveAck =
    failwith "todo"

  let get_market_data (_req : marketDataRequest) : marketDataAck =
    failwith "todo"

  (* Wallet functions *)

  let register_user (_uid : userId) =
    failwith "todo"

  let get_wallet (user_id : userId) : walletAck =
    let db = db_open (get_db_path ()) in
    let t = W.get_wallet db user_id in
    let _ = db_close db in

    match t with
    | Some v ->
      {
        user_id = user_id;
        balance = v;
        error_code = 20;
      }
    | None ->
      {
        user_id = "";
        balance = 0.0;
        error_code = 404;
      }

  

  let get_new_id () : userId =
    string_of_int (Atomic.get a_count)

end
