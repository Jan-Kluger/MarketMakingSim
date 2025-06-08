#!/usr/bin/env python3
import sys
import grpc
import exchange_pb2
import exchange_pb2_grpc

def run(host: str = 'localhost', port: int = 8080):
    # 1. Open the channel
    channel = grpc.insecure_channel(f'{host}:{port}')
    # 2. Create a stub (client)
    stub = exchange_pb2_grpc.ExchangeStub(channel)

    # 3. Get a new account
    try:
        reg_req = exchange_pb2.RegReq()  # empty registration request
        reg_resp = stub.GetNewAccount(reg_req)
        user_id = reg_resp.user_id  # adjust field name if different
        print(f"New account created with user_id: {user_id}")
    except grpc.RpcError as e:
        print(f"Failed to get new account: {e.code()} - {e.details()}")
        return

    # 4. Submit an order using the new user_id
    order_req = exchange_pb2.Order(
        id="1",
        user_id=user_id,
        side="S",
        price=100.0,
        quantity=1
    )
    try:
        ack = stub.SubmitOrder(order_req)
        print("Order submitted!")
        print(f"  order_id:   {ack.order_id}")
        print(f"  timestamp:  {ack.timestamp}")
        print(f"  status:     {ack.status}")
        print(f"  error_code: {ack.error_code}")
    except grpc.RpcError as e:
        if e.code() == grpc.StatusCode.UNAVAILABLE:
            print("Server not available")
        else:
            print(f"gRPC error: {e.code()} - {e.details()}")
        return

    # 5. Retrieve the order book for current bids
    try:
        balReq = exchange_pb2.WalletRequest(user_id = user_id)
        balResp = stub.GetWallet(balReq)

        print(balResp)

        book_req = exchange_pb2.RegReq()
        book_resp = stub.GetBook(book_req)
        print("\nCurrent bids:")
        for bid in book_resp.bids:
            print(f"  price: {bid.price}, quantity: {bid.quantity}")
    except grpc.RpcError as e:
        print(f"Failed to get book: {e.code()} - {e.details()}")

if __name__ == '__main__':
    # Usage: exchange_client.py [host] [port]
    host = sys.argv[1] if len(sys.argv) > 1 else 'localhost'
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8080
    run(host, port)
