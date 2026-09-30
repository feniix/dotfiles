#!/bin/bash
# Python Profiling Helper Script
# Usage: ./profile-python.sh <script.py> [args...]
#
# Generates CPU profile, memory profile, or line-by-line profile.
#
# Environment variables:
#   PROFILE_TYPE     cpu (default), memory, or line
#   PROFILE_OUTPUT   Output file (default: profile.prof or profile.dat)
#   PROFILE_SORT     Sort by: tottime, cumtime, calls (default: tottime)
#
# Examples:
#   ./profile-python.sh my_script.py                    # CPU profiling
#   PROFILE_TYPE=memory ./profile-python.sh my_script.py # Memory profiling
#   PROFILE_TYPE=line ./profile-python.sh my_script.py   # Line-by-line profiling

set -e

SCRIPT="$1"
shift

if [ -z "$SCRIPT" ]; then
    echo "Usage: ./profile-python.sh <script.py> [args...]"
    echo ""
    echo "Environment variables:"
    echo "  PROFILE_TYPE     Profile type: cpu (default), memory, line"
    echo "  PROFILE_OUTPUT   Output file (default: profile.prof or profile.dat)"
    echo "  PROFILE_SORT     Sort by: tottime, cumtime, calls (default: tottime)"
    echo ""
    echo "Examples:"
    echo "  ./profile-python.sh my_script.py"
    echo "  ./profile-python.sh my_script.py --input data.csv"
    echo "  PROFILE_SORT=cumtime ./profile-python.sh my_script.py"
    echo "  PROFILE_TYPE=memory ./profile-python.sh my_script.py"
    echo "  PROFILE_TYPE=line ./profile-python.sh my_script.py"
    exit 1
fi

if [ ! -f "$SCRIPT" ]; then
    echo "Error: Script '$SCRIPT' not found"
    exit 1
fi

# Configuration
PROFILE_TYPE="${PROFILE_TYPE:-cpu}"
OUTPUT="${PROFILE_OUTPUT:-profile.prof}"
SORT="${PROFILE_SORT:-tottime}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Python Performance Profiler${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Script:     ${GREEN}$SCRIPT${NC}"
echo -e "Type:       ${GREEN}$PROFILE_TYPE${NC}"
echo -e "Arguments:  ${YELLOW}$@${NC}"
echo ""

case "$PROFILE_TYPE" in
    cpu)
        echo -e "${BLUE}Running CPU profile...${NC}"
        python -m cProfile -o "$OUTPUT" -s "$SORT" "$SCRIPT" "$@"
        echo ""
        echo -e "${GREEN}✓ Profile saved to: $OUTPUT${NC}"
        echo ""
        echo -e "${BLUE}Top 20 functions by $SORT:${NC}"
        echo -e "${BLUE}================================================${NC}"
        python -c "
import pstats
stats = pstats.Stats('$OUTPUT')
stats.strip_dirs()
stats.sort_stats('$SORT')
stats.print_stats(20)
"
        ;;

    memory)
        OUTPUT="${PROFILE_OUTPUT:-profile.dat}"
        echo -e "${BLUE}Running memory profile...${NC}"
        echo ""

        if ! python -c "import memory_profiler" 2>/dev/null; then
            echo -e "${RED}✗ memory_profiler not installed${NC}"
            echo -e "${YELLOW}Install with: pip install memory_profiler${NC}"
            exit 1
        fi

        python -m memory_profiler "$SCRIPT" "$@"
        echo ""
        echo -e "${GREEN}✓ Memory profiling complete${NC}"
        echo ""
        echo -e "${YELLOW}Tip: For memory line-by-line output, add @profile decorator${NC}"
        echo -e "     and run: kernprof -l -v $SCRIPT"
        ;;

    line)
        OUTPUT="${PROFILE_OUTPUT:-profile.lprof}"
        echo -e "${BLUE}Running line-by-line profile...${NC}"
        echo ""

        if ! command -v kernprof &> /dev/null; then
            echo -e "${RED}✗ kernprof not installed${NC}"
            echo -e "${YELLOW}Install with: pip install line_profiler${NC}"
            exit 1
        fi

        # Create temp script with @profile decorators added if not present
        kernprof -l -v "$SCRIPT" "$@"
        echo ""
        echo -e "${GREEN}✓ Line profiling complete${NC}"
        echo ""
        echo -e "${YELLOW}Note: Functions must have @profile decorator for line profiling${NC}"
        echo -e "      Add @profile above functions you want to profile."
        ;;

    *)
        echo -e "${RED}✗ Unknown profile type: $PROFILE_TYPE${NC}"
        echo -e "Valid types: ${GREEN}cpu${NC}, ${GREEN}memory${NC}, ${GREEN}line${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Visualization
if [ "$PROFILE_TYPE" = "cpu" ]; then
    if command -v snakeviz &> /dev/null; then
        echo ""
        read -p "Open visualization in browser? [y/N] " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            snakeviz "$OUTPUT"
        fi
    else
        echo ""
        echo -e "${YELLOW}Tip: Install snakeviz for interactive visualization:${NC}"
        echo -e "      pip install snakeviz"
        echo -e "      snakeviz $OUTPUT"
    fi
fi
