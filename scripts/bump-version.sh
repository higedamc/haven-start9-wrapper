#!/bin/bash
# ==============================================================================
# Haven Start9 Wrapper - Version Bump Script
# ==============================================================================
# Usage:
#   ./scripts/bump-version.sh [patch|minor|major|VERSION]
#
# Examples:
#   ./scripts/bump-version.sh patch        # 1.1.6 → 1.1.7
#   ./scripts/bump-version.sh minor        # 1.1.6 → 1.2.0
#   ./scripts/bump-version.sh major        # 1.1.6 → 2.0.0
#   ./scripts/bump-version.sh 1.2.5        # 1.1.6 → 1.2.5
#   ./scripts/bump-version.sh              # Interactive mode
# ==============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Files to update
MANIFEST_FILE="manifest.yaml"
ENTRYPOINT_FILE="docker_entrypoint.sh"
IMPORT_SCRIPT="scripts/procedures/importNotes.sh"

# ==============================================================================
# Helper Functions
# ==============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

# ==============================================================================
# Version Detection
# ==============================================================================

get_current_version() {
    if command -v yq >/dev/null 2>&1; then
        yq '.version' "$MANIFEST_FILE" 2>/dev/null
    else
        grep "^version:" "$MANIFEST_FILE" | head -1 | awk '{print $2}'
    fi
}

# ==============================================================================
# Version Calculation
# ==============================================================================

calculate_next_version() {
    local current=$1
    local bump_type=$2
    
    # Parse current version
    IFS='.' read -r major minor patch <<< "$current"
    
    case $bump_type in
        patch)
            echo "${major}.${minor}.$((patch + 1))"
            ;;
        minor)
            echo "${major}.$((minor + 1)).0"
            ;;
        major)
            echo "$((major + 1)).0.0"
            ;;
        *)
            log_error "Invalid bump type: $bump_type"
            exit 1
            ;;
    esac
}

validate_version() {
    local version=$1
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Invalid version format: $version (expected: X.Y.Z)"
        return 1
    fi
    return 0
}

# ==============================================================================
# File Updates
# ==============================================================================

update_manifest_version() {
    local old_version=$1
    local new_version=$2
    
    log_step "Updating manifest.yaml version..."
    
    if command -v yq >/dev/null 2>&1; then
        yq -i ".version = \"$new_version\"" "$MANIFEST_FILE"
    else
        # Fallback to sed
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/^version: ${old_version}/version: ${new_version}/" "$MANIFEST_FILE"
        else
            sed -i "s/^version: ${old_version}/version: ${new_version}/" "$MANIFEST_FILE"
        fi
    fi
    
    log_success "Updated $MANIFEST_FILE"
}

update_default_versions() {
    local old_version=$1
    local new_version=$2
    
    log_step "Updating default version values in scripts..."
    
    # Escape dots for sed
    local old_escaped=$(echo "$old_version" | sed 's/\./\\./g')
    local new_escaped="$new_version"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/${old_escaped}/${new_escaped}/g" "$ENTRYPOINT_FILE"
        sed -i '' "s/${old_escaped}/${new_escaped}/g" "$IMPORT_SCRIPT"
    else
        # Linux
        sed -i "s/${old_escaped}/${new_escaped}/g" "$ENTRYPOINT_FILE"
        sed -i "s/${old_escaped}/${new_escaped}/g" "$IMPORT_SCRIPT"
    fi
    
    log_success "Updated $ENTRYPOINT_FILE"
    log_success "Updated $IMPORT_SCRIPT"
}

# ==============================================================================
# Release Notes
# ==============================================================================

prompt_release_notes() {
    local new_version=$1
    local today=$(date +%Y-%m-%d)
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📝 Release Notes for v${new_version}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Enter release title (or press Enter for default):"
    read -r release_title
    
    if [ -z "$release_title" ]; then
        release_title="Release v${new_version}"
    fi
    
    echo ""
    echo "Enter new features (one per line, empty line to finish):"
    echo -e "${CYAN}Example: Database Dashboard with event statistics${NC}"
    
    local features=()
    while true; do
        read -r feature
        if [ -z "$feature" ]; then
            break
        fi
        features+=("$feature")
    done
    
    echo ""
    echo "Enter improvements (one per line, empty line to finish):"
    echo -e "${CYAN}Example: Enhanced error handling${NC}"
    
    local improvements=()
    while true; do
        read -r improvement
        if [ -z "$improvement" ]; then
            break
        fi
        improvements+=("$improvement")
    done
    
    echo ""
    echo "Enter bug fixes (one per line, empty line to finish):"
    echo -e "${CYAN}Example: Fixed database persistence issue${NC}"
    
    local bugfixes=()
    while true; do
        read -r bugfix
        if [ -z "$bugfix" ]; then
            break
        fi
        bugfixes+=("$bugfix")
    done
    
    # Generate release notes
    local notes="  **v${new_version} - ${release_title} (${today})**"
    
    if [ ${#features[@]} -gt 0 ]; then
        notes="${notes}\n  \n  New Features:"
        for feature in "${features[@]}"; do
            notes="${notes}\n  - ${feature}"
        done
    fi
    
    if [ ${#improvements[@]} -gt 0 ]; then
        notes="${notes}\n  \n  Improvements:"
        for improvement in "${improvements[@]}"; do
            notes="${notes}\n  - ${improvement}"
        done
    fi
    
    if [ ${#bugfixes[@]} -gt 0 ]; then
        notes="${notes}\n  \n  Bug Fixes:"
        for bugfix in "${bugfixes[@]}"; do
            notes="${notes}\n  - ${bugfix}"
        done
    fi
    
    echo "$notes"
}

add_release_notes() {
    local new_version=$1
    local notes=$2
    
    log_step "Adding release notes to manifest.yaml..."
    
    # Create temporary file
    local temp_file=$(mktemp)
    local in_release_notes=false
    local added=false
    
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"
        
        # Check if we're at the release-notes line
        if [[ $line == "release-notes: |" ]]; then
            in_release_notes=true
            added=true
            # Add new release notes
            echo -e "$notes" >> "$temp_file"
            echo "  " >> "$temp_file"
            echo "  ---" >> "$temp_file"
        fi
    done < "$MANIFEST_FILE"
    
    if [ "$added" = true ]; then
        mv "$temp_file" "$MANIFEST_FILE"
        log_success "Added release notes"
    else
        rm "$temp_file"
        log_warn "Could not find release-notes section in manifest.yaml"
        log_warn "Please add release notes manually"
    fi
}

# ==============================================================================
# Validation
# ==============================================================================

validate_changes() {
    local old_version=$1
    local new_version=$2
    
    log_step "Validating changes..."
    
    local errors=0
    
    # Check manifest.yaml
    if ! grep -q "version: ${new_version}" "$MANIFEST_FILE"; then
        log_error "❌ Version not updated in $MANIFEST_FILE"
        errors=$((errors + 1))
    else
        log_success "Version in $MANIFEST_FILE: ${new_version}"
    fi
    
    # Check docker_entrypoint.sh
    local entrypoint_count=$(grep -c "${new_version}" "$ENTRYPOINT_FILE" || echo "0")
    if [ "$entrypoint_count" -lt 3 ]; then
        log_error "❌ Version not fully updated in $ENTRYPOINT_FILE (found $entrypoint_count/3)"
        errors=$((errors + 1))
    else
        log_success "Version in $ENTRYPOINT_FILE: ${new_version} (${entrypoint_count} occurrences)"
    fi
    
    # Check importNotes.sh
    local import_count=$(grep -c "${new_version}" "$IMPORT_SCRIPT" || echo "0")
    if [ "$import_count" -lt 2 ]; then
        log_error "❌ Version not fully updated in $IMPORT_SCRIPT (found $import_count/2)"
        errors=$((errors + 1))
    else
        log_success "Version in $IMPORT_SCRIPT: ${new_version} (${import_count} occurrences)"
    fi
    
    # Check for leftover old versions (excluding release notes history)
    local leftover=$(grep -r "${old_version}" "$MANIFEST_FILE" "$ENTRYPOINT_FILE" "$IMPORT_SCRIPT" 2>/dev/null | grep -v "v${old_version} -" | wc -l)
    if [ "$leftover" -gt 0 ]; then
        log_warn "⚠️  Found $leftover occurrence(s) of old version ${old_version}"
        log_warn "This might be in release notes history (OK) or missed updates (check manually)"
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "All validations passed!"
        return 0
    else
        log_error "Validation failed with $errors error(s)"
        return 1
    fi
}

# ==============================================================================
# Git Operations
# ==============================================================================

git_commit_and_tag() {
    local new_version=$1
    
    echo ""
    echo -e "${YELLOW}Would you like to commit these changes to git? (y/n)${NC}"
    read -r commit_choice
    
    if [[ $commit_choice == "y" || $commit_choice == "Y" ]]; then
        log_step "Committing changes to git..."
        
        git add "$MANIFEST_FILE" "$ENTRYPOINT_FILE" "$IMPORT_SCRIPT"
        git commit -m "update: version ${new_version}"
        
        log_success "Changes committed"
        
        echo ""
        echo -e "${YELLOW}Would you like to create a git tag v${new_version}? (y/n)${NC}"
        read -r tag_choice
        
        if [[ $tag_choice == "y" || $tag_choice == "Y" ]]; then
            git tag "v${new_version}"
            log_success "Created tag v${new_version}"
            
            echo ""
            echo -e "${CYAN}To push changes and tag, run:${NC}"
            echo "  git push origin main"
            echo "  git push origin v${new_version}"
        fi
    else
        log_info "Skipping git operations"
        echo ""
        echo -e "${CYAN}To commit manually, run:${NC}"
        echo "  git add $MANIFEST_FILE $ENTRYPOINT_FILE $IMPORT_SCRIPT"
        echo "  git commit -m \"update: version ${new_version}\""
        echo "  git tag v${new_version}"
    fi
}

# ==============================================================================
# Main Logic
# ==============================================================================

show_usage() {
    echo "Usage: $0 [patch|minor|major|VERSION]"
    echo ""
    echo "Examples:"
    echo "  $0 patch        # Bump patch version (1.1.6 → 1.1.7)"
    echo "  $0 minor        # Bump minor version (1.1.6 → 1.2.0)"
    echo "  $0 major        # Bump major version (1.1.6 → 2.0.0)"
    echo "  $0 1.2.5        # Set specific version (1.1.6 → 1.2.5)"
    echo "  $0              # Interactive mode"
}

main() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Haven Start9 - Version Bump Script               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check if we're in the right directory
    if [ ! -f "$MANIFEST_FILE" ]; then
        log_error "manifest.yaml not found. Are you in the project root?"
        exit 1
    fi
    
    # Get current version
    local current_version=$(get_current_version)
    
    if [ -z "$current_version" ]; then
        log_error "Could not detect current version from $MANIFEST_FILE"
        exit 1
    fi
    
    log_info "Current version: ${BLUE}${current_version}${NC}"
    echo ""
    
    # Determine new version
    local new_version=""
    local bump_type=""
    
    if [ $# -eq 0 ]; then
        # Interactive mode
        echo -e "${YELLOW}Select version bump type:${NC}"
        echo "  1) patch (${current_version} → $(calculate_next_version $current_version patch))"
        echo "  2) minor (${current_version} → $(calculate_next_version $current_version minor))"
        echo "  3) major (${current_version} → $(calculate_next_version $current_version major))"
        echo "  4) custom version"
        echo ""
        read -p "Enter choice [1-4]: " choice
        
        case $choice in
            1)
                bump_type="patch"
                new_version=$(calculate_next_version $current_version patch)
                ;;
            2)
                bump_type="minor"
                new_version=$(calculate_next_version $current_version minor)
                ;;
            3)
                bump_type="major"
                new_version=$(calculate_next_version $current_version major)
                ;;
            4)
                read -p "Enter version (X.Y.Z): " new_version
                if ! validate_version "$new_version"; then
                    exit 1
                fi
                ;;
            *)
                log_error "Invalid choice"
                exit 1
                ;;
        esac
    else
        # Command line argument provided
        local arg=$1
        
        case $arg in
            patch|minor|major)
                bump_type=$arg
                new_version=$(calculate_next_version $current_version $arg)
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                # Assume it's a version number
                new_version=$arg
                if ! validate_version "$new_version"; then
                    exit 1
                fi
                ;;
        esac
    fi
    
    echo ""
    log_info "New version will be: ${GREEN}${new_version}${NC}"
    echo ""
    
    # Confirmation
    echo -e "${YELLOW}Proceed with version bump? (y/n)${NC}"
    read -r confirm
    
    if [[ ! $confirm == "y" && ! $confirm == "Y" ]]; then
        log_warn "Version bump cancelled"
        exit 0
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Starting version bump: ${current_version} → ${new_version}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Update files
    update_manifest_version "$current_version" "$new_version"
    update_default_versions "$current_version" "$new_version"
    
    # Prompt for release notes
    echo ""
    echo -e "${YELLOW}Would you like to add release notes now? (y/n)${NC}"
    read -r add_notes
    
    if [[ $add_notes == "y" || $add_notes == "Y" ]]; then
        local notes=$(prompt_release_notes "$new_version")
        add_release_notes "$new_version" "$notes"
    else
        log_warn "Skipping release notes. Don't forget to add them manually to manifest.yaml!"
    fi
    
    # Validate changes
    echo ""
    if ! validate_changes "$current_version" "$new_version"; then
        log_error "Version bump completed with errors. Please review changes manually."
        exit 1
    fi
    
    # Git operations
    if command -v git >/dev/null 2>&1 && [ -d .git ]; then
        git_commit_and_tag "$new_version"
    fi
    
    # Success summary
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ Version bump completed successfully!${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Review changes: git diff"
    echo "  2. Build package: make clean && make"
    echo "  3. Test package: make verify"
    echo "  4. Deploy to Start9"
    echo ""
    echo -e "${CYAN}Files updated:${NC}"
    echo "  • $MANIFEST_FILE"
    echo "  • $ENTRYPOINT_FILE"
    echo "  • $IMPORT_SCRIPT"
    echo ""
}

# Run main
main "$@"

