# Request Hedging Configuration for Microservices

This document explains how to configure request hedging using Istio Virtual Services and EnvoyFilters to reduce tail latency in your microservices architecture.

## Overview

Request hedging is a technique that sends multiple requests to different service instances in parallel to reduce tail latency. When one request is slow, the faster response from another instance can be used, improving overall response times.

## Architecture

The configuration uses:
- **Istio Virtual Services**: For traffic routing and load balancing
- **EnvoyFilters**: For implementing request hedging policies
- **Helm Chart Configuration**: For centralized management of hedging settings

## Configuration

### 1. Enable Request Hedging

In your `values.yaml`, enable request hedging globally:

```yaml
requestHedging:
  enabled: true
  default:
    initial_requests: 1
    additional_request_chance:
      numerator: 1
      denominator: HUNDRED
    hedge_on_per_try_timeout: true
    max_requests: 2
```

### 2. Service-Specific Configuration

Configure hedging for specific service-to-service communication:

```yaml
requestHedging:
  services:
    frontend:
      productcatalogservice:
        enabled: true
        initial_requests: 1
        additional_request_chance:
          numerator: 1
          denominator: HUNDRED
        hedge_on_per_try_timeout: true
        max_requests: 2
      recommendationservice:
        enabled: true
        # ... similar configuration
```

### 3. Enable Virtual Services

Ensure Virtual Services are enabled for all services:

```yaml
frontend:
  virtualService:
    create: true
    hosts:
    - "*"
    gateway:
      name: asm-ingressgateway
      namespace: asm-ingress
      labelKey: asm
      labelValue: ingressgateway

productCatalogService:
  virtualService:
    create: true
    hosts:
    - "productcatalogservice.local"
```

## Parameters Explained

### Hedge Policy Parameters

- **`initial_requests`**: Number of requests to send initially (default: 1)
- **`additional_request_chance`**: Probability of sending additional requests
  - `numerator`: Number of additional requests (default: 1)
  - `denominator`: Denominator for probability calculation (HUNDRED = 100%)
- **`hedge_on_per_try_timeout`**: Whether to hedge on timeout (default: true)
- **`max_requests`**: Maximum total requests allowed (default: 2)

### Retry Policy Parameters

- **`retry_on`**: Conditions for retrying requests
- **`num_retries`**: Number of retry attempts
- **`per_try_timeout`**: Timeout for each retry attempt
- **`retry_host_predicate`**: Host selection strategy for retries

## Service Dependencies

The current configuration implements hedging for these critical paths:

1. **Frontend → Product Catalog Service**: Product listing and search
2. **Frontend → Recommendation Service**: Product recommendations
3. **Frontend → Cart Service**: Shopping cart operations
4. **Checkout Service → Cart Service**: Order processing
5. **Checkout Service → Product Catalog Service**: Product validation
6. **Checkout Service → Currency Service**: Price conversion
7. **Recommendation Service → Product Catalog Service**: Product data access

## Deployment

### 1. Install with Request Hedging

```bash
helm install md helm-chart/ \
  --set requestHedging.enabled=true \
  --set frontend.virtualService.create=true \
  --set productCatalogService.virtualService.create=true \
  --set recommendationService.virtualService.create=true \
  --set cartService.virtualService.create=true \
  --set checkoutService.virtualService.create=true
```

### 2. Customize Hedging Parameters

```bash
helm install md helm-chart/ \
  --set requestHedging.enabled=true \
  --set requestHedging.services.frontend.productcatalogservice.max_requests=3 \
  --set requestHedging.services.frontend.productcatalogservice.initial_requests=2
```

### 3. Disable Hedging for Specific Services

```bash
helm install md helm-chart/ \
  --set requestHedging.enabled=true \
  --set requestHedging.services.frontend.productcatalogservice.enabled=false
```

## Monitoring and Observability

### 1. Check EnvoyFilter Status

```bash
kubectl get envoyfilters -n default
```

### 2. Verify Virtual Services

```bash
kubectl get virtualservices -n default
```

### 3. Monitor Request Patterns

Use Istio's telemetry to monitor:
- Request latency percentiles
- Success/failure rates
- Request distribution across service instances

```bash
# View metrics in Grafana or Kiali
kubectl port-forward svc/kiali 20001:20001 -n istio-system
```

## Performance Tuning

### 1. Adjust Hedging Parameters

For high-traffic services:
```yaml
requestHedging:
  services:
    frontend:
      productcatalogservice:
        initial_requests: 2
        max_requests: 3
        additional_request_chance:
          numerator: 2
          denominator: HUNDRED
```

### 2. Optimize for Latency vs. Resource Usage

- **Lower latency**: Increase `initial_requests` and `max_requests`
- **Lower resource usage**: Decrease `additional_request_chance`

### 3. Service-Specific Tuning

```yaml
# For critical user-facing services
frontend:
  productcatalogservice:
    initial_requests: 2
    max_requests: 3

# For background services
recommendationservice:
  productcatalogservice:
    initial_requests: 1
    max_requests: 2
```

## Troubleshooting

### 1. EnvoyFilter Warnings

If you see warnings about unknown fields:
```
Envoy filter: unknown field "hedge_policy" in envoy.config.route.v3.Route
```

This is expected and doesn't affect functionality. The fields are valid in newer Envoy versions.

### 2. Check Service Discovery

Ensure services can discover each other:
```bash
kubectl exec -it deployment/frontend -- nslookup productcatalogservice
```

### 3. Verify Istio Sidecar Injection

Check that Istio sidecars are running:
```bash
kubectl get pods -l app=frontend -o jsonpath='{.items[0].spec.containers[*].name}'
```

## Best Practices

1. **Start Conservative**: Begin with `initial_requests: 1` and `max_requests: 2`
2. **Monitor Impact**: Use metrics to measure latency improvement vs. resource cost
3. **Service-Specific Tuning**: Different services may need different hedging strategies
4. **Circuit Breakers**: Combine with circuit breakers for robust fault tolerance
5. **Load Testing**: Test under realistic load to validate configuration

## Example Configurations

### High-Performance Configuration

```yaml
requestHedging:
  enabled: true
  services:
    frontend:
      productcatalogservice:
        enabled: true
        initial_requests: 2
        max_requests: 3
        additional_request_chance:
          numerator: 2
          denominator: HUNDRED
        hedge_on_per_try_timeout: true
```

### Conservative Configuration

```yaml
requestHedging:
  enabled: true
  services:
    frontend:
      productcatalogservice:
        enabled: true
        initial_requests: 1
        max_requests: 2
        additional_request_chance:
          numerator: 1
          denominator: HUNDRED
        hedge_on_per_try_timeout: true
```

## Related Documentation

- [Istio Traffic Management](https://istio.io/latest/docs/concepts/traffic-management/)
- [EnvoyFilter Configuration](https://istio.io/latest/docs/reference/config/networking/envoy-filter/)
- [Request Hedging Best Practices](https://istio.io/latest/docs/ops/best-practices/performance/) 