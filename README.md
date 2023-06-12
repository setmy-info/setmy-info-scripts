
# Tools collection

## term

Development terminal preparations

## stealer

Stealing (actually borrowing) as a function. Collect code from different locations, apply changes, add your code and get
working solution - .stealer folder as an input and working solution as an output.
Decrease code repeating and increase development efficiency.

## Build

```sh
./configure
make
make package
sudo rpm -e setmy-info-scripts
sudo rpm -i setmy-info-scripts-0.54.0-SNAPSHOT.noarch.rpm
```

All in single line:

```sh
./configure release && make clear clean && make all test package && sudo rpm -e setmy-info-scripts && sudo rpm -i setmy-info-scripts-0.54.0.noarch.rpm
```

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

# TODO

* sh separate into subdirectories (common/base, devel, server, software, desktop (devel. workstation), ...)

### Donate

* [Set your favorite donation](https://www.paypal.me/imretabur "Donate any amount")
