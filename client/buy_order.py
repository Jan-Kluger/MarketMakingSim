#!/usr/bin/env python3
import sys
from typing import Optional
from market_api import MarketAPI, Order

def main(host: str = "localhost", port: int = 8080, *, price: Optional[float] = 100.0):
    mf = MarketAPI(host, port)
    print("User ID:", mf.uid)

    # Balance before
    print("Balance before:", mf.get_balance())

    # Submit a BUY limit order
    buy_order = Order("B", 1, price)
    order_id, status = mf.place_order(buy_order)
    print(f"Order submitted → id={order_id}, status={status}")

    # Balance after
    print("Balance after:", mf.get_balance())


if __name__ == "__main__":
    host = sys.argv[1] if len(sys.argv) > 1 else "localhost"
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8080
    main(host, port)
