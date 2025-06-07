# MarketMakingSim

This projects aims to make it easier to test market making simulations on a real market. It can be hard to get a feel for developing trading algorithms without having a platform to play around on.

The market is developed in OCaml and through gRPC allow for interfacing with python bots which trade on the market data.

### How to run

First build the project with dune. Then run the executable found at src/_default/bin/main.exe. This should host the market on the port of your choosing.

To test it with the default python script just run it while the server is up. You should get client side information about the placement of your order, and the server should log the actions.
