open Grpc_lwt
open Types_lib.Types

let gen_uuid () : string =
  let buf = Bytes.init 16 (fun _ -> Char.chr (Random.int 256)) in
  Uuidm.v4 buf |> Uuidm.to_string

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
  let side =
      match request.side with
        | "B" -> Buy
        | "S" -> Sell
        | _ -> Invalid
  in
  let order = {
    id = gen_uuid ();
    user_id  = request.user_id;
    side = side;
    price = if request.price >= 0.0 then (Some request.price) else None;
    quantity = request.quantity;
    timestamp = timestamp ();
  }
  in
  let msg = OM.submit_order order in
  
  let reply = Exchange.SubmitOrder.Response.make
      ~order_id:msg.order_id
      ~timestamp:msg.timestamp
      ~status:msg.status
      ~error_code:msg.error_code ()
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
      ~user_id:    om_r.user_id
      ~balance:    om_r.balance
      ~error_code: om_r.error_code ()
  in
  Lwt.return (Grpc.Status.(v OK), Some (encode reply |> Writer.contents))

let getNewAccount _ =
  log "getWallet";
  let open Ocaml_protoc_plugin in
  let open Exchange.Mypackage in
  let _, encode = Service.make_service_functions Exchange.getWallet in
  let om_r = OM.get_new_id () in
  let reply = Exchange.GetWallet.Response.make
      ~user_id: om_r ()
  in
  Lwt.return (Grpc.Status.(v OK), Some (encode reply |> Writer.contents))


let getBook buffer =
  log "getWallet";
  let open Ocaml_protoc_plugin in
  let open Exchange.Mypackage in
  let decode, encode = Service.make_service_functions Exchange.getBook in
  let request =
    Reader.create buffer |> decode |> function
    | Ok v -> v
    | Error e ->
        failwith
          (Printf.sprintf "Could not decode request: %s" (Result.show_error e))
  in
  let bids, asks = OM.get_book request in
  let bids_pqts = List.fold_left (fun acc (p,q) ->
      let t = PriceQty.make ~price:p  ~quantity:q () in
      t :: acc
    ) [] bids in

  let asks_pqts = List.fold_left (fun acc (p,q) ->
      let t = PriceQty.make ~price:p  ~quantity:q () in
      t :: acc
    ) [] asks in

  let reply = Exchange.GetBook.Response.make
      ~bids:bids_pqts
      ~asks:asks_pqts
      ()
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
  
  let msg =
    match rt with
    | Invalid -> []
    | _ -> begin
    let t : marketDataRequest =
    {
      req_type = rt;
      time_from = request.time_from;
      time_to = request.time_to;
    }
    in
    OM.get_market_data t
  end in

  let trades = List.fold_left (fun acc (timestamp, aggressor_id, passive_id, price, quantity) ->
      (TradeData.make ~timestamp ~aggressor_id ~passive_id ~price ~quantity ())  :: acc ) [] msg
      in
  
    let reply = Exchange.GetMarketData.Response.make
        ~trades
         () in
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
      ~order_id:        msg.order_id
      ~user_id:         msg.user_id
      ~order_quantity:  msg.order_quantity
      ~amount_canceled: msg.amount_canceled ()
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
  let msg = OM.order_info request in
  let reply = Exchange.OrderAlive.Response.make
      ~alive:        msg.alive
      ~cancelled:    msg.cancelled
      ~side:         (Char.escaped (Types_lib.Types.side_to_char msg.side))
      ~order_amount: msg.order_amount
      ~fill_amount:  msg.fill_amount
      ~timestamp:    msg.timestamp
      ~error_code:   msg.error_code
      () in
    
  Lwt.return (Grpc.Status.(v OK), Some (encode reply |> Writer.contents))

let exchange_service =
  Server.Service.(
    v ()
    |> add_rpc ~name:"SubmitOrder"   ~rpc:(Unary (submitOrder))
    |> add_rpc ~name:"GetWallet"     ~rpc:(Unary (getWallet))
    |> add_rpc ~name:"GetBook"       ~rpc:(Unary (getBook))
    |> add_rpc ~name:"GetMarketData" ~rpc:(Unary (getMarketData))
    |> add_rpc ~name:"CancelOrder"   ~rpc:(Unary (cancelOrder))
    |> add_rpc ~name:"GetNewAccount" ~rpc:(Unary (getNewAccount))
    |> add_rpc ~name:"OrderAlive"    ~rpc:(Unary (orderAlive))
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
      print_endline ("\nListening @ port " ^ string_of_int port) );

  let forever, _ = Lwt.wait () in
  Lwt_main.run forever
end
