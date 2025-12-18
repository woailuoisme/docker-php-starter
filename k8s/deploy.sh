#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="development"
NAMESPACE="lunchbox-dev"
KUBE_CONTEXT=""
DRY_RUN=false
FORCE=false

# Function to print colored output
print_info() {
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

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Deploy Lunchbox application to Kubernetes"
    echo ""
    echo "Options:"
    echo "  -e, --environment ENV    Deployment environment (development|staging|production) [default: development]"
    echo "  -n, --namespace NS       Kubernetes namespace [default: based on environment]"
    echo "  -c, --context CONTEXT    Kubernetes context to use"
    echo "  -d, --dry-run            Perform dry run without applying changes"
    echo "  -f, --force              Force deployment without confirmation"
    echo "  -h, --help               Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -e development        # Deploy to development environment"
    echo "  $0 -e production -c prod # Deploy to production using 'prod' context"
    echo "  $0 -d -e staging         # Dry run for staging environment"
}

# Function to parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -c|--context)
                KUBE_CONTEXT="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Function to validate environment
validate_environment() {
    case $ENVIRONMENT in
        development|staging|production)
            # Set default namespace if not provided
            if [[ -z "$NAMESPACE" ]]; then
                case $ENVIRONMENT in
                    development) NAMESPACE="lunchbox-dev" ;;
                    staging) NAMESPACE="lunchbox-staging" ;;
                    production) NAMESPACE="lunchbox-prod" ;;
                esac
            fi
            ;;
        *)
            print_error "Invalid environment: $ENVIRONMENT"
            print_error "Valid environments: development, staging, production"
            exit 1
            ;;
    esac
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."

    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi

    # Check if kustomize is installed
    if ! command -v kustomize &> /dev/null; then
        print_warning "kustomize is not installed, using kubectl kustomize"
    fi

    # Set kubectl context if specified
    if [[ -n "$KUBE_CONTEXT" ]]; then
        if ! kubectl config get-contexts "$KUBE_CONTEXT" &> /dev/null; then
            print_error "Kubernetes context '$KUBE_CONTEXT' not found"
            exit 1
        fi
        kubectl config use-context "$KUBE_CONTEXT"
        print_info "Using Kubernetes context: $KUBE_CONTEXT"
    fi

    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi

    print_success "Prerequisites check passed"
}

# Function to create namespace if it doesn't exist
create_namespace() {
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        print_info "Creating namespace: $NAMESPACE"
        if [[ "$DRY_RUN" = false ]]; then
            kubectl create namespace "$NAMESPACE"
            print_success "Namespace $NAMESPACE created"
        else
            print_info "DRY RUN: Would create namespace $NAMESPACE"
        fi
    else
        print_info "Namespace $NAMESPACE already exists"
    fi
}

# Function to deploy secrets (placeholder - should be handled by external secret management)
deploy_secrets() {
    print_warning "Secrets deployment should be handled by external secret management system"
    print_info "Please ensure secrets are properly configured for environment: $ENVIRONMENT"
}

# Function to build and deploy with kustomize
deploy_with_kustomize() {
    local overlay_dir="overlays/$ENVIRONMENT"

    if [[ ! -d "$overlay_dir" ]]; then
        print_error "Overlay directory not found: $overlay_dir"
        exit 1
    fi

    print_info "Building manifests for environment: $ENVIRONMENT"

    if [[ "$DRY_RUN" = true ]]; then
        print_info "DRY RUN: Showing what would be deployed"
        if command -v kustomize &> /dev/null; then
            kustomize build "$overlay_dir"
        else
            kubectl kustomize "$overlay_dir"
        fi
        return
    fi

    # Apply the configuration
    print_info "Deploying to environment: $ENVIRONMENT, namespace: $NAMESPACE"

    if command -v kustomize &> /dev/null; then
        kustomize build "$overlay_dir" | kubectl apply -f -
    else
        kubectl apply -k "$overlay_dir"
    fi

    print_success "Deployment completed"
}

# Function to wait for deployment to be ready
wait_for_deployment() {
    if [[ "$DRY_RUN" = true ]]; then
        return
    fi

    print_info "Waiting for deployments to be ready..."

    # Wait for nginx deployment
    kubectl rollout status deployment/nginx -n "$NAMESPACE" --timeout=300s

    # Wait for php-fpm deployment
    kubectl rollout status deployment/php-fpm -n "$NAMESPACE" --timeout=300s

    # Wait for postgres statefulset
    kubectl rollout status statefulset/postgres -n "$NAMESPACE" --timeout=300s

    print_success "All deployments are ready"
}

# Function to display deployment status
show_deployment_status() {
    if [[ "$DRY_RUN" = true ]]; then
        return
    fi

    print_info "Deployment status:"
    echo ""

    # Show pods
    kubectl get pods -n "$NAMESPACE" -o wide

    echo ""
    print_info "Services:"
    kubectl get services -n "$NAMESPACE"

    echo ""
    print_info "Persistent volume claims:"
    kubectl get pvc -n "$NAMESPACE"
}

# Function to confirm deployment
confirm_deployment() {
    if [[ "$FORCE" = true ]]; then
        return
    fi

    echo ""
    print_warning "You are about to deploy to:"
    echo "  Environment:  $ENVIRONMENT"
    echo "  Namespace:    $NAMESPACE"
    echo "  Context:      $(kubectl config current-context)"

    if [[ "$DRY_RUN" = true ]]; then
        print_info "This is a dry run - no changes will be applied"
        return
    fi

    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled"
        exit 0
    fi
}

# Main function
main() {
    print_info "Starting Lunchbox deployment"

    # Parse command line arguments
    parse_args "$@"

    # Validate environment
    validate_environment

    # Check prerequisites
    check_prerequisites

    # Confirm deployment
    confirm_deployment

    # Create namespace
    create_namespace

    # Deploy secrets
    deploy_secrets

    # Deploy with kustomize
    deploy_with_kustomize

    # Wait for deployment to be ready
    wait_for_deployment

    # Show deployment status
    show_deployment_status

    print_success "Lunchbox deployment completed successfully!"
    echo ""
    print_info "Next steps:"
    print_info "1. Check application logs: kubectl logs -n $NAMESPACE deployment/nginx"
    print_info "2. Monitor application: kubectl get all -n $NAMESPACE"
    print_info "3. Access the application through the nginx service"
}

# Run main function with all arguments
main "$@"
