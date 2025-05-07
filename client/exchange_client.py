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

    # 3. Build the hardcoded Order request
    #    Note: both `id` and `user_id` are now strings
    request = exchange_pb2.Order(
        id="1",
        user_id="1",
        side="B",
        price=1.0,
        quantity=1
    )

    # 4. Perform the RPC with error handling
    try:
        ack = stub.SubmitOrder(request)
        # 5. Print each field of the SubmitAck
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

if __name__ == '__main__':
    # Usage: exchange_client.py [host] [port]
    host = sys.argv[1] if len(sys.argv) > 1 else 'localhost'
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8080
    run(host, port)
