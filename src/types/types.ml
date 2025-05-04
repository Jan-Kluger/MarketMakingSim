(* This file includes the basic types needed for all modules in the simulation *)

type side = Buy | Sell

type order_id = int
type user_id  = int

type order = {
  id        : order_id;
  user_id   : user_id;
  side      : side;
  price     : float option;
  quantity  : int;
  timestamp : float;
}

type trade = {
  buy_id    : order_id;
  sell_id   : order_id;
  price     : float;
  quantity  : int;
  timestamp : float;
}

let side_to_char = function
  | Buy  -> 'B'
  | Sell -> 'S'
