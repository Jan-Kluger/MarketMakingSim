open Types_lib.Types

module type ORDER_MANAGER = sig
  val submit_order    : order             -> submitAck
  val cancel_order    : cancelReq         -> cancelAck
  val get_wallet      : orderId           -> walletAck
  val order_alive     : orderId           -> aliveAck
  val get_market_data : marketDataRequest -> marketDataAck
end

module ORDER_MANAGER_impl : ORDER_MANAGER
