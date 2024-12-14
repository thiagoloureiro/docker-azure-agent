# Use Ubuntu as the base image
FROM ubuntu:latest

# Install dependencies and tools
RUN apt-get update && apt-get install -y \
    bash \
    jq \
    curl \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# Upgrade all installed packages
RUN apt-get update && apt-get upgrade -y

# Create a non-root user 'agent' with a home directory and set the UID to 1000
RUN useradd -m -u 1000 -s /bin/bash agent

# Install Docker group and add the agent user to the docker group to allow Docker access
RUN groupadd docker && usermod -aG docker agent

# Download and install the Azure DevOps agent
RUN mkdir /azp \
    && curl -Ls https://vstsagentpackage.azureedge.net/agent/3.248.0/vsts-agent-linux-x64-3.248.0.tar.gz | tar -xz -C /azp

# Change ownership of the agent directory to the 'agent' user
RUN chown -R agent:agent /azp

# Set the working directory to the agent installation directory
WORKDIR /azp

# Switch to the 'agent' user for the rest of the operations
USER agent

# Run the configuration script when the container starts
ENTRYPOINT ["./config.sh"]

# Command to run the Azure DevOps agent after configuring it
CMD ["./run.sh"]
