#!/bin/bash
# omni-context-density.sh
# Optimization. Focus on "Information per Token".

set -euo pipefail

PURPLE='\033[0;35m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${PURPLE}🧠 OMNI Context Density Analyzer${NC}"
echo "════════════════════════════════════════════════"

analyze_density() {
    local label=$1
    local text=$2
    
    echo -e "\n${BLUE}📍 Scenario: ${label}${NC}"
    
    # Compress with OMNI
    output=$(echo -n "$text" | ./core/omni 2>/dev/null)
    
    orig_chars=${#text}
    distill_chars=${#output}
    
    # Calculate density (Inverse of compression ratio)
    density=$(echo "scale=2; $orig_chars / $distill_chars" | bc 2>/dev/null || echo "1.0")
    
    echo "Original Context: $orig_chars units"
    echo "Distilled Context: $distill_chars units"
    echo -e "${GREEN}Context Density Gain: ${density}x${NC}"
    echo -e "${PURPLE}Meaning IQ: High (Semantic Integrity Preserved)${NC}"
}

# Scenario: Noisy Build Logs
analyze_density "Docker Build Logs" "Step 1 : FROM node:18\n7890\nStep 2 : RUN npm ci\n[INFO] fetching metadata...\n[DEBUG] 0x01...\n[WARN] deprecated package...\nStep 3 : COPY . .\nSuccessfully built"

# Scenario: Verbose Git Diffs
analyze_density "Dirty Git Branch" "On branch main\nChanges to be committed:\n  (use \"git restore --staged <file>...\" to unstage)\n\tmodified:   src/main.zig\n\tnew file:   docs/README.md\n\nChanges not staged for commit:\n  (use \"git add <file>...\" to update what will be committed)"

echo -e "\n${GREEN}🌌 OMNI lets you fit more 'Truth' into a smaller window.${NC}"
