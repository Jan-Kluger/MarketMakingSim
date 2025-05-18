import numpy as np
import matplotlib.pyplot as plt

import numpy as np

class RealTimePriceGenerator:
    def __init__(self, S0=100.0, sigma=1.0, dt=0.01, beta=0.6, alpha=0.05, seed=None):
        self.S = S0
        self.sigma = sigma
        self.dt = dt
        self.beta = beta
        self.alpha = alpha
        self.t = 0.0
        self.impact_queue = []  # queue of pending impacts (if modeling temporary impact)
        if seed is not None:
            np.random.seed(seed)
        self.S_history = [S0]
        self.t_history = [0.0]

    def step(self):
        dW = np.random.normal(0, 1) * np.sqrt(self.dt)
        self.S += self.sigma * dW
        self.t += self.dt
        self.S_history.append(self.S)
        self.t_history.append(self.t)
        return self.t, self.S

    def apply_price_impact(self, idx, Q):
        delta_p = self.alpha * np.sign(Q) * (abs(Q) ** self.beta)
        self.S_history[idx:] = [s + delta_p for s in self.S_history[idx:]]

    def get_history(self):
        return self.t_history, self.S_history



if __name__ == "__main__":
    steps = 101 
    gen = RealTimePriceGenerator(S0=100, sigma=1, dt=0.01, beta=0.75, alpha=0.05, seed=42)

    for _ in range(steps - 1):
        gen.step()

    t, S = gen.get_history()
    S_original = S.copy()  # backup before impact

    # Simulate 3 trades at t = 0.3, 0.5, 0.8
    trade_times = [0.3, 0.5, 0.8]
    trade_sizes = [+5, -10, -6]
    trade_indices = [int(ti / gen.dt) for ti in trade_times]

    for idx, size in zip(trade_indices, trade_sizes):
        gen.apply_price_impact(idx, size)

    t, S_impact = gen.get_history()

    # === Plotting ===
    plt.figure(figsize=(10, 5))
    plt.plot(t, S_original, label='Original Price', linewidth=1.8)
    plt.plot(t, S_impact, label='Price After Impact', linestyle='--', linewidth=1.8)

    for idx, size in zip(trade_indices, trade_sizes):
        color = 'green' if size > 0 else 'red'
        label = 'Buy' if size > 0 else 'Sell'
        plt.axvline(t[idx], color=color, linestyle=':', alpha=0.7)
        plt.scatter(t[idx], S_impact[idx], color=color, label=f"{label} at t={t[idx]:.2f}")

    plt.title("Price Path Before and After Trades with Impact (Real-Time Model)")
    plt.xlabel("Time")
    plt.ylabel("Price")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.show()