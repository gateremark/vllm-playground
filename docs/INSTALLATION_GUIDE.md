# vLLM Playground - Installation Guide

## Ultra-Minimal Container Setup

This guide walks you through installing all dependencies in the ultra-minimal vLLM Playground container deployed on OpenShift/Kubernetes.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Installation Steps](#detailed-installation-steps)
- [Hardware-Specific Instructions](#hardware-specific-instructions)
- [Verification](#verification)
- [Starting the Application](#starting-the-application)
- [Troubleshooting](#troubleshooting)
- [Disk Space Management](#disk-space-management)
- [Next Steps](#next-steps)

---

## Prerequisites

### Access the Container

First, remote into your running pod:

```bash
oc exec -it deployment/vllm-playground-dev -n vllm-playground-dev -- /bin/bash
```

Or if using Kubernetes:

```bash
kubectl exec -it deployment/vllm-playground-dev -n vllm-playground-dev -- /bin/bash
```

### Fix "I have no name!" Issue (If Applicable)

If you see `[I have no name!@...]` prompt, run this command to add your UID to `/etc/passwd`:

```bash
echo "vllm:x:$(id -u):0:vllm user:/home/vllm:/bin/bash" >> /etc/passwd
```

Then verify:

```bash
whoami
# Should output: vllm
```

### Check Available Disk Space

Before starting, verify you have enough space:

```bash
df -h /workspace
```

**Recommended minimum:** 40GB free space
- PyTorch: ~2GB
- vLLM: 2-5GB
- WebUI dependencies: ~1GB
- Models: 5-50GB each

---

## Quick Start

### For CPU-Only Deployments

```bash
# 1. Upgrade pip
pip3 install --upgrade pip setuptools wheel --user

# 2. Install PyTorch and vLLM (CPU version - fastest to install)
pip3 install --user torch torchvision --index-url https://download.pytorch.org/whl/cpu
pip3 install --user vllm-cpu-only

# 3. Install WebUI dependencies
pip3 install --user -r /home/vllm/vllm-playground/requirements.txt

# 4. Verify installation
python3 -c "import flask, vllm, torch; print('✅ All dependencies installed!')"

# 5. Start the application
cd /home/vllm/vllm-playground && python3 app.py
```

### For GPU Deployments

```bash
# 1. Verify GPU access
nvidia-smi

# 2. Upgrade pip
pip3 install --upgrade pip setuptools wheel --user

# 3. Install PyTorch with CUDA support
pip3 install --user torch torchvision --index-url https://download.pytorch.org/whl/cu121

# 4. Install vLLM with GPU support
pip3 install --user vllm

# 5. Verify GPU is accessible to PyTorch
python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'GPU: {torch.cuda.get_device_name(0)}')"

# 6. Install WebUI dependencies
pip3 install --user -r /home/vllm/vllm-playground/requirements.txt

# 7. Start the application
cd /home/vllm/vllm-playground && python3 app.py
```

---

## Detailed Installation Steps

### Step 1: Verify Build Tools (Pre-installed)

The ultra-minimal container now includes essential build tools pre-installed:
- `gcc` and `gcc-c++` - C/C++ compilers
- `python3.11-devel` - Python development headers
- `git` - Version control
- `vim` - Text editor

You can verify they're installed:

```bash
gcc --version
python3-config --help
git --version
vim --version
```

**Note:** These tools were installed as root during the container build, so you don't need to install them manually.

---

### Step 2: Upgrade pip and Build Tools

Always start with the latest pip:

```bash
pip3 install --upgrade pip setuptools wheel --user
```

**Expected output:**
```
Successfully installed pip-XX.X.X setuptools-XX.X.X wheel-X.X.X
```

**Verify:**
```bash
pip3 --version
# Should show pip 24.x or newer
```

---

### Step 3: Install PyTorch and vLLM

**IMPORTANT:** Install vLLM first before WebUI dependencies. This allows you to verify GPU access and test vLLM functionality before installing the web interface.

Choose the installation method based on your hardware:

#### Option A: CPU Only (Fastest to Install, Works Everywhere)

```bash
# Install PyTorch CPU version
pip3 install --user torch torchvision --index-url https://download.pytorch.org/whl/cpu

# Install vLLM CPU-only version
pip3 install --user vllm-cpu-only
```

**Pros:**
- Fastest installation (~2-3 minutes)
- Works on any hardware
- Smallest size (~2GB)

**Cons:**
- Slower inference speed
- Limited to smaller models

**Installation time:** 3-5 minutes

---

#### Option B: CUDA GPU (Best Performance)

```bash
# Install PyTorch with CUDA 12.1 support
pip3 install --user torch torchvision --index-url https://download.pytorch.org/whl/cu121

# Install vLLM with CUDA support
pip3 install --user vllm
```

**Requirements:**
- NVIDIA GPU with CUDA support
- GPU accessible in the pod (requires GPU node and resource allocation)

**Pros:**
- Best performance
- Supports large models
- Fast inference

**Cons:**
- Larger installation size (~5-8GB)
- Requires GPU hardware
- Longer installation time

**Installation time:** 10-20 minutes

**Verify GPU access:**
```bash
nvidia-smi
# Should show your GPU(s)
```

---

#### Option C: ROCm (AMD GPU)

```bash
# Install PyTorch with ROCm 6.1 support
pip3 install --user torch torchvision --index-url https://download.pytorch.org/whl/rocm6.1

# Install vLLM with ROCm support
pip3 install --user vllm
```

**Requirements:**
- AMD GPU with ROCm support
- ROCm drivers installed on the node

**Installation time:** 10-20 minutes

---

### Step 4: Verify vLLM Installation

Before installing WebUI dependencies, verify that vLLM is working correctly:

**For CPU installations:**
```bash
python3 -c "import vllm; print(f'✅ vLLM version: {vllm.__version__}')"
```

**For GPU installations:**
```bash
# Verify CUDA is available
python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"

# Verify GPU details
python3 -c "import torch; print(f'GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"}')"

# Verify vLLM
python3 -c "import vllm; print(f'✅ vLLM version: {vllm.__version__}')"
```

**Expected output for GPU:**
```
CUDA available: True
GPU: Tesla T4
✅ vLLM version: 0.X.X
```

---

### Step 5: Install WebUI Dependencies

Now that vLLM is installed and working, install the WebUI dependencies:

```bash
pip3 install --user -r /home/vllm/vllm-playground/requirements.txt
```

**This will install:**
- Flask and Flask-CORS (web server)
- Gradio (UI components)
- Requests, aiohttp (API calls)
- Pandas, matplotlib (metrics and visualization)
- And other dependencies

**Installation time:** 2-5 minutes

**Verify:**
```bash
python3 -c "import flask; print(f'✅ Flask version: {flask.__version__}')"
python3 -c "import gradio; print(f'✅ Gradio version: {gradio.__version__}')"
```

---

### Step 6: Install llmcompressor (Optional)

For model quantization and compression:

```bash
pip3 install --user llmcompressor
```

**Use cases:**
- Compress models to reduce size
- Quantize models (FP16, INT8, INT4)
- Optimize models for deployment

**Installation time:** 1-2 minutes

---

## Hardware-Specific Instructions

### For CPU-Only Deployments

```bash
# Complete installation script for CPU
pip3 install --upgrade pip setuptools wheel --user

# Install vLLM first
pip3 install --user torch torchvision --index-url https://download.pytorch.org/whl/cpu
pip3 install --user vllm-cpu-only

# Verify vLLM works
python3 -c "import vllm, torch; print(f'PyTorch: {torch.__version__}'); print(f'vLLM: {vllm.__version__}'); print(f'Device: {torch.device(\"cpu\")}')"

# Install WebUI dependencies
pip3 install --user -r /home/vllm/vllm-playground/requirements.txt

# Verify all dependencies
python3 -c "import flask, gradio; print('✅ All dependencies installed!')"
```

---

### For GPU Deployments

**Step 1: Verify GPU Access**

```bash
nvidia-smi
# Should show your GPU info
```

If `nvidia-smi` fails, your pod doesn't have GPU access. Check your deployment configuration.

**Step 2: Install vLLM with GPU Support**

```bash
pip3 install --upgrade pip setuptools wheel --user

# Install PyTorch with CUDA support
pip3 install --user torch torchvision --index-url https://download.pytorch.org/whl/cu121

# Install vLLM
pip3 install --user vllm

# Verify GPU is accessible to PyTorch and vLLM
python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'GPU count: {torch.cuda.device_count()}'); print(f'GPU name: {torch.cuda.get_device_name(0)}')"
python3 -c "import vllm; print(f'✅ vLLM version: {vllm.__version__}')"
```

**Expected output:**
```
CUDA available: True
GPU count: 1 (or more)
GPU name: Tesla T4
✅ vLLM version: 0.X.X
```

**Step 3: Install WebUI Dependencies**

```bash
# Now install the WebUI dependencies
pip3 install --user -r /home/vllm/vllm-playground/requirements.txt

# Verify all dependencies
python3 -c "import flask, gradio; print('✅ All dependencies installed!')"
```

---

## Verification

### Verify All Dependencies

Run this comprehensive verification script:

```bash
python3 << 'EOF'
import sys

def check_import(module_name, display_name=None):
    display_name = display_name or module_name
    try:
        mod = __import__(module_name)
        version = getattr(mod, '__version__', 'unknown')
        print(f"✅ {display_name}: {version}")
        return True
    except ImportError as e:
        print(f"❌ {display_name}: NOT INSTALLED - {e}")
        return False

print("=" * 50)
print("Dependency Verification")
print("=" * 50)

# Core dependencies
check_import('flask', 'Flask')
check_import('gradio', 'Gradio')
check_import('torch', 'PyTorch')
check_import('vllm', 'vLLM')

# Optional dependencies
check_import('requests', 'Requests')
check_import('aiohttp', 'aiohttp')
check_import('pandas', 'Pandas')

# Check PyTorch GPU availability
try:
    import torch
    print(f"\n🖥️  PyTorch Device: {torch.device('cuda' if torch.cuda.is_available() else 'cpu')}")
    if torch.cuda.is_available():
        print(f"🎮 GPU Count: {torch.cuda.device_count()}")
        print(f"🎮 GPU Name: {torch.cuda.get_device_name(0)}")
    else:
        print("💻 Running on CPU")
except Exception as e:
    print(f"⚠️  Error checking PyTorch: {e}")

print("=" * 50)
EOF
```

---

## Starting the Application

### Option 1: Start the WebUI

```bash
cd /home/vllm/vllm-playground
python3 app.py
```

**Expected output:**
```
Starting vLLM Playground...
Running on: http://0.0.0.0:7860
```

**Access the WebUI:**
- If you have a Route configured: `https://<your-route-url>`
- Otherwise, set up port forwarding:
  ```bash
  oc port-forward deployment/vllm-playground-dev 7860:7860 -n vllm-playground-dev
  ```
  Then access: `http://localhost:7860`

---

### Option 2: Start vLLM Server Directly

For API-only usage:

```bash
vllm serve <model-name> --host 0.0.0.0 --port 8000
```

**Example:**
```bash
vllm serve facebook/opt-125m --host 0.0.0.0 --port 8000
```

**Access the API:**
```bash
curl http://localhost:8000/v1/models
```

---

## Troubleshooting

### Issue: Permission Denied for microdnf

**Solution:**
Skip Step 1 and proceed with pip installations. Most packages have pre-compiled wheels.

---

### Issue: "I have no name!" in Shell Prompt

**Solution:**
```bash
echo "vllm:x:$(id -u):0:vllm user:/home/vllm:/bin/bash" >> /etc/passwd
```

Exit and re-enter the pod for changes to take effect.

---

### Issue: Cannot Write to /etc/passwd

**Solution:**
Check if you have write permissions:
```bash
ls -la /etc/passwd
```

If not writable, contact your cluster administrator to ensure the container is properly configured for OpenShift arbitrary UIDs.

---

### Issue: Disk Space Full During Installation

**Check disk usage:**
```bash
df -h /workspace
du -sh /workspace/.cache
```

**Clean up cache:**
```bash
# Clear pip cache
pip3 cache purge

# Remove HuggingFace cache (if you have old models)
rm -rf /workspace/.cache/huggingface/hub/*
```

---

### Issue: Installation is Very Slow

**Causes:**
- Slow network connection
- Large package sizes (PyTorch is ~2GB)
- Disk I/O limitations

**Solutions:**
- Use `--no-cache-dir` flag for pip
- Install CPU version first (smaller), then upgrade to GPU if needed
- Check network connectivity: `ping google.com`

---

### Issue: Import Errors After Installation

**Verify paths:**
```bash
echo $PATH
ls -la ~/.local/bin/
```

**Update PATH (if needed):**
```bash
export PATH="/home/vllm/.local/bin:$PATH"
```

**Reinstall specific package:**
```bash
pip3 uninstall <package-name>
pip3 install --user <package-name> --force-reinstall
```

---

### Issue: CUDA Not Available After Installation

**Check GPU access:**
```bash
nvidia-smi
```

If this fails, your pod doesn't have GPU access. Update your deployment to request GPU resources.

**Example deployment snippet:**
```yaml
resources:
  limits:
    nvidia.com/gpu: 1
```

---

## Disk Space Management

### Check Disk Usage

```bash
# Overall disk usage
df -h

# Workspace usage
du -sh /workspace

# Cache directory
du -sh /workspace/.cache/huggingface/hub

# List all models and their sizes
du -sh /workspace/.cache/huggingface/hub/*
```

---

### Clean Up Space

```bash
# Clear pip cache
pip3 cache purge

# Remove specific model
rm -rf /workspace/.cache/huggingface/hub/models--<org>--<model-name>

# Clean up old Python packages
pip3 uninstall <old-package>
```

---

## Next Steps

### 1. Download a Model

```bash
python3 << 'EOF'
from transformers import AutoTokenizer, AutoModelForCausalLM

model_name = "facebook/opt-125m"  # Start with small model
print(f"Downloading {model_name}...")
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(model_name)
print("✅ Model downloaded successfully!")
print(f"📁 Cached in: /workspace/.cache/huggingface/hub/")
EOF
```

---

### 2. Test vLLM Server

```bash
# Start server in background
vllm serve facebook/opt-125m --host 0.0.0.0 --port 8000 &

# Wait a few seconds for startup
sleep 10

# Test the API
curl http://localhost:8000/v1/models
```

---

### 3. Use the WebUI

```bash
cd /home/vllm/vllm-playground
python3 app.py
```

Navigate to the exposed route URL and start using the playground!

---

### 4. Model Compression with llmcompressor (Optional)

```bash
python3 << 'EOF'
from llmcompressor.transformers import oneshot
from transformers import AutoTokenizer

# Example: Quantize a model
model_path = "facebook/opt-125m"
output_path = "/workspace/compressed_models/opt-125m-quantized"

# Apply quantization
oneshot(
    model=model_path,
    output_dir=output_path,
    recipe="autoquant",
)

print(f"✅ Compressed model saved to: {output_path}")
EOF
```

---

## Additional Resources

- **vLLM Documentation:** https://docs.vllm.ai/
- **HuggingFace Models:** https://huggingface.co/models
- **llmcompressor:** https://github.com/vllm-project/llm-compressor
- **Gated Models Guide:** See `docs/GATED_MODELS_GUIDE.md`
- **Troubleshooting:** See `docs/TROUBLESHOOTING.md`

---

## Summary of Installation Commands

### Minimal CPU Installation (Fastest)

```bash
# Upgrade pip
pip3 install --upgrade pip setuptools wheel --user

# Install vLLM first
pip3 install --user torch torchvision --index-url https://download.pytorch.org/whl/cpu
pip3 install --user vllm-cpu-only

# Verify vLLM
python3 -c "import vllm; print('✅ vLLM installed')"

# Install WebUI dependencies
pip3 install --user -r /home/vllm/vllm-playground/requirements.txt
```

### Full GPU Installation

```bash
# Optional: Install build dependencies
microdnf install -y gcc gcc-c++ python3.11-devel git

# Verify GPU access
nvidia-smi

# Upgrade pip
pip3 install --upgrade pip setuptools wheel --user

# Install vLLM with GPU support first
pip3 install --user torch torchvision --index-url https://download.pytorch.org/whl/cu121
pip3 install --user vllm

# Verify GPU is accessible
python3 -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"

# Install WebUI dependencies
pip3 install --user -r /home/vllm/vllm-playground/requirements.txt

# Optional: Install llmcompressor
pip3 install --user llmcompressor
```

---

## Getting Help

If you encounter issues not covered in this guide:

1. Check the logs: `python3 app.py 2>&1 | tee app.log`
2. Review troubleshooting docs: `docs/TROUBLESHOOTING.md`
3. Check vLLM documentation: https://docs.vllm.ai/
4. Open an issue in the repository

---

**Happy model serving with vLLM Playground!** 🚀

