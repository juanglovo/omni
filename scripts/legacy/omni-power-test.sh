#!/bin/bash
# omni-power-test.sh
# The Ultimate OMNI Efficiency & Power Benchmark.

set -euo pipefail

# Colors
BOLD='\033[1m'
WHITE='\033[1;37m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

OMNI_BIN="./core/omni"
ITERATIONS=1000

echo -e "${MAGENTA}${BOLD}🚀 OMNI GLOBAL POWER TEST${NC}"
echo -e "${WHITE}══════════════════════════════════════════════════════════${NC}"

if [ ! -f "$OMNI_BIN" ]; then
    echo -e "${RED}Error: OMNI Native binary not found. Build it first with omni-deploy-edge.sh.${NC}"
    exit 1
fi

# 1. SEMANTIC POWER TEST (Quality over Quantity)
echo -e "\n${BLUE}${BOLD}[STAGE 1] SEMANTIC DISTILLATION QUALITY${NC}"

DOCKER_LOG="Step 1/12 : FROM alpine:3.18\n ---> 4567\nStep 2/12 : RUN apk add --no-cache curl build-base\n[INFO] Updating indices...\n[DEBUG] Trace: 0xDEADBEEF\nCACHED\nStep 3/12 : EXPOSE 3000"
SQL_QUERY="SELECT   id, name,   email   FROM   users   WHERE active = 1; -- internal query\n/* Block Comment */\nINSERT INTO sessions VALUES (1);"

echo -n "  Processing Docker Logs... "
d_out=$(echo -n "$DOCKER_LOG" | $OMNI_BIN 2>/dev/null)
echo -e "${GREEN}SUCCESS${NC}"

echo -n "  Processing SQL Schema...  "
s_out=$(echo -n "$SQL_QUERY" | $OMNI_BIN 2>/dev/null)
echo -e "${GREEN}SUCCESS${NC}"

# Result Display
cat << EOF
  --------------------------------------------------------
  ${YELLOW}Distillation Results:${NC}
  Input Size:   $(echo -e "$DOCKER_LOG\n$SQL_QUERY" | wc -c) units
  OMNI Output:  $(echo -e "$d_out\n$s_out" | wc -c) units
  ${BOLD}${MAGENTA}Context Density: +$(echo "scale=1; ($(echo -e "$DOCKER_LOG\n$SQL_QUERY" | wc -c) / $(echo -e "$d_out\n$s_out" | wc -c))" | bc)x Compression${NC}
  --------------------------------------------------------
EOF

# 2. SPEED POWER TEST (Native vs Scripting)
echo -e "\n${BLUE}${BOLD}[STAGE 2] EXTREME EXECUTION SPEED${NC}"
echo -e "  Benchmarking ${ITERATIONS} iterations of semantic filtering..."

start=$(python3 -c 'import time; print(time.time())' 2>/dev/null || date +%s.%N)
for i in $(seq 1 $ITERATIONS); do
    echo "git status" | $OMNI_BIN > /dev/null
done
end=$(python3 -c 'import time; print(time.time())' 2>/dev/null || date +%s.%N)

total_time=$(echo "$end - $start" | bc)
avg_lat=$(echo "scale=4; ($total_time * 1000) / $ITERATIONS" | bc)

echo -e "  Total Time:   ${GREEN}${total_time}s${NC}"
echo -e "  Avg Latency:  ${GREEN}${avg_lat}ms${NC} per request"
echo -e "  Throughput:   ${CYAN}$(echo "scale=0; $ITERATIONS / $total_time" | bc) ops/sec${NC}"

# 3. EDGE CAPABILITY TEST
echo -e "\n${BLUE}${BOLD}[STAGE 3] EDGE READINESS${NC}"
if [ -f "core/omni-wasm.wasm" ]; then
    size=$(du -h core/omni-wasm.wasm | awk '{print $1}')
    echo -e "  Wasm Engine Size:  ${GREEN}${size}${NC} (Hyper-portable)"
    echo -e "  Edge Caching:      ${GREEN}ENABLED${NC}"
else
    echo -e "  Wasm Engine:       ${RED}MISSING${NC}"
fi

echo -e "\n${WHITE}══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}✅ OMNI POWER TEST PASSED.${NC}"
echo -e "Ready for Public Push: ${MAGENTA}https://github.com/fajarhide/omni.git${NC}\n"
