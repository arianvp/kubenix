# Example: kubernetes nginx deployment

A simple example creating kubernetes nginx deployment and associated docker
image

## Usage

### Building and applying kubernetes configuration

```
kubectl apply -f $(nix-build --no-out-link -A result)
```

### Building and pushing docker images

```
nix run -f ./. pushDockerImages -c copy-docker-images
```

### Running tests

Test will spawn vm with kubernetes and run test script, which checks if everyting
works as expected.

```
nix build -f ./. test-script
cat result | jq '.'
```
