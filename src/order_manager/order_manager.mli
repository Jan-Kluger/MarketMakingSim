open Types_lib.Types

module type ORDER_MANAGER = sig
    val submit_order  : order          -> unit Lwt.t
    val cancel_order  : user_id:int
                      -> order_id:int -> unit Lwt.t
    val get_wallet    : user_id:int   -> (float * float) option Lwt.t
    val get_order_book: unit          -> order list * order list
end

module ORDER_MANAGER_impl : ORDER_MANAGER