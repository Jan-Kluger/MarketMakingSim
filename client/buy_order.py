#!/usr/bin/env python3
import sys
import grpc
import exchange_pb2
import exchange_pb2_grpc

def run(host: str = 'localhost', port: int = 8080):
    channel = grpc.insecure_channel(f'{host}:{port}')
    stub = exchange_pb2_grpc.ExchangeStub(channel)

    # 1. Create a new account
    reg_resp = stub.GetNewAccount(exchange_pb2.RegReq())
    user_id = reg_resp.user_id
    print(f"User ID: {user_id}")

    # 2. Check balance before
    bal_req = exchange_pb2.WalletRequest(user_id=user_id)
    bal_before = stub.GetWallet(bal_req)
    print(f"Balance before buy: {bal_before.balance}")

    # 3. Submit a buy order
    order_req = exchange_pb2.Order(
        id="",            # manager will overwrite with UUID
        user_id=user_id,
        side="B",         # 'B' for buy
        price=100.0,      # limit price
        quantity=1
    )
    ack = stub.SubmitOrder(order_req)
    print("Buy order submitted:")
    print(f"  order_id:   {ack.order_id}")
    print(f"  timestamp:  {ack.timestamp}")
    print(f"  status:     {ack.status}")
    print(f"  error_code: {ack.error_code}")

    # 4. Check balance after
    bal_after = stub.GetWallet(bal_req)
    print(f"Balance after buy: {bal_after.balance}")

if __name__ == '__main__':
    host = sys.argv[1] if len(sys.argv) > 1 else 'localhost'
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8080
    run(host, port)

