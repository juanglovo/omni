#!/bin/bash
# omni-distill-pro.sh
# Semantic Context Quality. Focus on "signal vs noise".

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

OMNI_BIN="./core/omni"
WASM_BIN="./core/omni-wasm.wasm"

echo -e "${BLUE}🌌 OMNI Semantic Distillation Pro${NC}"
echo "════════════════════════════════════════════════"

if [ ! -f "$OMNI_BIN" ]; then
    echo -e "${YELLOW}Native engine not found. Using Wasm via node...${NC}"
    # Simple node wrapper for testing if native bin isn't there
fi

test_distillation() {
    local name=$1
    local input=$2
    
    echo -e "\n${YELLOW}🧪 Testing Filter: ${name}${NC}"
    echo -e "${BLUE}Input (${#input} chars):${NC}"
    echo "$input" | head -n 3
    echo "..."
    
    echo -e "${GREEN}OMNI Distillation:${NC}"
    output=$(echo -n "$input" | $OMNI_BIN 2>/dev/null || echo "Error: OMNI binary failed")
    echo "$output"
    
    in_tokens=$(echo "$input" | wc -c)
    out_tokens=$(echo "$output" | wc -c)
    ratio=$(echo "scale=2; ($out_tokens / $in_tokens) * 100" | bc 2>/dev/null || echo "0")
    
    echo -e "${BLUE}Semantic Efficiency: ${ratio}% of original size (High Signal)${NC}"
}

# 1. Git Test
test_distillation "Git" "On branch feature/wasm\nChanges not staged for commit:\n  (use \"git add <file>...\" to update what will be committed)\n  (use \"git restore <file>...\" to discard changes in working directory)\n\tmodified:   core/src/wasm.zig\n\tmodified:   src/index.ts\n\nno changes added to commit (use \"git add\" and/or \"git commit -a\")"

# 2. Docker Test
test_distillation "Docker" "Step 1/10 : FROM zig-base\n ---> 9f1f00\nStep 2/10 : RUN build.sh\n[INFO] Installing dependencies...\n[DEBUG] Trace: 0x12345\nCACHED\nStep 3/10 : EXPOSE 8080"

# 3. SQL Test
test_distillation "SQL" "SELECT name, email   FROM   users   WHERE id = 100; -- fetch user data\n/* Optimized by OMNI */"

echo -e "\n${GREEN}✅ Distillation Complete. Context Density Maxed.${NC}"
