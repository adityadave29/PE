import subprocess
import re
from statistics import mean


DB_NAME = "tpch-500mb"
OUTPUT_NAME = "sv"

QUERY = r"""
SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT
    s_name,
    s_address
FROM
    supplier,
    nation
WHERE
    s_suppkey IN (
        SELECT
            ps_suppkey
        FROM
            partsupp_secure
        WHERE
            ps_partkey IN (
                SELECT
                    p_partkey
                FROM
                    part
                WHERE
                    p_name LIKE '%ivory%'
            )
            AND EXISTS (
                SELECT 1
                FROM
                    lineitem
                WHERE
                    l_partkey = ps_partkey
                    AND l_suppkey = ps_suppkey
                    AND l_shipdate >= DATE '1995-01-01'
                LIMIT 1
            )
    )
    AND s_nationkey = n_nationkey
    AND n_name = 'FRANCE'
ORDER BY
    s_name;
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