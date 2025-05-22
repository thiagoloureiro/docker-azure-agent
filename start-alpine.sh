FROM alpine:3.19

# Install required packages
RUN apk add --no-cache \
  bash \
  curl \
  jq \
  tar \
  coreutils \
  icu-libs \
  ca-certificates \
  su-exec \
  shadow

# Create agent user
RUN adduser -D -h /home/agent agent

# Set working dir
WORKDIR /azp

# Copy your entrypoint script
COPY start.sh .

# Make it executable
RUN chmod +x ./start.sh

# Run as non-root user
USER agent

# Entry point
ENTRYPOINT ["./start.sh"]
