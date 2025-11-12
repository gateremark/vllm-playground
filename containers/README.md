# vLLM Playground Container Images

This directory contains multiple Containerfile variants optimized for different use cases and size requirements.

## Container Variants

### 1. Containerfile (Ultra Minimal - ~800MB - 1.2GB)
**Smallest practical image with build tools**

**What's included:**
- Red Hat UBI9 Minimal base image
- Python 3.11 + development headers
- Build tools (gcc, gcc-c++, git, vim)
- pip (basic version)
- Application code only
- curl-minimal (for health checks)

**What's NOT included:**
- Virtual environment
- Any Python packages (no requirements.txt)
- vLLM
- PyTorch

**Use this when:**
- You need a small image size with build capability
- You want maximum flexibility to install specific versions
- Storage/bandwidth is limited
- You're deploying to environments requiring manual dependency installation

**Installation required after deployment:**
```bash
# 1. Upgrade pip
pip3 install --upgrade pip setuptools wheel --user

# 2. Install vLLM (GPU example)
pip3 install --user torch torchvision --index-url https://download.pytorch.org/whl/cu121
pip3 install --user vllm

# 3. Install WebUI dependencies
pip3 install --user -r /home/vllm/vllm-playground/requirements.txt
```

---

### 2. Containerfile.app (Lightweight - ~2GB - 3GB)
**Balanced approach with WebUI dependencies pre-installed**

**What's included:**
- Red Hat UBI9 Minimal base image
- Python 3.11 + development tools
- Virtual environment
- All WebUI dependencies (Flask, requests, etc.)
- Build tools for compilation

**What's NOT included:**
- vLLM
- PyTorch

**Use this when:**
- You want faster startup with WebUI dependencies ready
- You still want flexibility for vLLM installation
- Moderate image size is acceptable
- You don't want to install basic dependencies manually

**Installation required after deployment:**
```bash
# Activate virtual environment
source /home/vllm/vllm_env/bin/activate

# Install vLLM (GPU example)
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121
pip install vllm
```

---

### 3. Containerfile.cuda (Full-Featured - ~15GB - 20GB)
**Complete image with everything pre-installed**

**What's included:**
- Red Hat UBI9 Minimal base image
- Python 3.11 + development tools
- PyTorch with CUDA support
- vLLM with GPU support
- All WebUI dependencies
- CUDA libraries

**What's NOT included:**
- Nothing - it's ready to run!

**Use this when:**
- You have good storage/bandwidth
- You want zero-setup deployment
- You're running on GPU-enabled nodes
- Build time is less important than runtime convenience

**Installation required after deployment:**
- None! Ready to use immediately.

---

## Build Instructions

### Build Ultra Minimal Image (with build tools)
```bash
podman build -f containers/Containerfile -t vllm-playground:minimal .
```

### Build Lightweight Image (with WebUI deps)
```bash
podman build -f containers/Containerfile.app -t vllm-playground:lightweight .
```

### Build Full Image (GPU) - if Containerfile.cuda exists
```bash
podman build -f containers/Containerfile.cuda -t vllm-playground:cuda .
```

### Build vLLM Server Image - if Containerfile.vllm exists
```bash
podman build -f containers/Containerfile.vllm -t vllm-playground:vllm .
```

## Run Instructions

All variants use the same run command:

```bash
podman run -d \
  -p 7860:7860 \
  -p 8000:8000 \
  --name vllm-playground \
  vllm-playground:minimal
```

For GPU support (with CUDA):
```bash
podman run -d \
  -p 7860:7860 \
  -p 8000:8000 \
  --device nvidia.com/gpu=all \
  --security-opt=label=disable \
  --name vllm-playground \
  vllm-playground:cuda
```

## Expected Image Sizes

| Variant | Compressed | Uncompressed | Build Time | Startup Time |
|---------|-----------|--------------|------------|--------------|
| **minimal** | ~500MB | ~800MB - 1.2GB | ~3-5 min | Instant (no deps) |
| **lightweight** | ~800MB | ~2GB - 3GB | ~5-10 min | Fast (only vLLM needed) |
| **cuda** | ~6GB | ~15GB - 20GB | ~30-60 min | Ready immediately |

## Comparison Chart

```
Feature                  | minimal | lightweight | cuda
------------------------|---------|-------------|------
Base OS                  |    ✅   |     ✅      |  ✅
Python 3.11              |    ✅   |     ✅      |  ✅
Build Tools              |    ✅   |     ✅      |  ✅
Virtual Environment      |    ❌   |     ✅      |  ✅
WebUI Dependencies       |    ❌   |     ✅      |  ✅
PyTorch                  |    ❌   |     ❌      |  ✅
vLLM                     |    ❌   |     ❌      |  ✅
CUDA Support             |    ❌   |     ❌      |  ✅
------------------------|---------|-------------|------
Image Size               | ~1.2GB  |   ~2GB      | ~15GB
Setup Required           |   High  |   Medium    |  None
Flexibility              |   High  |   Medium    |  Low
Network/Storage Impact   |   Low   |   Medium    |  High
```

## Recommendation

- **Development/Testing**: Use `Containerfile` (ultra-minimal with build tools)
- **Production (GPU)**: Use `Containerfile.cuda` if you have storage
- **Production (CPU)**: Use `Containerfile.app` (lightweight) and install vllm-cpu-only
- **Edge/IoT**: Use `Containerfile` (smallest with build capability)
- **Air-gapped**: Use `Containerfile.cuda` (everything pre-bundled)

## OpenShift/Kubernetes Deployment

For OpenShift deployments, the ultra-minimal variant is recommended:

```yaml
# Use in your deployment YAML
spec:
  containers:
  - name: vllm-playground
    image: your-registry/vllm-playground:0.1
    # Container includes build tools (gcc, git)
    # Users install dependencies manually after deployment
```

See `deployments/` directory for complete examples.

## Troubleshooting

### Image still too large?

If even the minimal image is too large, consider:

1. **Use a different base image**: Alpine Linux (~5MB base) instead of UBI9
2. **Multi-stage builds**: Build in one stage, copy only runtime files to final stage
3. **Distroless images**: Google's distroless Python images
4. **External dependencies**: Mount requirements from a volume instead of copying

### Build fails with space issues?

```bash
# Clean up build cache
podman system prune -a

# Build with no cache
podman build --no-cache -f containers/Containerfile.minimal -t vllm-playground:minimal .
```

### Container starts but dependencies missing?

This is expected for minimal/lightweight variants. Follow the installation instructions shown when the container starts, or check the startup script at `/home/vllm/start.sh`.

### "Address already in use" error when rerunning?

If you lose connection and try to restart the playground:

```
ERROR: [Errno 98] error while attempting to bind on address ('0.0.0.0', 7860): address already in use
```

**Quick Fix**: Simply rerun the script - it will automatically detect and kill the old process:

```bash
python run.py
```

**Manual Fix**: Use the kill script:

```bash
python scripts/kill_playground.py
```

For detailed troubleshooting, see: [Container Troubleshooting Guide](../docs/CONTAINER_TROUBLESHOOTING.md)
