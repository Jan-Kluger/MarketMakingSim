open Order_manager_lib
open Gateway_lib

module OM = Order_manager.ORDER_MANAGER_impl
module G = Server.Gateway(OM)

let () =
  G.start 8080;
