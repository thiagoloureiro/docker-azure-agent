FROM ubuntu:24.04
ENV TARGETARCH="linux-x64"
# Also can be "linux-arm", "linux-arm64".

RUN apt update && \
  apt upgrade -y && \
  apt install -y curl git jq libicu74

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Azure CLI vendors an older PyJWT (2.13.0 in CLI 2.90.0). Upgrade it in
# the private env at /opt/az. 2.15.1 has no known vulnerabilities.
# --no-deps keeps the rest of the CLI pin set, including cryptography.
RUN /opt/az/bin/python3 -m pip install --no-cache-dir --upgrade --no-deps --root-user-action=ignore 'PyJWT==2.15.1' \
 && /opt/az/bin/python3 -c 'import importlib.metadata as m; dists = [d for d in m.distributions() if (d.metadata["Name"] or "").lower() == "pyjwt"]; versions = [d.version for d in dists]; assert versions == ["2.15.1"], versions' \
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