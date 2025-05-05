
(*
  Source: proto/exchange.proto
  Syntax: proto3
  Parameters:
    debug=false
    annot=''
    opens=[]
    int64_as_int=true
    int32_as_int=true
    fixed_as_int=false
    singleton_record=false
    prefix_output_with_package=false
*)
[@@@ocaml.alert "-protobuf"] (* Disable deprecation warnings for protobuf*)

(**/**)
module Runtime' = Ocaml_protoc_plugin [@@warning "-33"]
module Imported'modules = struct
end
(**/**)
module rec Exchange : sig
  module rec Side : sig
    type t =
      | BUY
      | SELL

    val name: unit -> string
    (** Fully qualified protobuf name of this enum *)

    (**/**)
    val to_int: t -> int
    val from_int: int -> t Runtime'.Result.t
    val from_int_exn: int -> t
    val to_string: t -> string
    val from_string_exn: string -> t
    (**/**)
  end
  and Order : sig
    type t = {
    id: int;
    user_id: int;
    side: Side.t;
    price: float;(** NaN -> market order *)
    quantity: int;
    }
    val make: ?id:int -> ?user_id:int -> ?side:Side.t -> ?price:float -> ?quantity:int -> unit -> t
    (** Helper function to generate a message using default values *)

    val to_proto: t -> Runtime'.Writer.t
    (** Serialize the message to binary format *)

    val from_proto: Runtime'.Reader.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from binary format *)

    val to_json: Runtime'.Json_options.t -> t -> Runtime'.Json.t
    (** Serialize to Json (compatible with Yojson.Basic.t) *)

    val from_json: Runtime'.Json.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from Json (compatible with Yojson.Basic.t) *)

    val name: unit -> string
    (** Fully qualified protobuf name of this message *)

    (**/**)
    type make_t = ?id:int -> ?user_id:int -> ?side:Side.t -> ?price:float -> ?quantity:int -> unit -> t
    val merge: t -> t -> t
    val to_proto': Runtime'.Writer.t -> t -> unit
    val from_proto_exn: Runtime'.Reader.t -> t
    val from_json_exn: Runtime'.Json.t -> t
    (**/**)
  end
  and SubmitReply : sig
    type t = (Trade.t list)
    val make: ?trades:Trade.t list -> unit -> t
    (** Helper function to generate a message using default values *)

    val to_proto: t -> Runtime'.Writer.t
    (** Serialize the message to binary format *)

    val from_proto: Runtime'.Reader.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from binary format *)

    val to_json: Runtime'.Json_options.t -> t -> Runtime'.Json.t
    (** Serialize to Json (compatible with Yojson.Basic.t) *)

    val from_json: Runtime'.Json.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from Json (compatible with Yojson.Basic.t) *)

    val name: unit -> string
    (** Fully qualified protobuf name of this message *)

    (**/**)
    type make_t = ?trades:Trade.t list -> unit -> t
    val merge: t -> t -> t
    val to_proto': Runtime'.Writer.t -> t -> unit
    val from_proto_exn: Runtime'.Reader.t -> t
    val from_json_exn: Runtime'.Json.t -> t
    (**/**)
  end
  and CancelReply : sig
    type t = (bool)
    val make: ?ok:bool -> unit -> t
    (** Helper function to generate a message using default values *)

    val to_proto: t -> Runtime'.Writer.t
    (** Serialize the message to binary format *)

    val from_proto: Runtime'.Reader.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from binary format *)

    val to_json: Runtime'.Json_options.t -> t -> Runtime'.Json.t
    (** Serialize to Json (compatible with Yojson.Basic.t) *)

    val from_json: Runtime'.Json.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from Json (compatible with Yojson.Basic.t) *)

    val name: unit -> string
    (** Fully qualified protobuf name of this message *)

    (**/**)
    type make_t = ?ok:bool -> unit -> t
    val merge: t -> t -> t
    val to_proto': Runtime'.Writer.t -> t -> unit
    val from_proto_exn: Runtime'.Reader.t -> t
    val from_json_exn: Runtime'.Json.t -> t
    (**/**)
  end
  and WalletReply : sig
    type t = {
    usd: float;
    asset: float;
    }
    val make: ?usd:float -> ?asset:float -> unit -> t
    (** Helper function to generate a message using default values *)

    val to_proto: t -> Runtime'.Writer.t
    (** Serialize the message to binary format *)

    val from_proto: Runtime'.Reader.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from binary format *)

    val to_json: Runtime'.Json_options.t -> t -> Runtime'.Json.t
    (** Serialize to Json (compatible with Yojson.Basic.t) *)

    val from_json: Runtime'.Json.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from Json (compatible with Yojson.Basic.t) *)

    val name: unit -> string
    (** Fully qualified protobuf name of this message *)

    (**/**)
    type make_t = ?usd:float -> ?asset:float -> unit -> t
    val merge: t -> t -> t
    val to_proto': Runtime'.Writer.t -> t -> unit
    val from_proto_exn: Runtime'.Reader.t -> t
    val from_json_exn: Runtime'.Json.t -> t
    (**/**)
  end
  and Trade : sig
    type t = {
    buy_id: int;
    sell_id: int;
    price: float;
    quantity: int;
    timestamp: float;
    }
    val make: ?buy_id:int -> ?sell_id:int -> ?price:float -> ?quantity:int -> ?timestamp:float -> unit -> t
    (** Helper function to generate a message using default values *)

    val to_proto: t -> Runtime'.Writer.t
    (** Serialize the message to binary format *)

    val from_proto: Runtime'.Reader.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from binary format *)

    val to_json: Runtime'.Json_options.t -> t -> Runtime'.Json.t
    (** Serialize to Json (compatible with Yojson.Basic.t) *)

    val from_json: Runtime'.Json.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from Json (compatible with Yojson.Basic.t) *)

    val name: unit -> string
    (** Fully qualified protobuf name of this message *)

    (**/**)
    type make_t = ?buy_id:int -> ?sell_id:int -> ?price:float -> ?quantity:int -> ?timestamp:float -> unit -> t
    val merge: t -> t -> t
    val to_proto': Runtime'.Writer.t -> t -> unit
    val from_proto_exn: Runtime'.Reader.t -> t
    val from_json_exn: Runtime'.Json.t -> t
    (**/**)
  end
  module Exchange : sig
    module SubmitOrder : sig
      include Runtime'.Service.Rpc with type Request.t = Order.t and type Response.t = SubmitReply.t
      module Request : Runtime'.Spec.Message with type t = Order.t and type make_t = Order.make_t
      (** Module alias for the request message for this method call *)

      module Response : Runtime'.Spec.Message with type t = SubmitReply.t and type make_t = SubmitReply.make_t
      (** Module alias for the response message for this method call *)

    end
    val submitOrder : (module Runtime'.Spec.Message with type t = Order.t) * (module Runtime'.Spec.Message with type t = SubmitReply.t)
    module CancelOrder : sig
      include Runtime'.Service.Rpc with type Request.t = Order.t and type Response.t = CancelReply.t
      module Request : Runtime'.Spec.Message with type t = Order.t and type make_t = Order.make_t
      (** Module alias for the request message for this method call *)

      module Response : Runtime'.Spec.Message with type t = CancelReply.t and type make_t = CancelReply.make_t
      (** Module alias for the response message for this method call *)

    end
    val cancelOrder : (module Runtime'.Spec.Message with type t = Order.t) * (module Runtime'.Spec.Message with type t = CancelReply.t)
    module GetWallet : sig
      include Runtime'.Service.Rpc with type Request.t = Order.t and type Response.t = WalletReply.t
      module Request : Runtime'.Spec.Message with type t = Order.t and type make_t = Order.make_t
      (** Module alias for the request message for this method call *)

      module Response : Runtime'.Spec.Message with type t = WalletReply.t and type make_t = WalletReply.make_t
      (** Module alias for the response message for this method call *)

    end
    val getWallet : (module Runtime'.Spec.Message with type t = Order.t) * (module Runtime'.Spec.Message with type t = WalletReply.t)
  end
end = struct
  module rec Side : sig
    type t =
      | BUY
      | SELL

    val name: unit -> string
    (** Fully qualified protobuf name of this enum *)

    (**/**)
    val to_int: t -> int
    val from_int: int -> t Runtime'.Result.t
    val from_int_exn: int -> t
    val to_string: t -> string
    val from_string_exn: string -> t
    (**/**)
  end = struct
    module This'_ = Side
    type t =
      | BUY
      | SELL

    let name () = ".exchange.Side"
    let to_int = function
      | BUY -> 0
      | SELL -> 1
    let from_int_exn = function
      | 0 -> BUY
      | 1 -> SELL
      | n -> Runtime'.Result.raise (`Unknown_enum_value n)
    let from_int e = Runtime'.Result.catch (fun () -> from_int_exn e)
    let to_string = function
      | BUY -> "BUY"
      | SELL -> "SELL"
    let from_string_exn = function
      | "BUY" -> BUY
      | "SELL" -> SELL
      | s -> Runtime'.Result.raise (`Unknown_enum_name s)

  end
  and Order : sig
    type t = {
    id: int;
    user_id: int;
    side: Side.t;
    price: float;(** NaN -> market order *)
    quantity: int;
    }
    val make: ?id:int -> ?user_id:int -> ?side:Side.t -> ?price:float -> ?quantity:int -> unit -> t
    (** Helper function to generate a message using default values *)

    val to_proto: t -> Runtime'.Writer.t
    (** Serialize the message to binary format *)

    val from_proto: Runtime'.Reader.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from binary format *)

    val to_json: Runtime'.Json_options.t -> t -> Runtime'.Json.t
    (** Serialize to Json (compatible with Yojson.Basic.t) *)

    val from_json: Runtime'.Json.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from Json (compatible with Yojson.Basic.t) *)

    val name: unit -> string
    (** Fully qualified protobuf name of this message *)

    (**/**)
    type make_t = ?id:int -> ?user_id:int -> ?side:Side.t -> ?price:float -> ?quantity:int -> unit -> t
    val merge: t -> t -> t
    val to_proto': Runtime'.Writer.t -> t -> unit
    val from_proto_exn: Runtime'.Reader.t -> t
    val from_json_exn: Runtime'.Json.t -> t
    (**/**)
  end = struct
    module This'_ = Order
    let name () = ".exchange.Order"
    type t = {
    id: int;
    user_id: int;
    side: Side.t;
    price: float;(** NaN -> market order *)
    quantity: int;
    }
    type make_t = ?id:int -> ?user_id:int -> ?side:Side.t -> ?price:float -> ?quantity:int -> unit -> t
    let make ?(id = 0) ?(user_id = 0) ?(side = Side.from_int_exn 0) ?(price = 0.) ?(quantity = 0) () = { id; user_id; side; price; quantity }
    let merge =
    let merge_id = Runtime'.Merge.merge Runtime'.Spec.( basic ((1, "id", "id"), uint64_int, (0)) ) in
    let merge_user_id = Runtime'.Merge.merge Runtime'.Spec.( basic ((2, "user_id", "userId"), uint64_int, (0)) ) in
    let merge_side = Runtime'.Merge.merge Runtime'.Spec.( basic ((3, "side", "side"), (enum (module Side)), (Side.from_int_exn 0)) ) in
    let merge_price = Runtime'.Merge.merge Runtime'.Spec.( basic ((4, "price", "price"), double, (0.)) ) in
    let merge_quantity = Runtime'.Merge.merge Runtime'.Spec.( basic ((5, "quantity", "quantity"), uint32_int, (0)) ) in
    fun t1 t2 -> {
    id = (merge_id t1.id t2.id);
    user_id = (merge_user_id t1.user_id t2.user_id);
    side = (merge_side t1.side t2.side);
    price = (merge_price t1.price t2.price);
    quantity = (merge_quantity t1.quantity t2.quantity);
     }
    let spec () = Runtime'.Spec.( basic ((1, "id", "id"), uint64_int, (0)) ^:: basic ((2, "user_id", "userId"), uint64_int, (0)) ^:: basic ((3, "side", "side"), (enum (module Side)), (Side.from_int_exn 0)) ^:: basic ((4, "price", "price"), double, (0.)) ^:: basic ((5, "quantity", "quantity"), uint32_int, (0)) ^:: nil )
    let to_proto' =
      let serialize = Runtime'.apply_lazy (fun () -> Runtime'.Serialize.serialize (spec ())) in
      fun writer { id; user_id; side; price; quantity } -> serialize writer id user_id side price quantity

    let to_proto t = let writer = Runtime'.Writer.init () in to_proto' writer t; writer
    let from_proto_exn =
      let constructor id user_id side price quantity = { id; user_id; side; price; quantity } in
      Runtime'.apply_lazy (fun () -> Runtime'.Deserialize.deserialize (spec ()) constructor)
    let from_proto writer = Runtime'.Result.catch (fun () -> from_proto_exn writer)
    let to_json options =
      let serialize = Runtime'.Serialize_json.serialize ~message_name:(name ()) (spec ()) options in
      fun { id; user_id; side; price; quantity } -> serialize id user_id side price quantity
    let from_json_exn =
      let constructor id user_id side price quantity = { id; user_id; side; price; quantity } in
      Runtime'.apply_lazy (fun () -> Runtime'.Deserialize_json.deserialize ~message_name:(name ()) (spec ()) constructor)
    let from_json json = Runtime'.Result.catch (fun () -> from_json_exn json)
  end
  and SubmitReply : sig
    type t = (Trade.t list)
    val make: ?trades:Trade.t list -> unit -> t
    (** Helper function to generate a message using default values *)

    val to_proto: t -> Runtime'.Writer.t
    (** Serialize the message to binary format *)

    val from_proto: Runtime'.Reader.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from binary format *)

    val to_json: Runtime'.Json_options.t -> t -> Runtime'.Json.t
    (** Serialize to Json (compatible with Yojson.Basic.t) *)

    val from_json: Runtime'.Json.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from Json (compatible with Yojson.Basic.t) *)

    val name: unit -> string
    (** Fully qualified protobuf name of this message *)

    (**/**)
    type make_t = ?trades:Trade.t list -> unit -> t
    val merge: t -> t -> t
    val to_proto': Runtime'.Writer.t -> t -> unit
    val from_proto_exn: Runtime'.Reader.t -> t
    val from_json_exn: Runtime'.Json.t -> t
    (**/**)
  end = struct
    module This'_ = SubmitReply
    let name () = ".exchange.SubmitReply"
    type t = (Trade.t list)
    type make_t = ?trades:Trade.t list -> unit -> t
    let make ?(trades = []) () = (trades)
    let merge =
    let merge_trades = Runtime'.Merge.merge Runtime'.Spec.( repeated ((1, "trades", "trades"), (message (module Trade)), not_packed) ) in
    fun (t1_trades) (t2_trades) -> merge_trades t1_trades t2_trades
    let spec () = Runtime'.Spec.( repeated ((1, "trades", "trades"), (message (module Trade)), not_packed) ^:: nil )
    let to_proto' =
      let serialize = Runtime'.apply_lazy (fun () -> Runtime'.Serialize.serialize (spec ())) in
      fun writer (trades) -> serialize writer trades

    let to_proto t = let writer = Runtime'.Writer.init () in to_proto' writer t; writer
    let from_proto_exn =
      let constructor trades = (trades) in
      Runtime'.apply_lazy (fun () -> Runtime'.Deserialize.deserialize (spec ()) constructor)
    let from_proto writer = Runtime'.Result.catch (fun () -> from_proto_exn writer)
    let to_json options =
      let serialize = Runtime'.Serialize_json.serialize ~message_name:(name ()) (spec ()) options in
      fun (trades) -> serialize trades
    let from_json_exn =
      let constructor trades = (trades) in
      Runtime'.apply_lazy (fun () -> Runtime'.Deserialize_json.deserialize ~message_name:(name ()) (spec ()) constructor)
    let from_json json = Runtime'.Result.catch (fun () -> from_json_exn json)
  end
  and CancelReply : sig
    type t = (bool)
    val make: ?ok:bool -> unit -> t
    (** Helper function to generate a message using default values *)

    val to_proto: t -> Runtime'.Writer.t
    (** Serialize the message to binary format *)

    val from_proto: Runtime'.Reader.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from binary format *)

    val to_json: Runtime'.Json_options.t -> t -> Runtime'.Json.t
    (** Serialize to Json (compatible with Yojson.Basic.t) *)

    val from_json: Runtime'.Json.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from Json (compatible with Yojson.Basic.t) *)

    val name: unit -> string
    (** Fully qualified protobuf name of this message *)

    (**/**)
    type make_t = ?ok:bool -> unit -> t
    val merge: t -> t -> t
    val to_proto': Runtime'.Writer.t -> t -> unit
    val from_proto_exn: Runtime'.Reader.t -> t
    val from_json_exn: Runtime'.Json.t -> t
    (**/**)
  end = struct
    module This'_ = CancelReply
    let name () = ".exchange.CancelReply"
    type t = (bool)
    type make_t = ?ok:bool -> unit -> t
    let make ?(ok = false) () = (ok)
    let merge =
    let merge_ok = Runtime'.Merge.merge Runtime'.Spec.( basic ((1, "ok", "ok"), bool, (false)) ) in
    fun (t1_ok) (t2_ok) -> merge_ok t1_ok t2_ok
    let spec () = Runtime'.Spec.( basic ((1, "ok", "ok"), bool, (false)) ^:: nil )
    let to_proto' =
      let serialize = Runtime'.apply_lazy (fun () -> Runtime'.Serialize.serialize (spec ())) in
      fun writer (ok) -> serialize writer ok

    let to_proto t = let writer = Runtime'.Writer.init () in to_proto' writer t; writer
    let from_proto_exn =
      let constructor ok = (ok) in
      Runtime'.apply_lazy (fun () -> Runtime'.Deserialize.deserialize (spec ()) constructor)
    let from_proto writer = Runtime'.Result.catch (fun () -> from_proto_exn writer)
    let to_json options =
      let serialize = Runtime'.Serialize_json.serialize ~message_name:(name ()) (spec ()) options in
      fun (ok) -> serialize ok
    let from_json_exn =
      let constructor ok = (ok) in
      Runtime'.apply_lazy (fun () -> Runtime'.Deserialize_json.deserialize ~message_name:(name ()) (spec ()) constructor)
    let from_json json = Runtime'.Result.catch (fun () -> from_json_exn json)
  end
  and WalletReply : sig
    type t = {
    usd: float;
    asset: float;
    }
    val make: ?usd:float -> ?asset:float -> unit -> t
    (** Helper function to generate a message using default values *)

    val to_proto: t -> Runtime'.Writer.t
    (** Serialize the message to binary format *)

    val from_proto: Runtime'.Reader.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from binary format *)

    val to_json: Runtime'.Json_options.t -> t -> Runtime'.Json.t
    (** Serialize to Json (compatible with Yojson.Basic.t) *)

    val from_json: Runtime'.Json.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from Json (compatible with Yojson.Basic.t) *)

    val name: unit -> string
    (** Fully qualified protobuf name of this message *)

    (**/**)
    type make_t = ?usd:float -> ?asset:float -> unit -> t
    val merge: t -> t -> t
    val to_proto': Runtime'.Writer.t -> t -> unit
    val from_proto_exn: Runtime'.Reader.t -> t
    val from_json_exn: Runtime'.Json.t -> t
    (**/**)
  end = struct
    module This'_ = WalletReply
    let name () = ".exchange.WalletReply"
    type t = {
    usd: float;
    asset: float;
    }
    type make_t = ?usd:float -> ?asset:float -> unit -> t
    let make ?(usd = 0.) ?(asset = 0.) () = { usd; asset }
    let merge =
    let merge_usd = Runtime'.Merge.merge Runtime'.Spec.( basic ((1, "usd", "usd"), double, (0.)) ) in
    let merge_asset = Runtime'.Merge.merge Runtime'.Spec.( basic ((2, "asset", "asset"), double, (0.)) ) in
    fun t1 t2 -> {
    usd = (merge_usd t1.usd t2.usd);
    asset = (merge_asset t1.asset t2.asset);
     }
    let spec () = Runtime'.Spec.( basic ((1, "usd", "usd"), double, (0.)) ^:: basic ((2, "asset", "asset"), double, (0.)) ^:: nil )
    let to_proto' =
      let serialize = Runtime'.apply_lazy (fun () -> Runtime'.Serialize.serialize (spec ())) in
      fun writer { usd; asset } -> serialize writer usd asset

    let to_proto t = let writer = Runtime'.Writer.init () in to_proto' writer t; writer
    let from_proto_exn =
      let constructor usd asset = { usd; asset } in
      Runtime'.apply_lazy (fun () -> Runtime'.Deserialize.deserialize (spec ()) constructor)
    let from_proto writer = Runtime'.Result.catch (fun () -> from_proto_exn writer)
    let to_json options =
      let serialize = Runtime'.Serialize_json.serialize ~message_name:(name ()) (spec ()) options in
      fun { usd; asset } -> serialize usd asset
    let from_json_exn =
      let constructor usd asset = { usd; asset } in
      Runtime'.apply_lazy (fun () -> Runtime'.Deserialize_json.deserialize ~message_name:(name ()) (spec ()) constructor)
    let from_json json = Runtime'.Result.catch (fun () -> from_json_exn json)
  end
  and Trade : sig
    type t = {
    buy_id: int;
    sell_id: int;
    price: float;
    quantity: int;
    timestamp: float;
    }
    val make: ?buy_id:int -> ?sell_id:int -> ?price:float -> ?quantity:int -> ?timestamp:float -> unit -> t
    (** Helper function to generate a message using default values *)

    val to_proto: t -> Runtime'.Writer.t
    (** Serialize the message to binary format *)

    val from_proto: Runtime'.Reader.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from binary format *)

    val to_json: Runtime'.Json_options.t -> t -> Runtime'.Json.t
    (** Serialize to Json (compatible with Yojson.Basic.t) *)

    val from_json: Runtime'.Json.t -> (t, [> Runtime'.Result.error]) result
    (** Deserialize from Json (compatible with Yojson.Basic.t) *)

    val name: unit -> string
    (** Fully qualified protobuf name of this message *)

    (**/**)
    type make_t = ?buy_id:int -> ?sell_id:int -> ?price:float -> ?quantity:int -> ?timestamp:float -> unit -> t
    val merge: t -> t -> t
    val to_proto': Runtime'.Writer.t -> t -> unit
    val from_proto_exn: Runtime'.Reader.t -> t
    val from_json_exn: Runtime'.Json.t -> t
    (**/**)
  end = struct
    module This'_ = Trade
    let name () = ".exchange.Trade"
    type t = {
    buy_id: int;
    sell_id: int;
    price: float;
    quantity: int;
    timestamp: float;
    }
    type make_t = ?buy_id:int -> ?sell_id:int -> ?price:float -> ?quantity:int -> ?timestamp:float -> unit -> t
    let make ?(buy_id = 0) ?(sell_id = 0) ?(price = 0.) ?(quantity = 0) ?(timestamp = 0.) () = { buy_id; sell_id; price; quantity; timestamp }
    let merge =
    let merge_buy_id = Runtime'.Merge.merge Runtime'.Spec.( basic ((1, "buy_id", "buyId"), uint64_int, (0)) ) in
    let merge_sell_id = Runtime'.Merge.merge Runtime'.Spec.( basic ((2, "sell_id", "sellId"), uint64_int, (0)) ) in
    let merge_price = Runtime'.Merge.merge Runtime'.Spec.( basic ((3, "price", "price"), double, (0.)) ) in
    let merge_quantity = Runtime'.Merge.merge Runtime'.Spec.( basic ((4, "quantity", "quantity"), uint32_int, (0)) ) in
    let merge_timestamp = Runtime'.Merge.merge Runtime'.Spec.( basic ((5, "timestamp", "timestamp"), double, (0.)) ) in
    fun t1 t2 -> {
    buy_id = (merge_buy_id t1.buy_id t2.buy_id);
    sell_id = (merge_sell_id t1.sell_id t2.sell_id);
    price = (merge_price t1.price t2.price);
    quantity = (merge_quantity t1.quantity t2.quantity);
    timestamp = (merge_timestamp t1.timestamp t2.timestamp);
     }
    let spec () = Runtime'.Spec.( basic ((1, "buy_id", "buyId"), uint64_int, (0)) ^:: basic ((2, "sell_id", "sellId"), uint64_int, (0)) ^:: basic ((3, "price", "price"), double, (0.)) ^:: basic ((4, "quantity", "quantity"), uint32_int, (0)) ^:: basic ((5, "timestamp", "timestamp"), double, (0.)) ^:: nil )
    let to_proto' =
      let serialize = Runtime'.apply_lazy (fun () -> Runtime'.Serialize.serialize (spec ())) in
      fun writer { buy_id; sell_id; price; quantity; timestamp } -> serialize writer buy_id sell_id price quantity timestamp

    let to_proto t = let writer = Runtime'.Writer.init () in to_proto' writer t; writer
    let from_proto_exn =
      let constructor buy_id sell_id price quantity timestamp = { buy_id; sell_id; price; quantity; timestamp } in
      Runtime'.apply_lazy (fun () -> Runtime'.Deserialize.deserialize (spec ()) constructor)
    let from_proto writer = Runtime'.Result.catch (fun () -> from_proto_exn writer)
    let to_json options =
      let serialize = Runtime'.Serialize_json.serialize ~message_name:(name ()) (spec ()) options in
      fun { buy_id; sell_id; price; quantity; timestamp } -> serialize buy_id sell_id price quantity timestamp
    let from_json_exn =
      let constructor buy_id sell_id price quantity timestamp = { buy_id; sell_id; price; quantity; timestamp } in
      Runtime'.apply_lazy (fun () -> Runtime'.Deserialize_json.deserialize ~message_name:(name ()) (spec ()) constructor)
    let from_json json = Runtime'.Result.catch (fun () -> from_json_exn json)
  end
  module Exchange = struct
    module SubmitOrder = struct
      let package_name = Some "exchange"
      let service_name = "Exchange"
      let method_name = "SubmitOrder"
      let name = "/exchange.Exchange/SubmitOrder"
      module Request = Order
      module Response = SubmitReply
    end
    let submitOrder : (module Runtime'.Spec.Message with type t = Order.t) * (module Runtime'.Spec.Message with type t = SubmitReply.t) =
      (module Order : Runtime'.Spec.Message with type t = Order.t ),
      (module SubmitReply : Runtime'.Spec.Message with type t = SubmitReply.t )

    module CancelOrder = struct
      let package_name = Some "exchange"
      let service_name = "Exchange"
      let method_name = "CancelOrder"
      let name = "/exchange.Exchange/CancelOrder"
      module Request = Order
      module Response = CancelReply
    end
    let cancelOrder : (module Runtime'.Spec.Message with type t = Order.t) * (module Runtime'.Spec.Message with type t = CancelReply.t) =
      (module Order : Runtime'.Spec.Message with type t = Order.t ),
      (module CancelReply : Runtime'.Spec.Message with type t = CancelReply.t )

    module GetWallet = struct
      let package_name = Some "exchange"
      let service_name = "Exchange"
      let method_name = "GetWallet"
      let name = "/exchange.Exchange/GetWallet"
      module Request = Order
      module Response = WalletReply
    end
    let getWallet : (module Runtime'.Spec.Message with type t = Order.t) * (module Runtime'.Spec.Message with type t = WalletReply.t) =
      (module Order : Runtime'.Spec.Message with type t = Order.t ),
      (module WalletReply : Runtime'.Spec.Message with type t = WalletReply.t )

  end
end
