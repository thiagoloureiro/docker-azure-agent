# Use Alpine Linux as the base image
FROM alpine:latest

# Install dependencies and tools
RUN apk add --no-cache bash jq curl docker
RUN apk update && apk-upgrade -y

# Create a non-root user 'agent' and set as the user for running the agent
RUN adduser -D -u 1000 agent

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
