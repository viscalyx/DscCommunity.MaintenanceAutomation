# ---
# TODO: It seems the VS Code extension Azure Functions does not support running in a container since I think it is suppose to provide the task provider "func:", but that fails. It is possible to start it using `func start` from the terminal, but it is not possible to debug the functions using F5.
#       Error: there is no registered task type 'func'. Did you miss installing an extension that provides a corresponding task provider?
#
# TODO: The command azurite does not automatically start as a background process or maybe it does, either way it is not recognized by VS Code as the ports are not forwarded and it is not possible to start the debugger with F5.
#       Workaround is to start azurite manually from the command line once the container is running.
# ---
# Use an official image that supports PowerShell
FROM mcr.microsoft.com/powershell:7.4-debian-12

# Add a label to name your image
LABEL name="dsccommunity/maintainanceautomation"

ENV DEBIAN_VERSION=12
#ENV NODE_VERSION=20
ENV POWERSHELL_VERSION=7.4.5
ENV POWERSHELL_PACKAGE_REVISION=1

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
    gpg \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Install .NET SDKs. v6.* is required for debugging Azure Functions in VS Code at the time of writing this Dockerfile
RUN wget --progress=dot:giga https://packages.microsoft.com/config/debian/$DEBIAN_VERSION/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    dotnet-sdk-8.0 \
    dotnet-sdk-7.0 \
    dotnet-sdk-6.0 \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Update PowerShell to the specified version
RUN wget https://github.com/PowerShell/PowerShell/releases/download/v$POWERSHELL_VERSION/powershell_${POWERSHELL_VERSION}-${POWERSHELL_PACKAGE_REVISION}.deb_amd64.deb -O powershell.deb \
    && dpkg -i powershell.deb \
    && apt-get update \
    && apt-get install -f \
    && rm powershell.deb \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# RUN npm install -g n@latest && n $NODE_VERSION \
#     && npm install -g npm@latest \
#     && npm install -g azure-functions-core-tools@4 --unsafe-perm true
#&& npm install -g azurite

# Install Azure Functions Core Tools
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /usr/share/keyrings/microsoft-prod.gpg \
    && wget -q https://packages.microsoft.com/config/debian/$DEBIAN_VERSION/prod.list \
    && mv prod.list /etc/apt/sources.list.d/microsoft-prod.list \
    && chown root:root /usr/share/keyrings/microsoft-prod.gpg \
    && chown root:root /etc/apt/sources.list.d/microsoft-prod.list \
    && apt-get update \
    && apt-get install -y azure-functions-core-tools-4 libicu-dev -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# # Install Visual Studio Code extensions (including Azure Functions)
# RUN curl -sSL https://aka.ms/install-vscode-server/setup.sh | sh
# #RUN /usr/local/bin/code-server --install-extension ms-azuretools.vscode-azurefunctions

# # Ensure the extension is activated in the container
# RUN mkdir -p /root/.vscode-server/extensions \
#     && cd /root/.vscode-server/extensions \
#     && curl -JL https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-azuretools/vsextensions/vscode-azurefunctions/latest/vspackage -o vscode-azurefunctions.zip \
#     && unzip vscode-azurefunctions.zip -d ms-azuretools.vscode-azurefunctions \
#     && rm vscode-azurefunctions.zip

# RUN mkdir -p /root/.vscode-server/data/Machine \
#     && echo '{ "extensions.autoUpdate": false }' > /root/.vscode-server/data/Machine/settings.json

# # Add this to ensure VS Code can find the extensions
# ENV VSCODE_EXTENSIONS="/root/.vscode-server/extensions"

# RUN mkdir -p /root/.local/share/code-server/User \
#     && echo '{ "extensions.autoUpdate": false }' > /root/.local/share/code-server/User/settings.json

# # Add this to ensure VS Code can find the extensions
# ENV CODE_SERVER_USER_DATA_DIR=/root/.local/share/code-server

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# # Set up a non-root user for the container
# ARG USERNAME=vscode
# ARG USER_UID=1000
# ARG USER_GID=$USER_UID

# RUN groupadd --gid $USER_GID $USERNAME \
#     && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
#     && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME \
#     && chmod 0440 /etc/sudoers.d/$USERNAME

# Expose Azurite ports
EXPOSE 10000 10001 10002

RUN mkdir -p /workspaces/.azurite \
    && chmod -R 777 /workspaces/.azurite
#   && chown -R $USERNAME:$USERNAME /workspaces/.azurite

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog

# Set the default shell to bash
SHELL ["/bin/bash", "-c"]

# Start Azurite when the container starts
#CMD ["azurite", "--blobHost", "0.0.0.0", "--queueHost", "0.0.0.0", "--location", "/workspaces/.azurite", "--silent"]

# # Switch to non-root user
# USER $USERNAME

# Install GitVersion as a dotnet tool for the node user
RUN dotnet tool install --global GitVersion.Tool

# # Add alias for gitversion, ensuring a newline before the alias
# RUN printf "\nalias gitversion=\"dotnet-gitversion\"\n" >> /home/$USERNAME/.bashrc

# Add alias to bash profile, and create PowerShell profile directory and add alias
RUN printf "\nalias gitversion=\"dotnet-gitversion\"\n" >> /root/.bashrc \
    && mkdir -p /root/.config/powershell \
    && echo 'New-Alias -Name gitversion -Value dotnet-gitversion' >> /root/.config/powershell/Microsoft.PowerShell_profile.ps1

# Set the default shell to PowerShell (/usr/bin/pwsh)
SHELL ["pwsh", "-Command"]

RUN git config --global --add safe.directory /workspaces/DscCommunity.MaintenanceAutomation
