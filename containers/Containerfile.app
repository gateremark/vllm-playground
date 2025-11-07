# vLLM Playground Container - Lightweight Edition
# Based on Red Hat Universal Base Image 9 Minimal
# This container ONLY includes vLLM Playground dependencies
# Users must install vLLM separately after deployment (via pip or remote installation)
# 
# This approach significantly reduces image size (~20GB -> ~2GB)
# Ideal for faster deployment to OpenShift/Kubernetes clusters

FROM registry.redhat.io/ubi9-minimal:latest

USER 0
# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    WEBUI_PORT=7860 \
    VLLM_PORT=8000 \
    HOME=/home/vllm \
    PYTHON_VERSION=3.11

# Install Python 3.11 and minimal build dependencies
# Note: UBI9 uses microdnf (same as Fedora Minimal)
# curl-minimal is already pre-installed in ubi9-minimal
RUN microdnf install -y \
    python3.11 \
    python3.11-devel \
    python3.11-pip \
    gcc \
    gcc-c++ \
    make \
    git \
    openssl \
    openssl-devel \
    tar \
    gzip \
    && microdnf clean all && \
    ln -sf /usr/bin/python3.11 /usr/bin/python3 && \
    ln -sf /usr/bin/pip3.11 /usr/bin/pip3

# Create non-root user
RUN useradd -m -u 1001 -s /bin/bash vllm

# Build everything as root, set working directory
WORKDIR /home/vllm

# Create virtual environment and install ONLY basic pip dependencies
# vLLM and PyTorch will be installed by the user later
RUN python3 -m venv vllm_env && \
    source vllm_env/bin/activate && \
    pip install --no-cache-dir --upgrade pip setuptools wheel

# Copy the vLLM Playground project files
COPY . /home/vllm/vllm-playground/

# Install ONLY WebUI dependencies (no vLLM, no PyTorch)
RUN source vllm_env/bin/activate && \
    cd vllm-playground && \
    pip install --no-cache-dir -r requirements.txt

# Set ownership of all files to vllm user
RUN chown -R 1001:1001 /home/vllm

# Expose ports
# 7860 - WebUI interface
# 8000 - vLLM API server (default)
EXPOSE 7860 8000

# Set the working directory to the WebUI
WORKDIR /home/vllm/vllm-playground

# Create a startup script
RUN echo '#!/bin/bash' > /home/vllm/start.sh && \
    echo 'source /home/vllm/vllm_env/bin/activate' >> /home/vllm/start.sh && \
    echo 'cd /home/vllm/vllm-playground' >> /home/vllm/start.sh && \
    echo '' >> /home/vllm/start.sh && \
    echo '# Check if vLLM is installed' >> /home/vllm/start.sh && \
    echo 'if ! python3 -c "import vllm" 2>/dev/null; then' >> /home/vllm/start.sh && \
    echo '    echo "================================================"' >> /home/vllm/start.sh && \
    echo '    echo "WARNING: vLLM is not installed!"' >> /home/vllm/start.sh && \
    echo '    echo "This is a lightweight container. Please install vLLM manually:"' >> /home/vllm/start.sh && \
    echo '    echo ""' >> /home/vllm/start.sh && \
    echo '    echo "For CUDA (GPU):"' >> /home/vllm/start.sh && \
    echo '    echo "  pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121"' >> /home/vllm/start.sh && \
    echo '    echo "  pip install vllm"' >> /home/vllm/start.sh && \
    echo '    echo ""' >> /home/vllm/start.sh && \
    echo '    echo "For CPU:"' >> /home/vllm/start.sh && \
    echo '    echo "  pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu"' >> /home/vllm/start.sh && \
    echo '    echo "  pip install vllm-cpu-only"' >> /home/vllm/start.sh && \
    echo '    echo ""' >> /home/vllm/start.sh && \
    echo '    echo "After installation, restart the container or run: python3 run.py"' >> /home/vllm/start.sh && \
    echo '    echo "================================================"' >> /home/vllm/start.sh && \
    echo '    echo ""' >> /home/vllm/start.sh && \
    echo '    echo "Dropping into shell for manual installation..."' >> /home/vllm/start.sh && \
    echo '    exec /bin/bash' >> /home/vllm/start.sh && \
    echo 'fi' >> /home/vllm/start.sh && \
    echo '' >> /home/vllm/start.sh && \
    echo '# If vLLM is installed, start the application normally' >> /home/vllm/start.sh && \
    echo 'exec python3 run.py' >> /home/vllm/start.sh && \
    chmod +x /home/vllm/start.sh

# Switch to non-root user for runtime
USER 1001

# Set entrypoint
ENTRYPOINT ["/bin/bash", "-c", "/home/vllm/start.sh"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:7860/api/status || exit 1

