#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_NAME=$(basename "$PROJECT_DIR")

# Colours for output
if [[ -t 1 ]]; then
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'
    BOLD=$'\033[1m'
    NC=$'\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

# ============================================================================
# Helpers
# ============================================================================

DRY_RUN=1
VERBOSE=0
TOTAL_CLEANED=0

print_header() {
    echo "${BOLD}${BLUE}==>${NC} ${BOLD}$1${NC}"
}

print_success() {
    echo "${GREEN}✓${NC} $1"
}

print_warning() {
    echo "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo "${BLUE}ℹ${NC} $1"
}

print_skip() {
    if [[ "$VERBOSE" == "1" ]]; then
        echo "  ${BLUE}-${NC} $1 (not found)"
    fi
}

# Clean a set of files matching a find pattern
# Usage: clean_files <description> <find_args...>
clean_files() {
    local desc="$1"
    shift

    local files
    files=$(cd "$PROJECT_DIR" && find "$@" -not -path './*.Rcheck/*' 2>/dev/null) || true

    if [[ -z "$files" ]]; then
        print_skip "$desc"
        return
    fi

    local count
    count=$(echo "$files" | wc -l | tr -d ' ')
    local size
    size=$(cd "$PROJECT_DIR" && echo "$files" | xargs du -ch 2>/dev/null | tail -1 | awk '{print $1}') || size="?"

    if [[ "$DRY_RUN" == "1" ]]; then
        print_info "[DRY RUN] Would remove $desc ($count files, $size)"
        if [[ "$VERBOSE" == "1" ]]; then
            echo "$files" | sed 's/^/    /'
        fi
    else
        (cd "$PROJECT_DIR" && echo "$files" | xargs rm -rf)
        print_success "Removed $desc ($count files, $size)"
    fi
    TOTAL_CLEANED=$((TOTAL_CLEANED + count))
}

# Clean a specific directory
# Usage: clean_dir <description> <dir_path>
clean_dir() {
    local desc="$1"
    local dir="$2"

    if [[ ! -d "$PROJECT_DIR/$dir" ]]; then
        print_skip "$desc"
        return
    fi

    local size
    size=$(du -sh "$PROJECT_DIR/$dir" 2>/dev/null | awk '{print $1}') || size="?"

    if [[ "$DRY_RUN" == "1" ]]; then
        print_info "[DRY RUN] Would remove $desc ($size)"
    else
        rm -rf "$PROJECT_DIR/$dir"
        print_success "Removed $desc ($size)"
    fi
    TOTAL_CLEANED=$((TOTAL_CLEANED + 1))
}

# Clean a specific file
# Usage: clean_file <description> <file_path>
clean_file() {
    local desc="$1"
    local file="$2"

    if [[ ! -f "$PROJECT_DIR/$file" ]]; then
        print_skip "$desc"
        return
    fi

    local size
    size=$(du -h "$PROJECT_DIR/$file" 2>/dev/null | awk '{print $1}') || size="?"

    if [[ "$DRY_RUN" == "1" ]]; then
        print_info "[DRY RUN] Would remove $desc ($size)"
    else
        rm -f "$PROJECT_DIR/$file"
        print_success "Removed $desc ($size)"
    fi
    TOTAL_CLEANED=$((TOTAL_CLEANED + 1))
}

# Clean files matching a glob in the project root
# Usage: clean_glob <description> <glob_pattern>
clean_glob() {
    local desc="$1"
    local pattern="$2"

    local files
    files=$(cd "$PROJECT_DIR" && ls -1 $pattern 2>/dev/null) || true

    if [[ -z "$files" ]]; then
        print_skip "$desc"
        return
    fi

    local count
    count=$(echo "$files" | wc -l | tr -d ' ')
    local size
    size=$(cd "$PROJECT_DIR" && du -ch $pattern 2>/dev/null | tail -1 | awk '{print $1}') || size="?"

    if [[ "$DRY_RUN" == "1" ]]; then
        print_info "[DRY RUN] Would remove $desc ($count files, $size)"
    else
        (cd "$PROJECT_DIR" && rm -rf $pattern)
        print_success "Removed $desc ($count files, $size)"
    fi
    TOTAL_CLEANED=$((TOTAL_CLEANED + count))
}

# ============================================================================
# Help
# ============================================================================

show_help() {
    cat << EOF
${YELLOW}USAGE:${NC}
    ${BOLD}$(basename "$0")${NC} [OPTIONS]

${YELLOW}DESCRIPTION:${NC}
    Remove build artifacts, compiled objects, and temporary files from the
    R package project. Only removes generated files that can be recreated.

${YELLOW}WHAT GETS CLEANED:${NC}
    ${GREEN}Compiled objects${NC}      src/**/*.o, src/**/*.so, src/**/*.dll
    ${GREEN}Package tarball${NC}       ${PACKAGE_NAME}_*.tar.gz
    ${GREEN}R CMD check output${NC}    ${PACKAGE_NAME}.Rcheck/
    ${GREEN}README.html${NC}           Intermediate knit output
    ${GREEN}.DS_Store${NC}             macOS metadata files
    ${GREEN}R session files${NC}       .RData, .Rhistory
    ${GREEN}Vignette cache${NC}        vignettes/*_cache/, vignettes/*_files/
    ${GREEN}Knitr cache${NC}           *_cache/ directories

${YELLOW}WHAT IS PRESERVED:${NC}
    ${BLUE}Source code${NC}           src/**/*.{cpp,h}, R/, man/, tests/
    ${BLUE}Vignette sources${NC}      vignettes/*.Rmd, vignettes/*.Rmd.orig
    ${BLUE}Vignette figures${NC}      vignettes/figures/, vignettes/figure/
    ${BLUE}Package data${NC}          data/*.rda
    ${BLUE}Documentation${NC}         docs/ (pkgdown site)
    ${BLUE}Configuration${NC}         Makevars, Makevars.win, .gitignore, etc.

${YELLOW}OPTIONS:${NC}
    ${GREEN}-f, --force${NC}      Actually delete files (default is dry run)
    ${GREEN}-n, --dry-run${NC}    Show what would be removed without deleting (default)
    ${GREEN}-h, --help${NC}       Show this help message
    ${GREEN}-v, --verbose${NC}    Show skipped items and file details

${YELLOW}EXAMPLES:${NC}
    ${BLUE}# See what would be cleaned (default)${NC}
    $(basename "$0")

    ${BLUE}# Actually clean${NC}
    $(basename "$0") --force

    ${BLUE}# Verbose dry run${NC}
    $(basename "$0") --verbose

EOF
}

# ============================================================================
# Parse Arguments
# ============================================================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--force)
            DRY_RUN=0
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=1
            shift
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        *)
            echo "${RED}✗${NC} Unknown option: $1" >&2
            echo "  Run $(basename "$0") --help for usage" >&2
            exit 1
            ;;
    esac
done

# ============================================================================
# Main
# ============================================================================

if [[ "$DRY_RUN" == "1" ]]; then
    print_header "Dry run — showing what would be cleaned..."
else
    print_header "Cleaning build artifacts..."
fi
echo ""

# --- R CMD build/check output (remove first so .o count isn't inflated) ---
print_header "Build & check output"
clean_dir "R CMD check output (${PACKAGE_NAME}.Rcheck/)" \
    "${PACKAGE_NAME}.Rcheck"
clean_glob "Package tarball (${PACKAGE_NAME}_*.tar.gz)" \
    "${PACKAGE_NAME}_*.tar.gz"
echo ""

# --- Compiled objects ---
print_header "Compiled objects"
clean_files "Object files (src/**/*.o)" \
    ./src -name '*.o' -type f
clean_files "Shared libraries (src/**/*.so)" \
    ./src -name '*.so' -type f
clean_files "DLL files (src/**/*.dll)" \
    ./src -name '*.dll' -type f
echo ""

# --- Intermediate knit/render output ---
print_header "Render artifacts"
clean_file "README.html" "README.html"
echo ""

# --- macOS junk ---
print_header "OS metadata"
clean_files ".DS_Store files" \
    . -name '.DS_Store' -not -path './.git/*' -type f
echo ""

# --- R session files ---
print_header "R session files"
clean_file ".RData" ".RData"
clean_file ".Rhistory" ".Rhistory"
echo ""

# --- Cache directories ---
print_header "Cache directories"
clean_files "Knitr/vignette caches (*_cache/)" \
    . -type d -name '*_cache' -not -path './.git/*'
clean_files "Vignette generated files (vignettes/*_files/)" \
    ./vignettes -type d -name '*_files'
echo ""

# --- Summary ---
if [[ "$TOTAL_CLEANED" -eq 0 ]]; then
    print_info "Already clean — nothing to remove."
else
    if [[ "$DRY_RUN" == "1" ]]; then
        print_warning "Dry run complete. Re-run with --force to actually clean."
    else
        print_success "Done! Cleaned $TOTAL_CLEANED items."
    fi
fi
