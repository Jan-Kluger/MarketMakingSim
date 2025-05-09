open Grpc_lwt
open Order_manager_lib
open Types_lib.Types

module Gateway (OM : Order_manager.ORDER_MANAGER) = struct

  let timestamp () =
    let tm = Unix.localtime (Unix.time ()) in
    Printf.sprintf
      "%04d-%02d-%02dT%02d:%02d:%02d"
      (1900 + tm.Unix.tm_year)
      (tm.Unix.tm_mon + 1)
      tm.Unix.tm_mday
      tm.Unix.tm_hour
      tm.Unix.tm_min
      tm.Unix.tm_sec
  
let log rpcc_name =
  let ts = timestamp () in
  Printf.printf "[LOG] %s called at %s\n%!" rpcc_name ts;
  ()
    
let submitOrder buffer =
  log "submitOrder";
  let open Ocaml_protoc_plugin in
  let open Exchange.Mypackage in
  let decode, encode = Service.make_service_functions Exchange.submitOrder in
  let request =
    Reader.create buffer |> decode |> function
    | Ok v -> v
    | Error e ->
        failwith
          (Printf.sprintf "Could not decode request: %s" (Result.show_error e))
  in

  let to_ack (v: Order.t) : submitAck =
    let side =
      match v.side with
        | "B" -> Buy
        | "S" -> Sell
        | _ -> Invalid
      in          
        
    let recieved_order : submitAck =
      match side with
      | Invalid -> begin
        let ack : submitAck =
        {
          order_id = "0";
          timestamp = "0";
          status = "REJECTED";
          error_code = 500;
        }
        in
        ack
       end
      | _ -> begin
        let r = {
          id = v.id;
          user_id  = v.user_id;
          side = side;
          price = Some v.price ;
          quantity = v.quantity;
          timestamp = timestamp ();
        }
        in
        (OM.submit_order r)
        end
      in
      recieved_order
   in

  let om_r = to_ack request in
     
  
  let reply = Exchange.SubmitOrder.Response.make
      ~order_id:om_r.order_id
      ~timestamp:om_r.timestamp
      ~status:om_r.status
      ~error_code:om_r.error_code ()
   in
  Lwt.return (Grpc.Status.(v OK), Some (encode reply |> Writer.contents))

let getWallet buffer =
  log "getWallet";
  let open Ocaml_protoc_plugin in
  let open Exchange.Mypackage in
  let decode, encode = Service.make_service_functions Exchange.getWallet in
  let request =
    Reader.create buffer |> decode |> function
    | Ok v -> v
    | Error e ->
        failwith
          (Printf.sprintf "Could not decode request: %s" (Result.show_error e))
  in
  let om_r = OM.get_wallet request in
  let reply = Exchange.GetWallet.Response.make
      ~user_id:om_r.user_id
      ~balance:om_r.balance
      ~error_code:om_r.error_code ()
  in
  Lwt.return (Grpc.Status.(v OK), Some (encode reply |> Writer.contents))

let getMarketData buffer =
  log "getMarketData";
  let open Ocaml_protoc_plugin in
  let open Exchange.Mypackage in
  let decode, encode = Service.make_service_functions Exchange.getMarketData in
  let request =
    Reader.create buffer |> decode |> function
    | Ok v -> v
    | Error e ->
        failwith
          (Printf.sprintf "Could not decode request: %s" (Result.show_error e))
  in
  let rt =
    match request.data_type with
    | "V" -> Volume
    | "P" -> Price
    | _ -> Invalid
  in
  
  let msg : marketDataAck =
    match rt with
    | Invalid -> {value = 0.0; error_code = 50;}
    | _ -> begin
    let t : marketDataRequest =
    {
      req_type = rt;
      time_from = request.time_from;
      time_to = request.time_to;
    }
    in
    OM.get_market_data t
    end
    in
    let reply = Exchange.GetMarketData.Response.make
        ~value:msg.value
        ~error_code:msg.error_code () in
  Lwt.return (Grpc.Status.(v OK), Some (encode reply |> Writer.contents))
  

let cancelOrder buffer =
  log "cancelOrder";
  let open Ocaml_protoc_plugin in
  let open Exchange.Mypackage in
  let decode, encode = Service.make_service_functions Exchange.cancelOrder in
  let request =
    Reader.create buffer |> decode |> function
    | Ok v -> v
    | Error e ->
        failwith
          (Printf.sprintf "Could not decode request: %s" (Result.show_error e))
  in
  let req : cancelReq =
    {
      order_id = request.order_id;
      user_id = request.user_id;
    }
    in
    let msg = OM.cancel_order req in
  let reply = Exchange.CancelOrder.Response.make
      ~order_id:msg.order_id
      ~user_id:msg.user_id
      ~order_quantity:msg.order_quantity
      ~amount_canceled:msg.amount_canceled ()
  in
  Lwt.return (Grpc.Status.(v OK), Some (encode reply |> Writer.contents))

let orderAlive buffer =
  log "orderAlive";
  let open Ocaml_protoc_plugin in
  let open Exchange.Mypackage in
  let decode, encode = Service.make_service_functions Exchange.orderAlive in
  let request =
    Reader.create buffer |> decode |> function
    | Ok v -> v
    | Error e ->
        failwith
          (Printf.sprintf "Could not decode request: %s" (Result.show_error e))
  in
  let msg = OM.order_alive request in
  let reply = Exchange.OrderAlive.Response.make
      ~alive:msg.alive
      ~error_code:msg.error_code () in
  Lwt.return (Grpc.Status.(v OK), Some (encode reply |> Writer.contents))

let exchange_service =
  Server.Service.(
    v ()
    |> add_rpc ~name:"SubmitOrder" ~rpc:(Unary (submitOrder))
    |> add_rpc ~name:"GetWallet" ~rpc:(Unary (getWallet))
    |> add_rpc ~name:"GetMarketData" ~rpc:(Unary (getMarketData))
    |> add_rpc ~name:"CancelOrder" ~rpc:(Unary (cancelOrder))
    |> add_rpc ~name:"OrderAlive" ~rpc:(Unary (orderAlive))
    |> handle_request)

let server =
  Server.(
    v () |> add_service ~name:"mypackage.Exchange" ~service:exchange_service)

let start iport =
  let open Lwt.Syntax in
  let port = iport in
  let listen_address = Unix.(ADDR_INET (inet_addr_loopback, port)) in
  Lwt.async (fun () ->
      let server =
        H2_lwt_unix.Server.create_connection_handler ?config:None
          ~request_handler:(fun _ reqd -> Server.handle_request server reqd)
          ~error_handler:(fun _ ?request:_ _ _ ->
            print_endline "an error occurred")
      in
      let+ _server =
        Lwt_io.establish_server_with_client_socket listen_address server
      in
      print_endline ("Listening @ port " ^ string_of_int port) );

  let forever, _ = Lwt.wait () in
  Lwt_main.run forever
end
