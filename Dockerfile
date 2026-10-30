FROM ubuntu:24.04
ENV TARGETARCH="linux-x64"
# Also can be "linux-arm", "linux-arm64".

RUN apt update && \
  apt upgrade -y && \
  apt install -y curl git jq libicu74

# Helm 4.3.1. The published checksum is a bare sha256, verified before install.
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) helm_arch=amd64 ;; \
      arm64) helm_arch=arm64 ;; \
      armhf) helm_arch=arm ;; \
      *) echo "unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    version=4.3.1; \
    file="helm-v${version}-linux-${helm_arch}.tar.gz"; \
    curl -fsSL -o "/tmp/${file}" "https://get.helm.sh/${file}"; \
    curl -fsSL -o "/tmp/${file}.sha256" "https://get.helm.sh/${file}.sha256"; \
    printf '%s  %s\n' "$(tr -d '[:space:]' < "/tmp/${file}.sha256")" "/tmp/${file}" | sha256sum -c -; \
    tar -C /tmp -xzf "/tmp/${file}"; \
    mv "/tmp/linux-${helm_arch}/helm" /usr/local/bin/helm; \
    chmod 755 /usr/local/bin/helm; \
    rm -rf "/tmp/${file}" "/tmp/${file}.sha256" "/tmp/linux-${helm_arch}"; \
    helm version

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Azure CLI 2.91.0 vendors older copies of these libraries in /opt/az.
# Patched versions: PyJWT 2.15.1, cryptography 50.0.0, urllib3 2.8.0,
# oauthlib 4.0.0, setuptools 83.0.0, certifi 2026.10.19.
# pyOpenSSL 26.2.0 only allows cryptography<49, so it moves to 26.4.0,
# which supports cryptography 50.x.
# certifi 2026.10.19 drops the emSign roots whose intermediate keys were
# compromised (GHSA-6q48-6c7w-9gw2). CLI 2.91.0 ships 2024.7.4.
# --no-deps keeps the rest of the CLI pin set.
RUN /opt/az/bin/python3 -m pip install --no-cache-dir --upgrade --no-deps --root-user-action=ignore \
      'PyJWT==2.15.1' \
      'cryptography==50.0.0' \
      'pyOpenSSL==26.4.0' \
      'urllib3==2.8.0' \
      'oauthlib==4.0.0' \
      'setuptools==83.0.0' \
      'certifi==2026.10.19' \
 && /opt/az/bin/python3 -c 'import importlib.metadata as m; expected={"pyjwt":"2.15.1","cryptography":"50.0.0","pyopenssl":"26.4.0","urllib3":"2.8.0","oauthlib":"4.0.0","setuptools":"83.0.0","certifi":"2026.10.19"}; found={}; \
[found.setdefault((d.metadata["Name"] or "").lower(), []).append(d.version) for d in m.distributions() if (d.metadata["Name"] or "").lower() in expected]; \
bad={n: found.get(n) for n,v in expected.items() if found.get(n)!=[v]}; assert not bad, bad; \
import OpenSSL, cryptography, urllib3, oauthlib, jwt, setuptools, certifi' \
 && az version

RUN /opt/az/bin/python3  -m pip uninstall --yes pip && rm -rf /root/.cache/pip

WORKDIR /azp/

COPY ./start.sh ./
RUN chmod +x ./start.sh

# Create agent user and set up home directory
RUN useradd -m -d /home/agent agent
RUN chown -R agent:agent /azp /home/agent

USER agent
# Another option is to run the agent as root.
# ENV AGENT_ALLOW_RUNASROOT="true"

ENTRYPOINT [ "./start.sh" ]
