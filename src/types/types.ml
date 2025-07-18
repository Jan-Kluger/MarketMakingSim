type side = Buy | Sell | Invalid [@@deriving show]
type req_type = Volume | Price | Invalid [@@deriving show]

type orderId = string [@@deriving show]
type userId  = string [@@deriving show]

type order = {
  id        : orderId;
  user_id   : userId;
  side      : side;
  price     : float option;
  quantity  : int;
  timestamp : string;
} [@@deriving show]

type submitAck = {
  order_id   : orderId;
  timestamp  : string;
  status     : string;
  error_code : int;
}[@@deriving show]

type marketDataRequest = {
  req_type  : req_type;
  time_from : string;
  time_to   : string;
} [@@deriving show]

type marketDataAck = {
  value      : float;
  error_code : int;
} [@@deriving show]

type walletAck = {
  user_id    : userId;
  balance    : float;
  error_code : int;
} [@@deriving show]

type cancelReq = {
  order_id : orderId;
  user_id  : userId;
} [@@deriving show]

type cancelAck = {
  order_id        : orderId;
  user_id         : userId;
  order_quantity  : int;
  amount_canceled : int;
} [@@deriving show]

type aliveAck = {
  alive        : bool;
  cancelled    : bool;
  price        : float option;
  side         : side;
  order_amount : int;
  fill_amount  : int;
  timestamp    : string;
  error_code   : int;
} [@@deriving show]

let side_to_char = function
  | Buy  -> 'B'
  | Sell -> 'S'
  | Invalid -> 'I'
