open Grpc_lwt
open Order_manager_lib

module Gateway (OM : Order_manager.ORDER_MANAGER) = struct
let log rpcc_name =
  let timestamp () =
    let tm = Unix.localtime (Unix.time ()) in
    Printf.sprintf
      "%04d-%02d-%02dT%02d:%02d:%02d"
      (1900 + tm.Unix.tm_year)
      (tm.Unix.tm_mon + 1)
      tm.Unix.tm_mday
      tm.Unix.tm_hour
      tm.Unix.tm_min
      tm.Unix.tm_sec in
  let ts = timestamp () in
  Printf.printf "[LOG] %s called at %s\n%!" rpcc_name ts;
  ()
    
let submitOrder buffer =
  log "submitOrder";
  let open Ocaml_protoc_plugin in
  let open Exchange.Mypackage in
  let decode, encode = Service.make_service_functions Exchange.submitOrder in
  let _request =
    Reader.create buffer |> decode |> function
    | Ok v -> v
    | Error e ->
        failwith
          (Printf.sprintf "Could not decode request: %s" (Result.show_error e))
  in
  let reply = Exchange.SubmitOrder.Response.make ~order_id:"1" ~timestamp:"00:00:00" ~status:"rejected" ~error_code:0 () in
  Lwt.return (Grpc.Status.(v OK), Some (encode reply |> Writer.contents))

let getWallet buffer =
  log "getWallet";
  let open Ocaml_protoc_plugin in
  let open Exchange.Mypackage in
  let decode, encode = Service.make_service_functions Exchange.getWallet in
  let _request =
    Reader.create buffer |> decode |> function
    | Ok v -> v
    | Error e ->
        failwith
          (Printf.sprintf "Could not decode request: %s" (Result.show_error e))
  in
  let reply = Exchange.GetWallet.Response.make ~user_id:"Bob" ~balance:0.1 () in
  Lwt.return (Grpc.Status.(v OK), Some (encode reply |> Writer.contents))

let getMarketData buffer =
  log "getMarketData";
  let open Ocaml_protoc_plugin in
  let open Exchange.Mypackage in
  let decode, encode = Service.make_service_functions Exchange.getMarketData in
  let _request =
    Reader.create buffer |> decode |> function
    | Ok v -> v
    | Error e ->
        failwith
          (Printf.sprintf "Could not decode request: %s" (Result.show_error e))
  in
  let reply = Exchange.GetMarketData.Response.make ~value:0.0 () in
  Lwt.return (Grpc.Status.(v OK), Some (encode reply |> Writer.contents))
  

let cancelOrder buffer =
  log "cancelOrder";
  let open Ocaml_protoc_plugin in
  let open Exchange.Mypackage in
  let decode, encode = Service.make_service_functions Exchange.cancelOrder in
  let _request =
    Reader.create buffer |> decode |> function
    | Ok v -> v
    | Error e ->
        failwith
          (Printf.sprintf "Could not decode request: %s" (Result.show_error e))
  in
  let reply = Exchange.CancelOrder.Response.make ~order_id:"1" ~user_id:"Bob" ~order_quantity:1 ~amount_canceled:1 () in
  Lwt.return (Grpc.Status.(v OK), Some (encode reply |> Writer.contents))

let orderAlive buffer =
  log "orderAlive";
  let open Ocaml_protoc_plugin in
  let open Exchange.Mypackage in
  let decode, encode = Service.make_service_functions Exchange.orderAlive in
  let _request =
    Reader.create buffer |> decode |> function
    | Ok v -> v
    | Error e ->
        failwith
          (Printf.sprintf "Could not decode request: %s" (Result.show_error e))
  in
  let reply = Exchange.OrderAlive.Response.make ~alive:true () in
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
