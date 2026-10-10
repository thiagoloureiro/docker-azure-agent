FROM ubuntu:24.04
ENV TARGETARCH="linux-x64"
# Also can be "linux-arm", "linux-arm64".

RUN apt update && \
  apt upgrade -y && \
  apt install -y curl git jq libicu74

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Azure CLI 2.91.0 vendors older copies of these libraries in /opt/az.
# Patched versions: PyJWT 2.15.1, cryptography 50.0.0, urllib3 2.8.0,
# oauthlib 4.0.0, setuptools 83.0.0.
# pyOpenSSL 26.2.0 only allows cryptography<49, so it moves to 26.4.0,
# which supports cryptography 50.x.
# --no-deps keeps the rest of the CLI pin set.
RUN /opt/az/bin/python3 -m pip install --no-cache-dir --upgrade --no-deps --root-user-action=ignore \
      'PyJWT==2.15.1' \
      'cryptography==50.0.0' \
      'pyOpenSSL==26.4.0' \
      'urllib3==2.8.0' \
      'oauthlib==4.0.0' \
      'setuptools==83.0.0' \
 && /opt/az/bin/python3 -c 'import importlib.metadata as m; expected={"pyjwt":"2.15.1","cryptography":"50.0.0","pyopenssl":"26.4.0","urllib3":"2.8.0","oauthlib":"4.0.0","setuptools":"83.0.0"}; found={}; \
[found.setdefault((d.metadata["Name"] or "").lower(), []).append(d.version) for d in m.distributions() if (d.metadata["Name"] or "").lower() in expected]; \
bad={n: found.get(n) for n,v in expected.items() if found.get(n)!=[v]}; assert not bad, bad; \
import OpenSSL, cryptography, urllib3, oauthlib, jwt, setuptools' \
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
