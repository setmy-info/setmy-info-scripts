#ifndef SET_MY_INFO_TESTS_1_H_
#define	SET_MY_INFO_TESTS_1_H_

#include "CppUnitTest.h"

BOOST_AUTO_TEST_CASE(ut, *boost::unit_test::label("L1")) {
    /*
    BOOST_CHECK(actual_sum == expected_sum);  // Kasutades BOOST_CHECK
    BOOST_REQUIRE(actual_sum == expected_sum);  // Kasutades BOOST_REQUIRE
    BOOST_CHECK_CLOSE(actual_sum, expected_sum, 0.01);  // Kasutades BOOST_CHECK_CLOSE
    */
    std::cout << "Using Boost "
              << BOOST_VERSION / 100000     << "."  // major version
              << BOOST_VERSION / 100 % 1000 << "."  // minor version
              << BOOST_VERSION % 100                // patch level
              << std::endl;
    std::cout << "1" <<  std::endl;
}
BOOST_AUTO_TEST_CASE(it, *boost::unit_test::label("L1")) {std::cout << "2" << std::endl;}

BOOST_AUTO_TEST_SUITE(library)

    BOOST_AUTO_TEST_SUITE(ut)
        BOOST_AUTO_TEST_CASE(ut_1) {std::cout << "3" << std::endl;/*int* ptr = new int;*/}
        BOOST_AUTO_TEST_CASE(ut_2) {std::cout << "4" << std::endl;}
    BOOST_AUTO_TEST_SUITE_END()

    BOOST_AUTO_TEST_SUITE(it)
        BOOST_AUTO_TEST_CASE(it_1, *boost::unit_test::label("L2")) {std::cout << "5" << std::endl;}
        BOOST_AUTO_TEST_CASE(it_2, *boost::unit_test::label("L2")) {std::cout << "6" << std::endl;/*int* ptr = new int;*/}
    BOOST_AUTO_TEST_SUITE_END()

    BOOST_AUTO_TEST_CASE(test_1, *boost::unit_test::label("L1")) {std::cout << "7" << std::endl;}
    BOOST_AUTO_TEST_CASE(test_2) {std::cout << "8" << std::endl;}
    BOOST_AUTO_TEST_CASE(test_2A) {std::cout << "9" << std::endl;}

BOOST_AUTO_TEST_SUITE_END()

#endif // SET_MY_INFO_TESTS_1_H_
