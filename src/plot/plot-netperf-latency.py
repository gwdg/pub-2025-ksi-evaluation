import os
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

import common

benchmark = "netperf-latency-tcp"

# If script is executed from plot directory, change to content root directory
if os.path.split(os.getcwd())[-1] == "plot":
    os.chdir("../..")

# Read data
plot_path = f"plots/plot-{benchmark}.jpg"

data_dir = f"data/{benchmark}"
project_dirs = [os.path.join(data_dir, p) for p in ["slurm", "bridge-operator", "hpk", "ksi"]]

# Find file with the highest number
benchmark_files = [os.path.join(d, max(os.listdir(d))) for d in project_dirs if os.path.exists(d)]
print(benchmark_files)

df = pd.concat([pd.read_csv(p, sep=";") for p in benchmark_files])
df["project"] = common.map_approach_name(df["project"])

print(df)

# Plot data

sns.set_theme(style="whitegrid")
chart = sns.barplot(data=df[["project", "mean_latency"]], hue="project", palette="flare", x="project", y="mean_latency",
                    estimator=np.mean, errorbar='sd', capsize=.1, alpha=0.85)
chart.set(xlabel='Integration Approach', ylabel='Latency  [microseconds]\nlower is better')

for i in chart.containers:
    chart.bar_label(i, label_type="center", fmt="%.0f")

plt.tight_layout(h_pad=2)
plt.savefig(plot_path, dpi=300)
plt.show()
