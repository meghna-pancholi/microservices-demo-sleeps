#!/bin/bash

# --- Start jaeger dashboard in background ---

# --- Delete existing jaeger pod ---
echo "---"
echo "Deleting existing jaeger pod..."
# Get the jaeger pod name
JAEGER_POD=$(kubectl get pods -n istio-system -l app=jaeger --no-headers -o custom-columns=":metadata.name")
if [ -n "$JAEGER_POD" ]; then
  kubectl delete pod "$JAEGER_POD" -n istio-system
  echo "Jaeger pod '$JAEGER_POD' deleted."
else
  echo "Jaeger pod not found. Skipping deletion."
fi

# --- Wait for jaeger pod to be ready ---
echo "---"
echo "Waiting for jaeger pod to be ready..."
if ! kubectl wait --for=condition=Ready pod -n istio-system -l app=jaeger --timeout=5m; then
  echo "Error: Jaeger pod did not become ready in time. Exiting."
  exit 1
fi
echo "Jaeger pod is ready."
# --- Start jaeger dashboard in background ---
echo "---"
echo "Starting jaeger dashboard in background..."
istio-1.26.0/bin/istioctl dashboard jaeger &
ISTIOCTL_PID=$!
echo "Jaeger dashboard started with PID: $ISTIOCTL_PID"

# --- Wait for jaeger dashboard to be accessible ---
echo "---"
echo "Waiting for jaeger dashboard to be accessible..."
TIMEOUT=60  # 60 seconds timeout
COUNT=0
while [ "$COUNT" -lt "$TIMEOUT" ]; do
  if curl -s http://localhost:16686/service/health | grep -q "ok"; then
    echo "Jaeger dashboard is accessible."
    break
  fi
  echo "Jaeger dashboard not ready yet. Waiting..."
  sleep 2
  COUNT=$((COUNT+2))
done

if [ "$COUNT" -eq "$TIMEOUT" ]; then
  echo "Error: Jaeger dashboard did not become accessible in time. Exiting."
  cleanup
fi

# --- Configuration Variables ---
HELM_VALUES_PATH="helm-chart/values.yaml"
HELM_CHART_NAME="md"
# It's better to fetch all traces and then filter/count locally,
# as Jaeger's 'limit' might not guarantee the exact number you want if
# there are more traces available.
JAEGER_URL="http://localhost:16686/jaeger/api/traces?service=frontend.default&limit=5000" # Increased limit
TARGET_TRACE_COUNT=500
OUTPUT_FILE="jaeger_traces.json" # This can be a base name now, the full name will be constructed later
echo "Jaeger dashboard is accessible."
NAMESPACE="default"
DEFAULT_CART_LATENCY1="0ms"
DEFAULT_CART_LATENCY2="0ms"
DEFAULT_CHECKOUT_LATENCY="0ms"
DEFAULT_CURRENCY_LATENCY="0ms"
DEFAULT_PRODUCT_CATALOG_LATENCY="0ms"
LOAD_GENERATION_INTERVAL_SECONDS=10 # How often to check for traces (adjust as needed)

# OUTPUT_FILE_WITH_PARAMS will be constructed AFTER parsing arguments


# --- Functions ---

# Function to clean up resources in case of script interruption
cleanup() {
  echo "" # Newline for cleaner output after potential interruption
  
  if [ -n "$ISTIOCTL_PID" ]; then
    echo "Killing jaeger dashboard with PID: $ISTIOCTL_PID"
    kill "$ISTIOCTL_PID" &>/dev/null
  fi
  
  echo "---"
  echo "Cleaning up Helm chart: $HELM_CHART_NAME in namespace $NAMESPACE..."
  helm uninstall "$HELM_CHART_NAME" --namespace "$NAMESPACE" &>/dev/null
  echo "Cleanup complete."
  exit 1 # Exit with an error code
}



# Trap Ctrl+C (SIGINT) and call the cleanup function
trap cleanup SIGINT

# --- Script Start ---
echo "---"
echo "Starting trace collection experiment..."

# Parse CLI arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -u|--users)
      USERS="$2"
      shift 2
      ;;
    -c1|--cartLatency1)
      CART_LATENCY1="$2"
      shift 2
      ;;
    -c2|--cartLatency2)
      CART_LATENCY2="$2"
      shift 2
      ;;
    -o|--checkoutLatency)
      CHECKOUT_LATENCY="$2"
      shift 2
      ;;
    -r|--currencyLatency)
      CURRENCY_LATENCY="$2"
      shift 2
      ;;
    -p|--productCatalogLatency)
      PRODUCT_CATALOG_LATENCY="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [-u|--users <number_of_users>] [-c1|--cartLatency1 <latency>] [-c2|--cartLatency2 <latency>] [-o|--checkoutLatency <latency>] [-r|--currencyLatency <latency>] [-p|--productCatalogLatency <latency>]"
      exit 1
      ;;
  esac
done

if [ -z "$USERS" ]; then
  USERS=100
  echo "No users specified, using default value: $USERS"
else
  echo "Using users: $USERS"
fi

if [ -z "$CART_LATENCY1" ]; then
  CART_LATENCY1=$DEFAULT_CART_LATENCY1
  echo "No cart replica 1 latency specified, using default value: $CART_LATENCY1"
else
  echo "Using cart replica 1 latency: $CART_LATENCY1"
fi

if [ -z "$CART_LATENCY2" ]; then
  CART_LATENCY2=$DEFAULT_CART_LATENCY2
  echo "No cart replica 2 latency specified, using default value: $CART_LATENCY2"
else
  echo "Using cart replica 2 latency: $CART_LATENCY2"
fi

if [ -z "$CHECKOUT_LATENCY" ]; then
  CHECKOUT_LATENCY=$DEFAULT_CHECKOUT_LATENCY
  echo "No checkout latency specified, using default value: $CHECKOUT_LATENCY"
else
  echo "Using checkout latency: $CHECKOUT_LATENCY"
fi

if [ -z "$CURRENCY_LATENCY" ]; then
  CURRENCY_LATENCY=$DEFAULT_CURRENCY_LATENCY
  echo "No currency latency specified, using default value: $CURRENCY_LATENCY"
else
  echo "Using currency latency: $CURRENCY_LATENCY"
fi

if [ -z "$PRODUCT_CATALOG_LATENCY" ]; then
  PRODUCT_CATALOG_LATENCY=$DEFAULT_PRODUCT_CATALOG_LATENCY
  echo "No product catalog latency specified, using default value: $PRODUCT_CATALOG_LATENCY"
else
  echo "Using product catalog latency: $PRODUCT_CATALOG_LATENCY"
fi

# --- Construct OUTPUT_FILE_WITH_PARAMS AFTER variables are set ---
OUTPUT_FILE_WITH_PARAMS="product_only_jaeger_traces_users_${USERS}"
if [ -n "$CART_LATENCY1" ] && [ "$CART_LATENCY1" != "$DEFAULT_CART_LATENCY1" ]; then
  OUTPUT_FILE_WITH_PARAMS="${OUTPUT_FILE_WITH_PARAMS}_cart1_${CART_LATENCY1}"
fi
if [ -n "$CART_LATENCY2" ] && [ "$CART_LATENCY2" != "$DEFAULT_CART_LATENCY2" ]; then
  OUTPUT_FILE_WITH_PARAMS="${OUTPUT_FILE_WITH_PARAMS}_cart2_${CART_LATENCY2}"
fi
if [ -n "$CHECKOUT_LATENCY" ] && [ "$CHECKOUT_LATENCY" != "$DEFAULT_CHECKOUT_LATENCY" ]; then
  OUTPUT_FILE_WITH_PARAMS="${OUTPUT_FILE_WITH_PARAMS}_checkout_${CHECKOUT_LATENCY}"
fi
if [ -n "$CURRENCY_LATENCY" ] && [ "$CURRENCY_LATENCY" != "$DEFAULT_CURRENCY_LATENCY" ]; then
  OUTPUT_FILE_WITH_PARAMS="${OUTPUT_FILE_WITH_PARAMS}_currency_${CURRENCY_LATENCY}"  
fi
if [ -n "$PRODUCT_CATALOG_LATENCY" ] && [ "$PRODUCT_CATALOG_LATENCY" != "$DEFAULT_PRODUCT_CATALOG_LATENCY" ]; then
  OUTPUT_FILE_WITH_PARAMS="${OUTPUT_FILE_WITH_PARAMS}_product_${PRODUCT_CATALOG_LATENCY}"
fi  
OUTPUT_FILE_WITH_PARAMS="${OUTPUT_FILE_WITH_PARAMS}.json"
# -----------------------------------------------------------------

# Update values.yaml with the new number of users and latencies
echo "Updating $HELM_VALUES_PATH..."

## YAML Update Functions using yq ##
#
# Prerequisite: Ensure yq is installed.
# For macOS: brew install yq
# For Linux: sudo snap install yq
# Or download binary from https://github.com/mikefarah/yq/releases
#

# Function to update a simple key-value pair using yq
update_yaml_value() {
  local file="$1"
  local key_path="$2" # e.g., ".loadGenerator.users" or ".checkoutService.extraLatency"
  local value="$3"
  
  # Corrected yq command: The filter and file path are separate arguments.
  # No need for 'eval' when passing arguments directly.
  if ! yq eval --inplace "${key_path} = \"${value}\"" "$file"; then
      echo "Error: Failed to update key '${key_path}' in '$file' using yq."
      exit 1
  fi
}

# Function to update cartService replica latency using yq
update_cart_replica_latency() {
  local file="$1"
  local replica_name="$2" # e.g., "cartservice-replica-1"
  local latency_value="$3"

  # Corrected yq command: Filter and file path are separate arguments.
  if ! yq eval --inplace "( .cartService.replicaConfigs[] | select(.name == \"${replica_name}\") ).extraLatency = \"${latency_value}\"" "$file"; then
      echo "Error: Failed to update extraLatency for '${replica_name}' in '$file' using yq."
      exit 1
  fi
}

# --- Apply the updates using the yq functions ---

# Update users (top-level key)
update_yaml_value "$HELM_VALUES_PATH" ".loadGenerator.users" "$USERS"

# Update cartService replica latencies
update_cart_replica_latency "$HELM_VALUES_PATH" "cartservice-replica-1" "$CART_LATENCY1"
update_cart_replica_latency "$HELM_VALUES_PATH" "cartservice-replica-2" "$CART_LATENCY2"

# Update checkoutService extraLatency
update_yaml_value "$HELM_VALUES_PATH" ".checkoutService.extraLatency" "$CHECKOUT_LATENCY"

# Update currencyService extraLatency
update_yaml_value "$HELM_VALUES_PATH" ".currencyService.extraLatency" "$CURRENCY_LATENCY"

# Update productCatalogService extraLatency
update_yaml_value "$HELM_VALUES_PATH" ".productCatalogService.extraLatency" "$PRODUCT_CATALOG_LATENCY"

if [ $? -ne 0 ]; then
  echo "Error: Failed to update $HELM_VALUES_PATH. Exiting."
  exit 1
fi
echo "$HELM_VALUES_PATH updated successfully."

# Install Helm chart
echo "Installing helm chart '$HELM_CHART_NAME' in namespace '$NAMESPACE'..."
if ! helm install "$HELM_CHART_NAME" helm-chart --values "$HELM_VALUES_PATH" --namespace "$NAMESPACE" --create-namespace; then
  echo "Error: Helm chart installation failed. Exiting."
  exit 1
fi
echo "Helm chart installed successfully."

echo "Target trace count: $TARGET_TRACE_COUNT"
echo "---"
# Wait for pods to be ready
echo "Waiting for pods in namespace '$NAMESPACE' to be ready (timeout: 5m)..."
if ! kubectl wait --for=condition=Ready pods --all -n "$NAMESPACE" --timeout=5m; then
  echo "Error: Pods did not become ready in time. Exiting."
  helm uninstall "$HELM_CHART_NAME" --namespace "$NAMESPACE" &>/dev/null
  exit 1
fi
echo "All pods are ready."

TRACE_COUNT=0
ITERATION=0
while [ "$TRACE_COUNT" -lt "$TARGET_TRACE_COUNT" ]; do
  ITERATION=$((ITERATION + 1))
  echo "---"
  echo "Iteration $ITERATION: Collecting traces..."

  # Generate load (assuming an external load generator is running)
  echo "Simulating load generation... (Ensure your load generator is active)"
  # If you need to trigger load generation from this script, add the command here.
  # For example: your_load_generator_command

  # Fetch traces from Jaeger
  echo "Fetching traces from Jaeger at $JAEGER_URL..."
  if ! curl -s "$JAEGER_URL" > "$OUTPUT_FILE_WITH_PARAMS"; then
    echo "Error: Failed to fetch traces from Jaeger. Retrying..."
    sleep "$LOAD_GENERATION_INTERVAL_SECONDS"
    continue # Skip to the next iteration
  fi

  # Parse trace count using jq
  # We use '.data | length' to get the number of traces in the 'data' array.
  # The '.total' field in Jaeger's API might not always reflect the actual
  # number of traces returned in the 'data' array, especially with limits.
  TEMP_TRACE_COUNT=$(jq '.data | length' "$OUTPUT_FILE_WITH_PARAMS")

  if [ -z "$TEMP_TRACE_COUNT" ] || [ "$TEMP_TRACE_COUNT" -lt 0 ]; then
    echo "Warning: Could not parse trace count from '$OUTPUT_FILE'. Skipping this iteration."
    TRACE_COUNT=0 # Reset or keep previous, depending on desired behavior
  else
    TRACE_COUNT="$TEMP_TRACE_COUNT"
  fi

  echo "Collected $TRACE_COUNT traces in this batch."

  # Check if we have enough traces
  if [ "$TRACE_COUNT" -lt "$TARGET_TRACE_COUNT" ]; then
    echo "Current total traces: $TRACE_COUNT. Target: $TARGET_TRACE_COUNT. Waiting for more traces..."
    sleep "$LOAD_GENERATION_INTERVAL_SECONDS"
  fi
done

echo "---"
echo "Reached $TARGET_TRACE_COUNT traces. Experiment finished."

# Uninstall Helm chart
helm uninstall "$HELM_CHART_NAME" --namespace "$NAMESPACE"
echo "Helm chart uninstalled."
echo "---"
echo "Script completed successfully."