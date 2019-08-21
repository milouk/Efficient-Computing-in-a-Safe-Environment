
import matplotlib.pyplot as plt
import matplotlib
import numpy as np
import matplotlib.pyplot as plt
from pylab import rcParams

stock={"apache":42.00, "CB memcpy":52.35, "CB memset":50.00, "CB mixed":50.00,
       "CB read":52.00, "CB write":50.00, "OS create_files":5.00, "OS create_processes":5.00,
       "OS create_threads":5.00, "OS launch_programs":5.00, "MC add":14.00, "MC append":13.00,
       "MC delete":8.00, "MC get":8.05, "MC prepend":13.00, "MC replace":13.00, "MC set":14.00,
       "OS mem_alloc":5.00, "nginx":33.55, "aes":54.00, "blowfish":18.00, "camellia":54.00,
       "cast":18.00, "dsa":60.00, "ecdsa":40.00, "ghash":18.00, "hmac":18.00, "idea":18.00,
       "whirlpool":18.00}
with_out_mitigations={"apache":34.15, "CB memcpy":51.15, "CB memset":50.00, "CB mixed":50.00,
                      "CB read":52.00, "CB write":50.00, "OS create_files":5.00,
                      "OS create_processes":5.00, "OS create_threads":5.00, "OS launch_programs":5.00,
                      "MC add":10.20, "MC append":10.00, "MC delete":6.00, "MC get":6.00,
                      "MC prepend":9.75, "MC replace":9.65, "MC set":10.35, "OS mem_alloc":5.00,
                      "nginx":26.95, "aes":54.00, "blowfish":18.00, "camellia":54.00, "cast":18.00,
                      "dsa":60.00, "ecdsa":40.00, "ghash":18.00, "hmac":18.00, "idea":18.00,
                      "whirlpool":18.00}

plt.figure(figsize=(18,7))
plt.xticks(fontsize=15, rotation=270)
plt.yticks(fontsize=15)
plt.ylabel("Execution time (in Seconds)", fontsize=15)

loc_s = np.arange(len(with_out_mitigations))+0.2 # Offsetting the tick-label location
loc_r = np.arange(len(stock))-0.2 # Offsetting the tick-label location
xtick_loc = list(loc_s) + list(loc_r)
xticks = list(with_out_mitigations.keys())

plt.bar(loc_s,list(with_out_mitigations.values()),color="blue", width=0.35,label='Mitigations Patches OFF')
plt.bar(loc_r,list(stock.values()),color="red", width=0.35,label='Mitigations Patches ON')
plt.xticks(xtick_loc, xticks, rotation=90, ha="right")
plt.tick_params(axis='x', which='minor', pad=15)
plt.legend(loc='upper right', prop={'size': 12})
plt.savefig("performance_coloured_results.pdf", bbox_inches='tight')
