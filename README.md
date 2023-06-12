
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


### Donate

* [Set your favorite donation](https://www.paypal.me/imretabur "Donate any amount")
* [1 EUR](https://www.paypal.me/imretabur/1 "Donate 1 EUR")
* [5 EUR](https://www.paypal.me/imretabur/5 "Donate 5 EUR")
* [10 EUR](https://www.paypal.me/imretabur/10 "Donate 10 EUR")
* [15 EUR](https://www.paypal.me/imretabur/15 "Donate 15 EUR")
* [20 EUR](https://www.paypal.me/imretabur/20 "Donate 20 EUR")
* [30 EUR](https://www.paypal.me/imretabur/30 "Donate 30 EUR")
* [50 EUR](https://www.paypal.me/imretabur/50 "Donate 50 EUR")
* [75 EUR](https://www.paypal.me/imretabur/75 "Donate 75 EUR")
* [100 EUR](https://www.paypal.me/imretabur/100 "Donate 100 EUR")
* [200 EUR](https://www.paypal.me/imretabur/200 "Donate 200 EUR")
