FROM ubuntu:24.04
ENV TARGETARCH="linux-x64"
# Also can be "linux-arm", "linux-arm64".

RUN apt update && \
  apt upgrade -y && \
  apt install -y curl git jq libicu74

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Azure CLI vendors these in /opt/az (PyJWT 2.13.0/2.15.0, oauthlib 3.2.2).
# 2.15.1 and 4.0.1 clear the current advisories, including CVE-2026-118669
# and CVE-2026-49272. --no-deps keeps the rest of the CLI pin set.
RUN /opt/az/bin/python3 -m pip install --no-cache-dir --upgrade --no-deps --root-user-action=ignore \
      'PyJWT==2.15.1' \
      'oauthlib==4.0.1' \
 && /opt/az/bin/python3 -c 'import importlib.metadata as m; import oauthlib, requests_oauthlib; expected={"pyjwt":"2.15.1","oauthlib":"4.0.1"}; found={}; \
[found.setdefault((d.metadata["Name"] or "").lower(), []).append(d.version) for d in m.distributions() if (d.metadata["Name"] or "").lower() in expected]; \
assert found=={k:[v] for k,v in expected.items()}, found' \
 && az version

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