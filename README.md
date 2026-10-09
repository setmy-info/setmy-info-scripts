# Tools collection

## term

Development terminal preparations

## stealer

Stealing (actually borrowing) as a function. Collect code from different locations, apply changes, add your code and get
working solution - .stealer folder as an input and working solution as an output.
Decrease code repeating and increase development efficiency.

## Prepare

```sh
# TO build python
sudo dnf install -y openssl-devel sqlite sqlite-devel libffi-devel
```

## Build

```sh
SCRIPTS_VERSION=0.122.3
# Or
# SCRIPTS_VERSION=$(sed -n 's/^SCRIPTS_VERSION=\([0-9.]*\)$/\1/p' README.md)
./configure release
make clean
make all test package
sudo rpm -e setmy-info-scripts
# sudo rpm -e setmy-info-scripts 2>/dev/null || true
sudo rpm -i setmy-info-scripts-${SCRIPTS_VERSION}.noarch.rpm
```

All in a single line:

```sh
SCRIPTS_VERSION=0.122.3 && ./configure release && make clean && make all test package && sudo rpm -e setmy-info-scripts && sudo rpm -i setmy-info-scripts-${SCRIPTS_VERSION}.noarch.rpm

# Or
# SCRIPTS_VERSION=$(sed -n 's/^SCRIPTS_VERSION=\([0-9.]*\)$/\1/p' README.md) && ./configure release && make clean && make all test package && (sudo rpm -e setmy-info-scripts 2>/dev/null || true) && sudo rpm -i setmy-info-scripts-${SCRIPTS_VERSION}.noarch.rpm
```

and for SMI Rocky Linux Docker

### Build options

**./configure** options

**ci** - synonyme for release

**release** -
verification (unit tests, integration tests incl. valgrind tests), release (no debug info) binaries, stripped, without
-SNAPSHOT, real paths in side scripts.

**skipITs** - like maven skipITS, that skips integration tests incl. valgrind tests.

**noSnapshot** - without — SNAPSHOT

**realPaths** - inside scripts real path used

```sh
./configure [ci/release | release]
```

# Deploy to a server

The built RPM is uploaded with the `deploy` user, whose public key is installed on the server, so
no password is asked, and then handed to the deployment service of that machine, which installs
it. Nothing is installed over ssh.

No server is named in this repository. Every value comes from the environment, so a CI job
configuration or a command line decides which machine is deployed to:

```sh
./configure release && make clean && make all test package
SMI_DEPLOY_HOSTS="one.example.com two.example.com:2222" make deploy   # upload, then hand over
SMI_DEPLOY_HOSTS="one.example.com" make upload                        # upload only
make deploy-help                                                      # targets and variables
```

| variable                  | meaning                                                               | default                        |
|---------------------------|-----------------------------------------------------------------------|--------------------------------|
| `SMI_DEPLOY_HOSTS`        | the servers, `[user@]host[:port]` each, separated by spaces or commas | required                       |
| `SMI_DEPLOY_USER`         | user for an entry that does not name one                              | `deploy`                       |
| `SMI_DEPLOY_PORT`         | port for an entry that does not name one                              | `22`                           |
| `SMI_DEPLOY_REMOTE_DIR`   | where to upload                                                       | `/home/<user>/deploy`          |
| `SMI_DEPLOY_INCOMING_DIR` | what the deployment service watches                                   | `/var/opt/setmy.info/incoming` |

The same package belongs on every machine, whatever its role: this project is the helper script
collection every VM, container host and server needs, not a per environment configuration. One
call deploys to the whole list, so one more machine is one more word in the variable. A server
that fails does not stop the others, and the command ends with 1 when any of them failed. An IPv6
address goes in brackets, `[2001:db8::1]:2222`, as ssh and scp write it.

The hand over copies the package into the incoming directory under a `.part` name and renames it
there, so the watcher never starts on a half written file. This project is deployed published,
not as a draft: it is the toolset of the machine and there is nothing in it to approve.

What happened on the server:

```sh
journalctl -u setmy-info-deploy.service
```

An upload without the hand over is installed by hand there, as a user who may:

```sh
sudo dnf -y install /home/deploy/deploy/setmy-info-scripts-${SCRIPTS_VERSION}.noarch.rpm
```

Jenkins does the same, and its own job configuration holds the servers: the Deploy stage maps its
variables onto `SMI_DEPLOY_HOSTS` and runs `make deploy` on a `devel*`, `release*` or `hotfix*`
branch for the test environment and on `master` for the live one. There is
no DEV machine, the Jenkins node is the test machine itself, so the dev stage says so and the test
stage does the work. The installed version is deliberately not read back: the service installs in
parallel with the build and a query would race it.

# Verification

With Docker

```sh
docker build --no-cache --progress=plain -f Dockerfile .
```

# Version upgrade

Run from the project root:

```sh
./src/main/sh/build/update-versions.sh <new-version>
```

This updates all version references in:

* ./README.md
* ./Doxyfile
* ./Dockerfile
* ./CMakeLists.txt
* ./src/main/sh/build/packages-build.sh
* ./src/main/sh/build/check-files.sh (smi-version output test)
* ./setup.iss

After updating versions, rebuild and reinstall.

# TODO

## PCMake variables problem

Function usage is a problem. CMame doesn't have global variables. Only function or parent ... (directory, ... ?).

* sh separate into subdirectories (common/base, devel, server, software, desktop (devel. workstation), AWS, Google, K8S,
  git, ...):
    * common or **base**
        * time
        * string
        * CLI
    * **development** (devel. workstation)
        * python
        * groovy
        * C/C++
        * Java
        * JavaScript
        * AI, TensorFlow
    * **server**
        * ansible
    * desktop or **workstation**
    * ~~software~~
    * **vcs**, git, mercurial, subversion
    * ssl, **pki**
    * aws, google, **cloud**
    * k8s, **virtualization**, docker
    * **crm**
    * **tools**, helpers

# Windows

* [Inno Setup](https://jrsoftware.org/isinfo.php)
* [NSIS](https://sourceforge.net/projects/nsis/)

### Build with CMake and NSIS

To build the project and generate the NSIS installation executable (choose one generator):

```cmd
# Using Ninja (if installed)
call src\main\cmd\lib\profiles\ninja.cmd
cmake -B cmake-build-release -S . -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build cmake-build-release --target package
```

The resulting installer will be located in the `cmake-build-release` directory.

### Manual build

Alternatively, you can build the installers manually if the scripts are already prepared:

```cmd
makensis setup.nsi
ISCC.exe setup.iss
REM or
build.cmd
```
