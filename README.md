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
SCRIPTS_VERSION=0.102.0
./configure release
make clean
make all test package
sudo rpm -e setmy-info-scripts
sudo rpm -i setmy-info-scripts-${SCRIPTS_VERSION}.noarch.rpm
```

All in single line:

```sh
SCRIPTS_VERSION=0.102.0 && ./configure release && make clean && make all test package && sudo rpm -e setmy-info-scripts && sudo rpm -i setmy-info-scripts-${SCRIPTS_VERSION}.noarch.rpm
```

and for SMI Rocky Linux Docker

### Build options

**./configure** options

**ci** - synonyme for release

**release** -
verification (unit tests, integration tests incl. valgrind tests), release (no debug info) binaries, stripped, without
-SNAPSHOT, real paths in side scripts.

**skipITs** - like maven skipITS, that skips integration tests incl. valgrind tests.

**noSnapshot** - without -SNAPSHOT

**realPaths** - inside scripts real path used

```sh
./configure [ci/release | release]
```

# Version upgrade

* ./README.md
* ./Doxyfile
* ./Dockerfile
* ./CMakeLists.txt
* ./src/main/sh/build/packages-build.sh

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
