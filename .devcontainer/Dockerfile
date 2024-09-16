# Use an official image that supports PowerShell
FROM mcr.microsoft.com/powershell:7.4-debian-12

# Add a label to name your image
LABEL name="dsccommunity/maintainanceautomation"

ENV DEBIAN_VERSION=12
ENV DOTNET_SDK_VERSION=8.0
ENV NODE_VERSION=20

# Install additional packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    wget \
    apt-transport-https \
    curl \
    git \
    unzip \
    npm \
    sudo \
    nano \
    locales \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN wget --progress=dot:giga https://packages.microsoft.com/config/debian/$DEBIAN_VERSION/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    dotnet-sdk-$DOTNET_SDK_VERSION \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Install Azurite
RUN npm install -g n@latest && n $NODE_VERSION \
    && npm install -g npm@latest \
    && npm install -g azure-functions-core-tools@4 --unsafe-perm true \
    && npm install -g azurite

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Set up a non-root user for the container
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Expose Azurite ports
EXPOSE 10000 10001 10002

RUN mkdir -p /workspaces/.azurite \
    && chmod -R 777 /workspaces/.azurite \
    && chown -R $USERNAME:$USERNAME /workspaces/.azurite

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog

# Set the default shell to bash
SHELL ["/bin/bash", "-c"]

# Start Azurite when the container starts
CMD ["azurite", "--blobHost", "0.0.0.0", "--queueHost", "0.0.0.0", "--location", "/workspaces/.azurite", "--silent"]

# Switch to non-root user
USER $USERNAME

# Install GitVersion as a dotnet tool for the node user
RUN dotnet tool install --global GitVersion.Tool

# Add alias for gitversion, ensuring a newline before the alias
RUN printf "\nalias gitversion=\"dotnet-gitversion\"\n" >> /home/$USERNAME/.bashrc

# Set the default shell to pwsh
SHELL ["/bin/pwsh", "-c"]
