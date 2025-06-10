#!/usr/bin/env python3
import grpc
import exchange_pb2
import exchange_pb2_grpc
from typing import Optional

class Order():
    def __init__(self, side : str , quantity : int, price:Optional[float]=None) -> None:
        if (not (side == "B" or side == "S")):
            raise ValueError("Side should be B or S (Buy or Sell)")
        if price:
            if price < 0.0:
                raise ValueError("Price should be Positive")
        if quantity < 0:
            raise ValueError("Quantity should be Positive")
        # Price of -1 for Market order
        self.price = price or -1.0
        self.side = side
        self.price = price
        self.quantity = quantity
    

class MarketAPI():
    def __init__(self, host: str = 'localhost', port: int = 8080) -> None:
        channel = grpc.insecure_channel(f'{host}:{port}')
        self.stub = exchange_pb2_grpc.ExchangeStub(channel)

        reg_resp = self.stub.GetNewAccount(exchange_pb2.RegReq())
        self.uid = reg_resp.user_id

    def get_balance(self) -> float:
        bal_req = exchange_pb2.WalletRequest(user_id=self.uid)
        return self.stub.GetWallet(bal_req).balance
    
    def place_order(self, order : Order):
        order_req = exchange_pb2.Order(
            user_id=self.uid,
            side=order.side,
            price= order.price or -1,
            quantity=order.quantity
        )

        ack = self.stub.SubmitOrder(order_req)
        
        if not (ack.error_code == 0):
            raise Exception (f"Order failed, error code: {ack.error_code}")
        return (ack.order_id, ack.status)
    
    def get_book (self):
        ack =self.stub.GetBook()
        bids = [(b.price, b.quantity) for b in ack.bids]
        asks = [(a.price, a.quantity) for a in ack.asks]
        return bids, asks

    def get_market_data(self, time_from : str, time_to : str):
        data_req = exchange_pb2.MarketDataRequest(
            data_type = "V"
            , time_from = time_from
            , time_to = time_to
        )

        ack = self.stub.GetMarketData(data_req)
        
        return ack

    def cancel_order (self, order_id : str):

        cancel_req = exchange_pb2.CancelOrderRequest (
            user_id = self.uid,
            order_id = order_id
        )

        ack = self.stub.CancelOrder(cancel_req)
        
        if (ack.order_id == -1 and ack.user_id != self.uid):
            raise Exception ("Could not cancel order")
        return (ack.order_id, ack.order_quantity, ack.amount_canceled)
        

    def order_info (self, order_id : str):
        info_req = exchange_pb2.OrderAliveRequest (
            order_id = order_id
        )
        
        ack = self.stub.OrderAlive(info_req)
        if not (ack.error_code == 0):
            raise Exception (f"Could not get order info, Error code: {ack.error_code}")
        return (ack.alive, ack.side, ack.order_amount, ack.fill_amount, ack.timestamp)
