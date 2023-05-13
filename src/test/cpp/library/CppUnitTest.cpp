#define BOOST_TEST_MODULE library
#include <boost/test/included/unit_test.hpp>
#include <iostream>

using boost::unit_test::label;

BOOST_AUTO_TEST_CASE(ut, *label("L1")) {
std::cout << "Using Boost "
<< BOOST_VERSION / 100000     << "."  // major version
<< BOOST_VERSION / 100 % 1000 << "."  // minor version
<< BOOST_VERSION % 100                // patch level
<< std::endl;
std::cout << "1" <<  std::endl;
}
BOOST_AUTO_TEST_CASE(it, *label("L1")) {std::cout << "2" << std::endl;}

BOOST_AUTO_TEST_SUITE(library)

BOOST_AUTO_TEST_SUITE(ut)
BOOST_AUTO_TEST_CASE(ut_1) {std::cout << "3" << std::endl;/*int* ptr = new int;*/}
BOOST_AUTO_TEST_CASE(ut_2) {std::cout << "4" << std::endl;}
BOOST_AUTO_TEST_SUITE_END()

BOOST_AUTO_TEST_SUITE(it)
BOOST_AUTO_TEST_CASE(it_1, *label("L2")) {std::cout << "5" << std::endl;}
BOOST_AUTO_TEST_CASE(it_2, *label("L2")) {std::cout << "6" << std::endl;/*int* ptr = new int;*/}
BOOST_AUTO_TEST_SUITE_END()

BOOST_AUTO_TEST_CASE(test_1, *label("L1")) {std::cout << "7" << std::endl;}
BOOST_AUTO_TEST_CASE(test_2) {std::cout << "8" << std::endl;}
BOOST_AUTO_TEST_CASE(test_2A) {std::cout << "9" << std::endl;}

BOOST_AUTO_TEST_SUITE_END()
