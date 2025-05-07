type side = Buy | Sell [@@deriving show]

type order_id = int [@@deriving show]
type user_id  = int [@@deriving show]

type order = {
  id        : order_id;
  user_id   : user_id;
  side      : side;
  price     : float option;
  quantity  : int;
  timestamp : float;
} [@@deriving show]

type trade = {
  buy_id    : order_id;
  sell_id   : order_id;
  price     : float;
  quantity  : int;
  timestamp : float;
} [@@deriving show]

let side_to_char = function
  | Buy  -> 'B'
  | Sell -> 'S'
