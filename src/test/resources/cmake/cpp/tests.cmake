# PLACEHOLDER-BEGIN #
MESSAGE("-- test cpp tests.cmake")

#ADD_TEST(NAME data_types_test_ut COMMAND test.bin --run_test=data_types_test/ut)

IF(VERIFY_USED)
#ADD_TEST(NAME valgrind_data_types_test_ut COMMAND ${MEM_LEAK_TEST_COMMAND} ${BINARY_OUTPUT_PATH}/test.bin --run_test=data_types_test/ut)
ENDIF()

INCLUDE(${TEST_CPP_CMAKE_PATH}/library/tests.cmake)

# PLACEHOLDER-END #
