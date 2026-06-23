import subprocess
import re
from statistics import mean

# ============================================================
# CONFIGURATION
# ============================================================

DB_NAME = "tpch-300mb"

QUERY = r"""
SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
        s_acctbal,
        s_name,
        n_name,
        p_partkey,
        p_mfgr,
        s_address,
        s_phone,
        s_comment
from
        part,
        supplier,
        partsupp,
        nation,
        region
where
        p_partkey = ps_partkey
        and s_suppkey = ps_suppkey
        and p_size = 15
        and p_type like '%BRASS'
        and s_nationkey = n_nationkey
        and n_regionkey = region.r_regionkey
        and region.r_name = 'EUROPE'
        and ps_supplycost = (
                select
                        min(ps_supplycost)
                from
                        partsupp,
                        supplier,
                        nation,
                        region
                where
                        p_partkey = ps_partkey
                        and s_suppkey = ps_suppkey
                        and s_nationkey = n_nationkey
                        and n_regionkey = region.r_regionkey
                        and region.r_name = 'EUROPE'
        )
order by
        s_acctbal desc,
        n_name,
        s_name,
        p_partkey
limit 100;
"""

# ============================================================
# BENCHMARK
# ============================================================

planning_times = []
execution_times = []
last_output = ""

for i in range(10):
    print(f"Running {i+1}/10...")

    proc = subprocess.Popen(
        ["psql", "-d", DB_NAME, "-X"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )

    output, _ = proc.communicate(QUERY)

    # Print only the 10th run
    if i == 9:
        print("\n" + "=" * 100)
        print("5TH RUN OUTPUT")
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

# ============================================================
# SUMMARY
# ============================================================

avg_planning = mean(planning_times)
avg_execution = mean(execution_times)

print("\n" + "=" * 100)
print("BENCHMARK SUMMARY")
print("=" * 100)
print(f"Runs                : {len(execution_times)}")
print(f"Average Planning    : {avg_planning:.3f} ms")
print(f"Average Execution   : {avg_execution:.3f} ms")

# ============================================================
# SAVE 10TH RUN OUTPUT
# ============================================================

with open("run5_explain.txt", "w") as f:
    f.write(last_output)

# ============================================================
# SAVE SUMMARY
# ============================================================

with open("summary.txt", "w") as f:
    f.write(f"Runs: {len(execution_times)}\n")
    f.write(f"Average Planning Time: {avg_planning:.3f} ms\n")
    f.write(f"Average Execution Time: {avg_execution:.3f} ms\n")

print("\nGenerated Files:")
print("  run5_explain.txt")
print("  summary.txt")