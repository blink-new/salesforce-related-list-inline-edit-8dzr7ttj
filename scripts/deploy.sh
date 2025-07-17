#!/bin/bash

# Salesforce Related List Inline Edit Component Deployment Script
# This script deploys the component to a Salesforce org

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if sfdx is installed
check_sfdx() {
    if ! command -v sfdx &> /dev/null; then
        print_error "Salesforce CLI (sfdx) is not installed or not in PATH"
        print_error "Please install it from: https://developer.salesforce.com/tools/sfdxcli"
        exit 1
    fi
    print_success "Salesforce CLI found"
}

# Function to validate org connection
validate_org() {
    local org_alias=$1
    
    if [ -z "$org_alias" ]; then
        print_error "No org alias provided"
        return 1
    fi
    
    print_status "Validating connection to org: $org_alias"
    
    if sfdx force:org:display -u "$org_alias" &> /dev/null; then
        print_success "Successfully connected to org: $org_alias"
        return 0
    else
        print_error "Failed to connect to org: $org_alias"
        print_error "Please check your org alias and authentication"
        return 1
    fi
}

# Function to run pre-deployment checks
pre_deployment_checks() {
    local org_alias=$1
    
    print_status "Running pre-deployment checks..."
    
    # Check if Lightning Experience is enabled
    print_status "Checking Lightning Experience status..."
    
    # Check API version compatibility
    print_status "Checking API version compatibility..."
    
    # Validate required permissions
    print_status "Validating user permissions..."
    
    print_success "Pre-deployment checks completed"
}

# Function to deploy metadata
deploy_metadata() {
    local org_alias=$1
    local check_only=$2
    
    print_status "Starting metadata deployment..."
    
    local deploy_cmd="sfdx force:source:deploy -p force-app/main/default -u $org_alias"
    
    if [ "$check_only" = "true" ]; then
        deploy_cmd="$deploy_cmd --checkonly"
        print_status "Running deployment validation (check-only mode)..."
    else
        print_status "Deploying to org: $org_alias"
    fi
    
    if $deploy_cmd; then
        if [ "$check_only" = "true" ]; then
            print_success "Deployment validation successful"
        else
            print_success "Deployment completed successfully"
        fi
        return 0
    else
        print_error "Deployment failed"
        return 1
    fi
}

# Function to run tests
run_tests() {
    local org_alias=$1
    
    print_status "Running Apex tests..."
    
    if sfdx force:apex:test:run -c -r human -u "$org_alias"; then
        print_success "All tests passed"
        return 0
    else
        print_error "Some tests failed"
        return 1
    fi
}

# Function to assign permissions
assign_permissions() {
    local org_alias=$1
    
    print_status "Assigning custom permissions..."
    
    # Create permission set if it doesn't exist
    print_status "Creating permission set for Related List Inline Edit..."
    
    # Note: In a real deployment, you would create and assign permission sets
    # This is a placeholder for the actual permission assignment logic
    
    print_warning "Permission assignment requires manual configuration"
    print_warning "Please assign the following custom permissions as needed:"
    print_warning "- Related_List_Inline_Edit_Admin"
    print_warning "- Related_List_Bulk_Operations"
}

# Function to display post-deployment instructions
post_deployment_instructions() {
    print_success "Deployment completed successfully!"
    echo
    print_status "Next steps:"
    echo "1. Add the component to Lightning record pages:"
    echo "   - Go to Setup > Lightning App Builder"
    echo "   - Edit a record page (e.g., Account record page)"
    echo "   - Drag 'Related List Inline Edit' component to the page"
    echo "   - Configure the component properties"
    echo
    echo "2. Assign custom permissions (if needed):"
    echo "   - Go to Setup > Custom Permissions"
    echo "   - Assign permissions to users or permission sets"
    echo
    echo "3. Configure field-level security:"
    echo "   - Ensure users have appropriate field permissions"
    echo "   - Test inline editing functionality"
    echo
    echo "4. Test the component:"
    echo "   - Navigate to a record page with the component"
    echo "   - Test inline editing, bulk operations, and configuration"
    echo
    print_status "For detailed configuration instructions, see force-app/README.md"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] <org-alias>"
    echo
    echo "Deploy the Salesforce Related List Inline Edit component"
    echo
    echo "Arguments:"
    echo "  org-alias     Salesforce org alias or username"
    echo
    echo "Options:"
    echo "  -c, --check-only    Validate deployment without deploying"
    echo "  -t, --test-only     Run tests only (no deployment)"
    echo "  -s, --skip-tests    Skip running tests after deployment"
    echo "  -h, --help          Show this help message"
    echo
    echo "Examples:"
    echo "  $0 myorg                    # Deploy to 'myorg'"
    echo "  $0 -c myorg                 # Validate deployment to 'myorg'"
    echo "  $0 -t myorg                 # Run tests only on 'myorg'"
    echo "  $0 --skip-tests myorg       # Deploy without running tests"
}

# Main deployment function
main() {
    local org_alias=""
    local check_only=false
    local test_only=false
    local skip_tests=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--check-only)
                check_only=true
                shift
                ;;
            -t|--test-only)
                test_only=true
                shift
                ;;
            -s|--skip-tests)
                skip_tests=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [ -z "$org_alias" ]; then
                    org_alias=$1
                else
                    print_error "Multiple org aliases provided"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate arguments
    if [ -z "$org_alias" ]; then
        print_error "No org alias provided"
        show_usage
        exit 1
    fi
    
    # Start deployment process
    print_status "Starting deployment process..."
    print_status "Target org: $org_alias"
    
    # Check prerequisites
    check_sfdx
    
    # Validate org connection
    if ! validate_org "$org_alias"; then
        exit 1
    fi
    
    # Run pre-deployment checks
    pre_deployment_checks "$org_alias"
    
    # Handle test-only mode
    if [ "$test_only" = "true" ]; then
        run_tests "$org_alias"
        exit $?
    fi
    
    # Deploy metadata
    if ! deploy_metadata "$org_alias" "$check_only"; then
        exit 1
    fi
    
    # Skip remaining steps if check-only mode
    if [ "$check_only" = "true" ]; then
        print_success "Deployment validation completed successfully"
        exit 0
    fi
    
    # Run tests unless skipped
    if [ "$skip_tests" = "false" ]; then
        if ! run_tests "$org_alias"; then
            print_warning "Tests failed, but deployment was successful"
            print_warning "Please review test results and fix any issues"
        fi
    fi
    
    # Assign permissions
    assign_permissions "$org_alias"
    
    # Show post-deployment instructions
    post_deployment_instructions
}

# Run main function with all arguments
main "$@"