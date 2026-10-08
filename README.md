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
SCRIPTS_VERSION=0.121.0
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
SCRIPTS_VERSION=0.121.0 && ./configure release && make clean && make all test package && sudo rpm -e setmy-info-scripts && sudo rpm -i setmy-info-scripts-${SCRIPTS_VERSION}.noarch.rpm

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

# Deploy to the servers

The built RPM is uploaded to the servers with the `deploy` user, whose public key is already
installed there, so no password is asked. Installation is manual, on purpose: the upload only
puts the package into `/home/deploy/deploy`.

```sh
./configure release && make clean && make all test package
make upload-test            # TEST
make upload-live            # LIVE front end, SSH port 27443
make upload-all             # every configured environment
make upload-help            # what the targets do, with the hosts and ports
```

The same package goes to every machine, TEST and LIVE alike: this project is the helper script
collection every VM, container host and server needs, so there is nothing to filter per
environment.

On the server, as a user who may:

```sh
sudo dnf -y install /home/deploy/deploy/setmy-info-scripts-${SCRIPTS_VERSION}.noarch.rpm
```

The LIVE back end server does not exist yet. `make upload-be` is ready for it and says what is
missing until `DEPLOY_BE_HOST` is filled in, in `src/main/resources/cmake/deploy.cmake` or on the
command line. Every value can be overridden the same way:

```sh
make upload-live DEPLOY_LIVE_HOST=host DEPLOY_LIVE_PORT=port DEPLOY_USER=user DEPLOY_REMOTE_DIR=dir
```

Jenkins does the same: the Deploy stage of the Jenkinsfile runs `make upload-test` on a `devel*`
branch and `make upload-live` on `master`.

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
