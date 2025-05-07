open Types_lib.Types

module type ORDER_MANAGER = sig
  val submit_order    : order             -> submitAck
  val cancel_order    : cancelReq         -> cancelAck
  val get_wallet      : orderId           -> walletAck
  val order_alive     : orderId           -> aliveAck
  val get_market_data : marketDataRequest -> marketDataAck                                
end

module ORDER_MANAGER_impl : ORDER_MANAGER = struct

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

  let get_wallet (user_id : orderId) : walletAck =
    let _u = user_id in
    failwith "todo"

  let order_alive (_user_id : orderId) : aliveAck =
    failwith "todo"

  let get_market_data (_req : marketDataRequest) : marketDataAck =
    failwith "todo"

end
