#!/bin/bash

# R Package Format Script
# Formats R, C++ and JSON code for the package. A .formatignore file at the
# package root (full gitignore glob semantics) controls what every formatter
# skips; .gitignore is honoured too, and the local/ directory is an escape hatch.

set -e  # Exit on any errors
set -u  # Exit on undefined variables

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_NAME=$(basename "$0")

# Run from the package root (this script lives in <root>/scripts/) so every
# path -- and the .formatignore lookup -- resolves relative to it.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Colours for output
if [[ -t 1 ]]; then
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'
    BOLD=$'\033[1m'
    NC=$'\033[0m' # No Colour
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "${BOLD}${BLUE}==>${NC} ${BOLD}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# ============================================================================
# Help Function
# ============================================================================

show_help() {
    cat << EOF
${YELLOW}USAGE:${NC}
    ${BOLD}$SCRIPT_NAME${NC} [OPTIONS] [COMMAND]

${YELLOW}DESCRIPTION:${NC}
    Format R, C++ and JSON code in the package. Every formatter skips paths
    listed in .formatignore (full gitignore glob semantics) and .gitignore;
    the local/ directory is a ready-made escape hatch.

${YELLOW}COMMANDS:${NC}
    ${GREEN}r${NC}            Format R code using air (extremely fast formatter)
    ${GREEN}r-check${NC}      Check if R code is formatted (no changes)
    ${GREEN}cpp${NC}          Format C++ code using clang-format
    ${GREEN}cpp-check${NC}    Check if C++ code is formatted (no changes)
    ${GREEN}json${NC}         Format JSON using jq, 2-space indent (skips generated/tool-owned files)
    ${GREEN}json-check${NC}   Check if JSON is formatted (no changes)
    ${GREEN}all${NC}          Format R, C++ and JSON code (default)
    ${GREEN}check${NC}        Check formatting for R, C++ and JSON code
    ${GREEN}help${NC}         Show this help message

${YELLOW}OPTIONS:${NC}
    ${GREEN}-h, --help${NC}   Show this help message
    ${GREEN}-v, --verbose${NC} Enable verbose output

${YELLOW}EXAMPLES:${NC}
    ${BLUE}# Format all code${NC}
    $SCRIPT_NAME

    ${BLUE}# Format only R code${NC}
    $SCRIPT_NAME r

    ${BLUE}# Format only C++ code${NC}
    $SCRIPT_NAME cpp

    ${BLUE}# Check all formatting (for CI)${NC}
    $SCRIPT_NAME check

${YELLOW}NOTES:${NC}
    - Requires: air (R formatter), clang-format (C++ formatter), jq (JSON formatter)
    - Install air: ${BLUE}curl -LsSf https://github.com/posit-dev/air/releases/latest/download/air-installer.sh | sh${NC}
    - Install clang-format: ${BLUE}brew install clang-format${NC}
    - Install jq: ${BLUE}brew install jq${NC}
    - jq 1.7+ preserves number literals and key order, so values are never mutated
    - Exclusions: edit ${BLUE}.formatignore${NC} (full gitignore globs) or drop files under ${BLUE}local/${NC}

EOF
}

# ============================================================================
# Command Functions
# ============================================================================

run_cmd() {
    if [[ "${VERBOSE:-0}" == "1" ]]; then
        print_info "Running: $*"
    fi
    "$@"
}

# Select files matching the given extensions (e.g. "select_files R r") that
# are NOT excluded by .gitignore or .formatignore. Filtering is delegated to
# git's own ignore engine, so .formatignore understands the full gitignore
# glob vocabulary -- negation (!), **, anchoring -- and it applies even to
# tracked files. Requires a git repository.
select_files() {
    local globs=() ext
    for ext in "$@"; do globs+=("*.$ext"); done

    local candidates
    candidates=$(git ls-files --cached --others --exclude-standard -- "${globs[@]}" 2>/dev/null || true)
    [[ -z "$candidates" ]] && return 0

    if [[ -f "$ROOT/.formatignore" ]]; then
        local ignored
        ignored=$(printf '%s\n' "$candidates" \
            | git -c core.excludesFile="$ROOT/.formatignore" check-ignore --no-index --stdin 2>/dev/null || true)
        if [[ -n "$ignored" ]]; then
            printf '%s\n' "$candidates" | grep -vxF -f <(printf '%s\n' "$ignored") || true
            return 0
        fi
    fi
    printf '%s\n' "$candidates"
    return 0
}

# Read select_files output into the global SELECTED array (portable: macOS
# bash 3.2 has no mapfile). Callers must check ${#SELECTED[@]} before use.
read_selected() {
    SELECTED=()
    local line
    while IFS= read -r line; do
        [[ -n "$line" ]] && SELECTED+=("$line")
    done < <(select_files "$@")
}

cmd_format_r() {
    print_header "Formatting R code with air..."
    if ! command -v air &> /dev/null; then
        print_error "air is not installed. Install it from: https://posit-dev.github.io/air/"
        print_info "Quick install: curl -LsSf https://github.com/posit-dev/air/releases/latest/download/air-installer.sh | sh"
        exit 1
    fi
    read_selected R r
    if [[ ${#SELECTED[@]} -eq 0 ]]; then
        print_info "No R files to format"
        return 0
    fi
    run_cmd air format "${SELECTED[@]}"
    print_success "R code formatted"
}

cmd_format_r_check() {
    print_header "Checking R code formatting..."
    if ! command -v air &> /dev/null; then
        print_error "air is not installed. Install it from: https://posit-dev.github.io/air/"
        print_info "Quick install: curl -LsSf https://github.com/posit-dev/air/releases/latest/download/air-installer.sh | sh"
        exit 1
    fi
    read_selected R r
    if [[ ${#SELECTED[@]} -eq 0 ]]; then
        print_info "No R files to check"
        return 0
    fi
    if run_cmd air format --check "${SELECTED[@]}"; then
        print_success "All R code is properly formatted"
    else
        print_error "Some files need formatting. Run '$SCRIPT_NAME r' to fix."
        exit 1
    fi
}

cmd_format_cpp() {
    print_header "Formatting C++ code with clang-format..."
    if ! command -v clang-format &> /dev/null; then
        print_error "clang-format is not installed."
        print_info "Install with: brew install clang-format"
        exit 1
    fi
    read_selected cpp cc cxx h hpp hxx
    if [[ ${#SELECTED[@]} -eq 0 ]]; then
        print_info "No C++ files to format"
        return 0
    fi
    run_cmd clang-format -i "${SELECTED[@]}"
    print_success "C++ code formatted"
}

cmd_format_cpp_check() {
    print_header "Checking C++ code formatting..."
    if ! command -v clang-format &> /dev/null; then
        print_error "clang-format is not installed."
        print_info "Install with: brew install clang-format"
        exit 1
    fi
    read_selected cpp cc cxx h hpp hxx
    if [[ ${#SELECTED[@]} -eq 0 ]]; then
        print_info "No C++ files to check"
        return 0
    fi
    # --dry-run --Werror returns non-zero if changes are needed
    if run_cmd clang-format --dry-run --Werror "${SELECTED[@]}" 2>/dev/null; then
        print_success "All C++ code is properly formatted"
    else
        print_error "Some C++ files need formatting. Run '$SCRIPT_NAME cpp' to fix."
        exit 1
    fi
}

cmd_format_json() {
    print_header "Formatting JSON with jq..."
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed."
        print_info "Install with: brew install jq"
        exit 1
    fi
    read_selected json
    if [[ ${#SELECTED[@]} -eq 0 ]]; then
        print_info "No JSON files to format"
        return 0
    fi

    # jq 1.7+ prints unmutated number literals in their original form and
    # preserves key order, so only whitespace changes -- values and diffs
    # stay byte-stable.
    local f tmp
    for f in "${SELECTED[@]}"; do
        tmp=$(mktemp)
        if jq --indent 2 . "$f" > "$tmp" 2>/dev/null; then
            mv "$tmp" "$f"
        else
            rm -f "$tmp"
            print_warning "Skipped (invalid JSON): $f"
        fi
    done
    print_success "JSON formatted"
}

cmd_format_json_check() {
    print_header "Checking JSON formatting..."
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed."
        print_info "Install with: brew install jq"
        exit 1
    fi
    read_selected json
    if [[ ${#SELECTED[@]} -eq 0 ]]; then
        print_info "No JSON files to check"
        return 0
    fi

    local f needs_format=0
    for f in "${SELECTED[@]}"; do
        if ! diff -q <(jq --indent 2 . "$f" 2>/dev/null) "$f" > /dev/null 2>&1; then
            print_warning "Needs formatting: $f"
            needs_format=1
        fi
    done

    if [[ "$needs_format" == "1" ]]; then
        print_error "Some JSON files need formatting. Run '$SCRIPT_NAME json' to fix."
        exit 1
    fi
    print_success "All JSON is properly formatted"
}

cmd_format_all() {
    cmd_format_r
    echo ""
    cmd_format_cpp
    echo ""
    cmd_format_json
    print_success "All code formatted"
}

cmd_check_all() {
    cmd_format_r_check
    echo ""
    cmd_format_cpp_check
    echo ""
    cmd_format_json_check
    print_success "All code properly formatted"
}

# ============================================================================
# Argument Parsing
# ============================================================================

VERBOSE=0
COMMAND=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help|help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        r|r-check|cpp|cpp-check|json|json-check|all|check)
            COMMAND=$1
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
done

# ============================================================================
# Main Execution
# ============================================================================

# Default to 'all' if no command specified
if [[ -z "$COMMAND" ]]; then
    COMMAND="all"
fi

# Execute the command
case $COMMAND in
    r)
        cmd_format_r
        ;;
    r-check)
        cmd_format_r_check
        ;;
    cpp)
        cmd_format_cpp
        ;;
    cpp-check)
        cmd_format_cpp_check
        ;;
    json)
        cmd_format_json
        ;;
    json-check)
        cmd_format_json_check
        ;;
    all)
        cmd_format_all
        ;;
    check)
        cmd_check_all
        ;;
esac

exit 0
