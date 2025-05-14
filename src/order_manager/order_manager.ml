open Types_lib.Types
open Wallet_store_lib

module type ORDER_MANAGER = sig
  val submit_order    : order             -> submitAck
  val cancel_order    : cancelReq         -> cancelAck
  val get_wallet      : orderId           -> walletAck
  val order_alive     : orderId           -> aliveAck
  val get_market_data : marketDataRequest -> marketDataAck
  val register_user   : userId            -> int option
end

module ORDER_MANAGER_impl (W : Wallet_store.WALLET_STORE) : ORDER_MANAGER = struct

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

  let order_alive (_user_id : orderId) : aliveAck =
    failwith "todo"

  let get_market_data (_req : marketDataRequest) : marketDataAck =
    failwith "todo"

  (* Wallet functions *)

  let register_user (_uid : userId) =
    
    failwith "todo"

  let get_wallet (user_id : userId) : walletAck =
    let _u = user_id in
    let _t = W.get_wallet user_id in
    failwith "todo"

end
