from price_generator import generator
import matplotlib.pyplot as plt
import numpy as np

generated = generator(S0=100, sigma=1, T=1.0, dt=0.005, seed=1)
t, S = generated.generate()

def optimal_quotes(S, q, gamma, sigma, k, T, t):
    
    tau = T - t
    adjustment = q * gamma * sigma**2 * tau
    spread = (1 / gamma) * np.log(1 + gamma / k)
    p_bid = S - adjustment - spread
    p_ask = S + adjustment + spread
    return p_bid, p_ask

