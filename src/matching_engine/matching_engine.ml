type side = Buy | Sell

type order = {
  id : int;                (* unique identifier *)
  side : side;             (* Buy or Sell *)
  price : float;           (* limit price *)
  quantity : int;          (* number of units *)
  timestamp : float;       (* for FIFO matching priority *)
}

module type Matching_engineatching_engine = sig
  
end
