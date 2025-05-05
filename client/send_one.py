# Need package grpc

import grpc, time, math
import exchange_pb2 as pb
import exchange_pb2_grpc as pbg

def main():
    chan = grpc.insecure_channel("localhost:50051")
    stub = pbg.ExchangeStub(chan)

    order = pb.Order(
        id        = 1,
        user_id   = 42,
        side      = pb.BUY,
        price     = math.nan,   # market order
        quantity  = 100,
    )

    resp = stub.SubmitOrder(order, timeout=3)
    print("Python got reply:", resp)

if __name__ == "__main__":
    main()
