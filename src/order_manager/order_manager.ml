open Types_lib.Types

module type ORDER_MANAGER = sig
  val submit_order  : order          -> unit Lwt.t
  val cancel_order  : user_id:int
                    -> order_id:int -> unit Lwt.t
  val get_wallet    : user_id:int   -> (float * float) option Lwt.t
  val get_order_book: unit          -> order list * order list
end

module ORDER_MANAGER_impl : ORDER_MANAGER = struct

  let submit_order (order : order) : unit Lwt.t =
    (* synchronously print to stdout, then return a resolved promise *)
    Printf.printf "🔔 [mock] submit_order: %s\n%!"
      (show_order order);
    Lwt.return_unit
      
  let cancel_order ~(user_id : int) ~(order_id : int) : unit Lwt.t =
    let _u = user_id in
    let _o = order_id in
    failwith "todo"

  let get_wallet ~(user_id : int) : (float * float) option Lwt.t =
    let _u = user_id in
    failwith "todo"

  let get_order_book (a : unit) : order list * order list =
    let _a = a in
    failwith "todo"

end