type side = Buy | Sell  [@@deriving show]

type order_id = int
type user_id  = int

type order = {
  id        : order_id;
  user_id   : user_id;
  side      : side;
  price     : float option;  (** None => market order *)
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

val side_to_char : side -> char
