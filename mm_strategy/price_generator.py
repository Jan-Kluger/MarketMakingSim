import numpy as np
import matplotlib.pyplot as plt

class Generator:
    def __init__(self, S0=100, sigma=1, T=1, dt=0.01, seed=None, beta=0.5, impact_factor = 0.1):
        self.S0 = S0
        self.sigma = sigma
        self.T = T
        self.dt = dt
        self.N = int(T / dt)
        self.seed = seed
        self.beta = beta  # price impact exponent
        self.impact_factor = impact_factor
        if self.seed is not None:
            np.random.seed(seed)

    def generate(self):
        t = np.linspace(0, self.T, self.N + 1)
        dW = np.random.normal(0, 1, size=self.N) * np.sqrt(self.dt)
        W = np.concatenate([[0], np.cumsum(dW)])
        S = self.S0 + self.sigma * W
        self.S_path = S.copy()  # store for later modification
        return t, S

    def apply_price_impact(self, trade_indices, trade_sizes):
        for idx, Q in zip(trade_indices, trade_sizes):
            if idx < 0 or idx > self.N:
                continue  # skip invalid
            delta_p = self.impact_factor * np.sign(Q) * (abs(Q) ** self.beta)
            # Apply permanent impact to all future prices
            self.S_path[idx:] += delta_p

    def get_price_path(self):
        return self.S_path


if __name__ == "__main__":
    gen = Generator(S0=100, sigma=1, T=1, dt=0.01, beta=0.75, seed=42)
    t, S = gen.generate()

    # Simulate 3 trades: buy at t=0.3, sell at t=0.5 and 0.8
    trade_times = [0.3, 0.5, 0.8]
    trade_sizes = [+1, -1, -1]
    trade_indices = [int(ti / gen.dt) for ti in trade_times]

    gen.apply_price_impact(trade_indices, trade_sizes)
    S_impact = gen.get_price_path()

    # Plot original and impacted price paths
    plt.figure(figsize=(10, 5))
    plt.plot(t, S, label='Original Price', linewidth=1.8)
    plt.plot(t, S_impact, label='Price After Impact', linestyle='--', linewidth=1.8)

    # Mark trade times
    for idx, size in zip(trade_indices, trade_sizes):
        color = 'green' if size > 0 else 'red'
        label = 'Buy' if size > 0 else 'Sell'
        plt.axvline(t[idx], color=color, linestyle=':', alpha=0.7)
        plt.scatter(t[idx], S_impact[idx], color=color, label=f"{label} at t={t[idx]:.2f}")

    plt.title("Price Path Before and After Trades with Impact")
    plt.xlabel("Time")
    plt.ylabel("Price")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.show()
