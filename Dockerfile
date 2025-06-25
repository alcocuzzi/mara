#checkov:skip=CKV_DOCKER_2 Healthcheck instructions have not been added to container images
# aarch64 x86_64
FROM ubuntu:noble AS base
ENV UID="999"
ENV GID="999"
ENV USER="mara"
ENV GROUP="mara"
ENV OS_TOOLS="wget curl git python3 python3-pip sudo tar unzip less jq vim fish gpg netcat-traditional cookiecutter"
ENV PY_TOOLS="configparser==7.2.0 docopt==0.6.2 pre-commit==4.2.0 rich==13.7.1 boto3==1.38.36 botocore==1.38.36 PyGithub==2.6.1 pygit2==1.18.0"
RUN ARCH=$(uname -m) && \
    case "$ARCH" in x86_64) ARCH_SHORT=amd64; ARCH_SSM=64bit ;; aarch64) ARCH_SHORT=arm64; ARCH_SSM=arm64 ;; esac && \
    apt-get update -y && \
    apt-get install ${OS_TOOLS} --no-install-recommends -y && \
    pip3 install --no-cache-dir ${PY_TOOLS} --break-system-packages && \
    cd /tmp && \
    curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" -o "awscliv2.zip" && \
    unzip ./awscliv2.zip -d /tmp && \
    /tmp/aws/install && \
    curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash && \
    curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash && \
    curl -sSL -o k9s_linux_${ARCH_SHORT}.deb https://github.com/derailed/k9s/releases/latest/download/k9s_linux_${ARCH_SHORT}.deb && \
    dpkg -i k9s_linux_${ARCH_SHORT}.deb && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH_SHORT}/kubectl" && \
    sudo install -m 0755 kubectl /usr/local/bin/kubectl && \
    curl -sSL -o argocd-linux-${ARCH_SHORT} https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${ARCH_SHORT} && \
    sudo install -m 555 argocd-linux-${ARCH_SHORT} /usr/local/bin/argocd && \
    curl -Lo ./velero-v1.15.0-linux-${ARCH_SHORT}.tar.gz https://github.com/vmware-tanzu/velero/releases/download/v1.15.0/velero-v1.15.0-linux-${ARCH_SHORT}.tar.gz && \
    tar -xzf velero-v1.15.0-linux-${ARCH_SHORT}.tar.gz && \
    mv velero-v1.15.0-linux-${ARCH_SHORT}/velero /usr/local/bin/velero && \
    curl -Lo ./terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.18.0/terraform-docs-v0.18.0-$(uname)-${ARCH_SHORT}.tar.gz && \
    tar -xzf terraform-docs.tar.gz && \
    mv terraform-docs /usr/local/bin/terraform-docs && \
    curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep DISTRIB_CODENAME /etc/lsb-release | cut -d'=' -f2) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && sudo apt-get install terraform -y && \
    curl -sSL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_${ARCH_SSM}/session-manager-plugin.deb" -o session-manager-plugin.deb && \
    dpkg -i session-manager-plugin.deb && \
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh && \
    curl -o /tmp/starship_install.sh -sS https://starship.rs/install.sh && \
    chmod +x /tmp/starship_install.sh /usr/local/bin/kubectl /usr/local/bin/terraform-docs && \
    /tmp/starship_install.sh -y && \
    apt clean && rm -rf /var/lib/apt/lists/* /tmp/*

FROM base AS mara

COPY config /tmp/

RUN ARCH=$(uname -m) && \
    case "$ARCH" in x86_64) ARCH_SHORT=amd64 ;; aarch64) ARCH_SHORT=arm64 ;; esac && \
    useradd -m -s /usr/bin/fish $USER && \
    usermod -u $UID $USER && groupmod -g $GID $GROUP && \
    echo "mara ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /app/scripts /home/mara/.aws /etc/fixuid /home/mara/.config /home/mara/.config/fish/functions && \
    cp -R /tmp/bin/mara /usr/local/bin/mara && \
    mv /tmp/etc/fixuid/config.yml /etc/fixuid/config.yml && \
    mv /tmp/etc/starship/starship.toml /home/mara/.config/starship.toml && \
    mv /tmp/etc/fish/mara.fish /usr/share/fish/completions/mara.fish && \
    mv /tmp/etc/fish/fish_greeting.fish /home/mara/.config/fish/functions/fish_greeting.fish && \
    cp -R /tmp/bin/scripts/* /app/scripts/ && \
    chown -R $UID:$GID /home/mara/ /home/mara/.* /app/scripts/* /usr/local/bin/ && \
    chmod +x /usr/local/bin/mara && \
    echo "alias tf=terraform"  >> /home/mara/.config/fish/config.fish && \
    echo "alias k=kubectl"  >> /home/mara/.config/fish/config.fish && \
    curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.6.0/fixuid-0.6.0-linux-${ARCH_SHORT}.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    echo "starship init fish | source" >> /home/mara/.config/fish/config.fish && \
    rm -rf /tmp/*

USER mara

WORKDIR /home/mara

ENTRYPOINT [ "fixuid", "-q", "/usr/bin/fish" ]
