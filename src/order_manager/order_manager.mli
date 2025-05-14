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

module ORDER_MANAGER_impl (_ : Wallet_store.WALLET_STORE) : ORDER_MANAGER
