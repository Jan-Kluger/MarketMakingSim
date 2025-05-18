from price_generator import generator
import matplotlib.pyplot as plt

generated = generator(S0=100, sigma=1, T=1.0, dt=0.005, seed=1)
t, S = generated.generate()

plt.plot(t, S)
plt.xlabel("Time")
plt.ylabel("Mid-price S(t)")
plt.title("Simulated Mid-Price Path")
plt.grid(True)
plt.show()
