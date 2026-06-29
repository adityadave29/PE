import subprocess
import re
from statistics import mean


DB_NAME = "tpch-300mb"
OUTPUT_NAME = "sv-300"

QUERY = r"""
SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
        sum(l_extendedprice) / 7.0 as avg_yearly
from
        lineitem_secure,
        part
where
        p_partkey = l_partkey
        and p_brand = 'Brand#53'
        and p_container = 'MED BAG'
        and l_quantity < (
                select
                        0.7 * avg(l_quantity)
                from
                        lineitem_secure
                where
                        l_partkey = p_partkey
        );
"""

planning_times = []
execution_times = []
last_output = ""

for i in range(20):
    print(f"Running {i + 1}/20...")

    proc = subprocess.Popen(
        ["psql", "-d", DB_NAME, "-X"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )

    output, _ = proc.communicate(QUERY)

    if i == 19:
        print("\n" + "=" * 100)
        print("20TH RUN OUTPUT")
        print("=" * 100)
        print(output)

    last_output = output

    planning_match = re.search(
        r"Planning Time:\s+([\d.]+)\s+ms",
        output
    )

    execution_match = re.search(
        r"Execution Time:\s+([\d.]+)\s+ms",
        output
    )

    if planning_match:
        planning_times.append(float(planning_match.group(1)))

    if execution_match:
        execution_times.append(float(execution_match.group(1)))

avg_planning = mean(planning_times) if planning_times else 0
avg_execution = mean(execution_times) if execution_times else 0

print("\n" + "=" * 100)
print("BENCHMARK SUMMARY")
print("=" * 100)
print(f"Runs                : {len(execution_times)}")
print(f"Average Planning    : {avg_planning:.3f} ms")
print(f"Average Execution   : {avg_execution:.3f} ms")

with open(f"{OUTPUT_NAME}.txt", "w") as f:
    f.write(last_output)

with open(f"summary-{OUTPUT_NAME}.txt", "w") as f:
    f.write(f"Runs: {len(execution_times)}\n")
    f.write(f"Average Planning Time: {avg_planning:.3f} ms\n")
    f.write(f"Average Execution Time: {avg_execution:.3f} ms\n")

print("\nGenerated Files:")
print(f"  {OUTPUT_NAME}.txt")
print(f"  summary-{OUTPUT_NAME}.txt")