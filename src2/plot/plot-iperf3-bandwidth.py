import os
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

import common

benchmark = "iperf3-bandwidth"

# If script is executed from plot directory, change to content root directory
if os.path.split(os.getcwd())[-1] == "plot":
    os.chdir("../..")

# Read data
plot_path = f"plots2/plot-{benchmark}.jpg"

data_dir = f"data2/{benchmark}"
driver_csvs = [os.path.join(data_dir, p) for p in ["baseline.csv", "nerdctl-bypass4netns.csv", "nerdctl-slirp4netns.csv", "podman-pasta.csv"]]

# Find file with the highest number
benchmark_files = driver_csvs
print(benchmark_files)

df = pd.concat([pd.read_csv(p, sep=";") for p in benchmark_files])
df["driver"] = common.map_approach_name(df["driver"])
df['score'] = df['scoreBitsPerSec'] / 1000000  # to MBit/s
print(df)

# Plot data

sns.set_theme(style="whitegrid")
chart = sns.barplot(data=df[["driver", "score"]], hue="driver",
                    palette=sns.color_palette(common.colors(len(benchmark_files))),
                    x="driver", y="score",
                    estimator=np.mean, errorbar='sd', capsize=.1, alpha=0.8)
chart.set(xlabel='Integration Approach', ylabel='Throughput  [MBit/s]\nhigher is better')

for i in chart.containers:
    chart.bar_label(i, label_type="center", fmt="%.0f")

plt.tight_layout(h_pad=2)
plt.savefig(plot_path, dpi=300)
plt.show()
