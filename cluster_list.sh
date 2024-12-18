#!/bin/bash
# Strict mode
set -euo pipefail

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Error handling function
handle_error() {
    log "ERROR: $*"
    exit 1
}

# Function to display a section with a title and table
print_section() {
    local title="$1"
    echo -e "\n$title"
    echo "$(printf -- '-%.0s' {1..80})"
}

# List Kubernetes resources
list_kubernetes_resources() {
    log "Listing Kubernetes Services, Pods, and Deployments"
    
    # Check if kubectl is configured
    if ! kubectl cluster-info > /dev/null 2>&1; then
        handle_error "kubectl is not configured for this cluster. Ensure you have access."
    fi

    # Get Services
    print_section "Following are the Kubernetes Services provisioned for Denodo Hands-on Learning"
    kubectl get services --all-namespaces \
        --no-headers \
        -o custom-columns=\
"NAMESPACE:.metadata.namespace,\
NAME:.metadata.name,\
CLUSTER-IP:.spec.clusterIP,\
PORTS:.spec.ports[*].port" \
        2>/dev/null || echo "No services found"

    # Get Pods
    print_section "Following are the Kubernetes Pods provisioned for Denodo Hands-on Learning"
    kubectl get pods --all-namespaces \
        --no-headers \
        -o custom-columns=\
"NAMESPACE:.metadata.namespace,\
NAME:.metadata.name,\
STATUS:.status.phase" \
        2>/dev/null || echo "No pods found"

    # Get Deployments
    print_section "Following are the Kubernetes Deployments provisioned for Denodo Hands-on Learning"
    kubectl get deployments --all-namespaces \
        --no-headers \
        -o custom-columns=\
"NAMESPACE:.metadata.namespace,\
NAME:.metadata.name,\
REPLICAS:.status.replicas,\
AVAILABLE:.status.availableReplicas" \
        2>/dev/null || echo "No deployments found"
}

# List GKE clusters and node pools
list_gke_resources() {
    log "Listing GKE Clusters and Node Pools"
    print_section "Following are the GKE Clusters provisioned for Denodo Hands-on Learning"
    gcloud container clusters list \
        --format="table(name,location,currentMasterVersion,status)" \
        2>/dev/null || echo "No GKE clusters found"

    # Get Node Pool details including machine types
    print_section "Following are the GKE Node Pools and their Machine Types"
    for CLUSTER in $(gcloud container clusters list --format="value(name,location)" 2>/dev/null); do
        CLUSTER_NAME=$(echo $CLUSTER | cut -d' ' -f1)
        CLUSTER_LOCATION=$(echo $CLUSTER | cut -d' ' -f2)
        
        gcloud container node-pools list \
            --cluster=$CLUSTER_NAME \
            --location=$CLUSTER_LOCATION \
            --format="table(name,config.machineType,initialNodeCount,nodeConfig.diskSizeGb,version)" \
            2>/dev/null || echo "No node pools found for cluster: $CLUSTER_NAME"
    done
}

# List VM instances in the cluster
list_compute_instances() {
    log "Listing Compute Engine Instances"
    print_section "Following are the Compute Engine Instances for Denodo Hands-on Learning"
    gcloud compute instances list \
        --format="table(name,zone,machineType.basename(),status,networkInterfaces[0].networkIP)" \
        2>/dev/null || echo "No compute instances found"
}

# List storage buckets
list_storage_resources() {
    log "Listing Storage Resources"
    print_section "Following are the Storage Buckets provisioned for Denodo Hands-on Learning"
    gcloud storage buckets list \
        --format="table(name,location,storageClass)" \
        2>/dev/null || echo "No storage buckets found"
}

# Main execution
main() {
    log "Fetching Denodo Deployment Details"
    list_kubernetes_resources
    list_gke_resources
    list_compute_instances
    list_storage_resources
    log "All services listed successfully!"
}

# Execute main function
main
