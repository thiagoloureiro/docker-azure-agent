FROM ubuntu:24.04
ENV TARGETARCH="linux-x64"
# Also can be "linux-arm", "linux-arm64".

RUN apt update && \
  apt upgrade -y && \
  apt install -y curl git jq libicu74

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Azure CLI vendors pinned copies of these in /opt/az. pyOpenSSL 26.2.0
# rejects cryptography newer than 48, so 26.4.0 has to move with it.
# cryptography 50.0.2, urllib3 2.8.0, and setuptools 84.2.1 clear the
# current advisories (CVE-2026-69247, GHSA-8988-9cw3-xx77, CVE-2026-59890).
RUN /opt/az/bin/python3 -m pip install --no-cache-dir --upgrade --root-user-action=ignore \
      'PyJWT==2.15.1' \
      'oauthlib==4.0.1' \
      'cryptography==50.0.2' \
      'pyOpenSSL==26.4.0' \
      'urllib3==2.8.0' \
      'setuptools==84.2.1' \
 && az version \
 && /opt/az/bin/python3 - <<'PY'
import importlib.metadata as m
import oauthlib
import requests_oauthlib
import setuptools
import urllib3
from OpenSSL import SSL

expected = {
    "pyjwt": "2.15.1",
    "oauthlib": "4.0.1",
    "cryptography": "50.0.2",
    "pyopenssl": "26.4.0",
    "urllib3": "2.8.0",
    "setuptools": "84.2.1",
}
found = {}
for dist in m.distributions():
    name = (dist.metadata["Name"] or "").lower()
    if name in expected:
        found.setdefault(name, []).append(dist.version)
assert found == {name: [version] for name, version in expected.items()}, found
PY

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