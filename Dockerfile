FROM ubuntu:noble AS base
ENV UID="999"
ENV GID="999"
ENV USER="mara"
ENV GROUP="mara"
ENV OS_TOOLS="wget curl git python3 python3-pip sudo tar unzip less jq vim fish gpg netcat-traditional nano cookiecutter unzip"
ENV PY_TOOLS="configparser==7.2.0 docopt==0.6.2 pre-commit==4.2.0 rich==13.7.1 boto3==1.38.36 botocore==1.38.36 PyGithub==2.6.1 pygit2==1.18.0 tabulate==0.9.0"
ENV CLI_TOOLS="awscli, helm, tfsec, tflint, kubectl, argocd, terraform, k9s, ssm-session-manager github-cli supabase-cli"
RUN apt-get update -y && \
    apt-get install ${OS_TOOLS} --no-install-recommends -y && \
    pip3 install --no-cache-dir ${PY_TOOLS} --break-system-packages && \
    apt clean && rm -rf /var/lib/apt/lists/*

FROM base AS install
ENV TF_VERSION="1.12.2"
ENV GIT_CLI_VERSION="2.74.2"
ENV SUPABASE_VERSION="2.33.6"
WORKDIR /tmp
RUN ARCH=$(uname -m) && \
    case "$ARCH" in x86_64) ARCH_SHORT=amd64; ARCH_SSM=64bit ;; aarch64) ARCH_SHORT=arm64; ARCH_SSM=arm64 ;; esac && \
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" -o "awscliv2.zip" && \
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y && \
    curl -fsSL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash && \
    curl -fsSL https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash && \
    curl -fsSL -o kubectl "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH_SHORT}/kubectl" && \
    curl -fsSL -o argocd-linux-${ARCH_SHORT} https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${ARCH_SHORT} && \
    curl -fsSL "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_${ARCH_SHORT}.zip" -o terraform.zip && unzip -q terraform.zip && \
    curl -sSL -o k9s_linux_${ARCH_SHORT}.deb https://github.com/derailed/k9s/releases/latest/download/k9s_linux_${ARCH_SHORT}.deb && \
    curl -fsSL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_${ARCH_SSM}/session-manager-plugin.deb" -o session-manager-plugin.deb && \
    curl -fSSL "https://github.com/cli/cli/releases/download/v${GIT_CLI_VERSION}/gh_${GIT_CLI_VERSION}_linux_${ARCH_SHORT}.deb" -o gh_linux.deb && \
    curl -fSSL "https://github.com/terraform-docs/terraform-docs/releases/download/v0.18.0/terraform-docs-v0.18.0-$(uname)-${ARCH_SHORT}.tar.gz" -o terraform-docs.tar.gz && \
    curl -fSSL "https://github.com/supabase/cli/releases/download/v${SUPABASE_VERSION}/supabase_${SUPABASE_VERSION}_linux_${ARCH_SHORT}.deb" -o supabase_linux.deb && \
    tar -xzf terraform-docs.tar.gz && mv terraform-docs /usr/local/bin/terraform-docs && \
    unzip ./awscliv2.zip -d /tmp && \
    /tmp/aws/install && \
    for deb in *.deb; do \
        dpkg -i $deb; \
    done && \
    install -m 0755 kubectl /usr/local/bin/kubectl && \
    install -m 0755 argocd-linux-${ARCH_SHORT} /usr/local/bin/argocd && \
    install -m 0755 terraform /usr/local/bin/terraform && \
    apt clean && rm -rf /var/lib/apt/lists/* /tmp/*

FROM install AS mara
COPY config /tmp/
RUN ARCH=$(uname -m) && \
    case "$ARCH" in x86_64) ARCH_SHORT=amd64; ARCH_SSM=64bit ;; aarch64) ARCH_SHORT=arm64; ARCH_SSM=arm64 ;; esac && \
    useradd -m -s /usr/bin/fish $USER && \
    usermod -u $UID $USER && groupmod -g $GID $GROUP && \
    echo "mara ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.6.0/fixuid-0.6.0-linux-${ARCH_SHORT}.tar.gz | tar -C /usr/local/bin -xzf - && \
    mkdir -p /app/scripts /home/mara/.aws /etc/fixuid /home/mara/.config /home/mara/.config/fish/functions && \
    cp -R /tmp/bin/mara /usr/local/bin/mara && \
    cp -R /tmp/bin/scripts/* /app/scripts/ && \
    mv /tmp/etc/fixuid/config.yml /etc/fixuid/config.yml && \
    mv /tmp/etc/starship/starship.toml /home/mara/.config/starship.toml && \
    mv /tmp/etc/fish/mara.fish /usr/share/fish/completions/mara.fish && \
    mv /tmp/etc/fish/fish_greeting.fish /home/mara/.config/fish/functions/fish_greeting.fish && \
    chown -R $UID:$GID /home/mara/ /home/mara/.* /app/scripts/* /usr/local/bin/ && \
    chmod +x /usr/local/bin/mara && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    echo "alias tf=terraform"  >> /home/mara/.config/fish/config.fish && \
    echo "alias k=kubectl"  >> /home/mara/.config/fish/config.fish && \
    echo "starship init fish | source" >> /home/mara/.config/fish/config.fish && \
    rm -rf /tmp/*
USER mara
WORKDIR /home/mara
ENTRYPOINT [ "fixuid", "-q", "/usr/bin/fish" ]