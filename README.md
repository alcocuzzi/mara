# Mara
Introducing a powerful Docker container tailored for efficient development of Terraform and Python code on AWS. With pre-installed tools, it simplifies the development process by providing a convenient ready to develop environment.

Seamlessly integrated with many open source tools and with a built-in Python script utility tool, it enables effortless login to the AWS through AWS SSO credentials, ensuring smooth workflows and enhanced productivity.

## Get started with Mara

### Step 1: Have a container orchestrator installed
Either Docker, Podman or Apple Container installed is required to run the container.

### Step 2: Pull Mara image

**Docker:**
```console
docker pull thecoderepublic/mara:latest
```

**Podman:**
```console
podman pull thecoderepublic/mara:latest
```

**Apple Container:**
```console
container image pull --arch arm64 thecoderepublic/mara:latest
```

### Step 3: Run Mara

**Docker:**
```console
docker run --rm -it thecoderepublic/mara:latest
```

**Podman:**
```console
podman run --rm -it thecoderepublic/mara:latest
```

**Apple Container:**
```console
container run --rm -it thecoderepublic/mara:latest
```

**Optional: Create a wrapper script**
By creating a wrapper script it makes easier to run the `Mara` container and access computer folders with your preferable code editor.

In order to create the wrapper script, please follow the below steps:

- Create a file called `mara` in /usr/local/bin/

- Paste the following content in the file using your preferable text editor (choose one based on your container orchestrator):

**Docker:**
```console
#!/bin/bash

UID=$(id -u)
GID=$(id -g)

image=thecoderepublic/mara:latest
docker pull ${image}

docker run \
   -it \
   --name=mara \
   --rm \
   -u $UID:$GID \
   -v ${HOME}:/home/mara/devbox \
   ${image}
```

**Podman:**
```console
#!/bin/bash

UID=$(id -u)
GID=$(id -g)

image=thecoderepublic/mara:latest
podman pull ${image}

podman run \
   -it \
   --name=mara \
   --rm \
   -u $UID:$GID \
   -v ${HOME}:/home/mara/devbox \
   ${image}
```

**Apple Container:**
```console
#!/bin/zsh

UID=$(id -u)
GID=$(id -g)

mkdir -p ${HOME}/Documents/devbox
image=thecoderepublic/mara:latest
container image pull --arch arm64 ${image}

container run \
   -it \
   --rm \
   -u $UID:$GID \
   -w /home/mara/devbox \
   -v ${HOME}/Documents/devbox:/home/mara/devbox \
   ${image}
```

- Make the mara file executable:
```console
chmod +x /usr/local/bin/mara
```

- Every time you would like to use the tool, just type it:
```console
mara
```

From now on, use any code editor to open the folder mounted within mara container and store code there, and enjoy `Mara` facilities.

To find the mara utilities and starting using them, type the `mara` command and check out its functionalities:

```console
mara help
mara tools
```

Please note that the credentials are exposed to the container only during the usage time and they will be gone after exiting the container.