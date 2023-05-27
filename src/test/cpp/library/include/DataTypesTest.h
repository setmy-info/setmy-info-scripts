#ifndef SET_MY_INFO_DATA_TYPES_TEST_H_
#define	SET_MY_INFO_DATA_TYPES_TEST_H_

#include "CppUnitTest.h"
#include "DataTypes.h"

BOOST_AUTO_TEST_SUITE(data_types_test)

    BOOST_AUTO_TEST_SUITE(ut)

        BOOST_AUTO_TEST_CASE(char_lengths) {
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::Char), 1);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::UChar), 1);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::SChar), 1);

            BOOST_CHECK(std::numeric_limits<SetMyInfo::Char>::is_signed);
            BOOST_CHECK(!std::numeric_limits<SetMyInfo::UChar>::is_signed);
            BOOST_CHECK(std::numeric_limits<SetMyInfo::SChar>::is_signed);
        }

        BOOST_AUTO_TEST_CASE(int8_lengths) {
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::Int8), 1);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::UInt8), 1);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::SInt8), 1);

            BOOST_CHECK(std::numeric_limits<SetMyInfo::Int8>::is_signed);
            BOOST_CHECK(!std::numeric_limits<SetMyInfo::UInt8>::is_signed);
            BOOST_CHECK(std::numeric_limits<SetMyInfo::SInt8>::is_signed);
        }

        BOOST_AUTO_TEST_CASE(int16_lengths) {
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::Int16), 2);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::UInt16), 2);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::SInt16), 2);

            BOOST_CHECK(std::numeric_limits<SetMyInfo::Int16>::is_signed);
            BOOST_CHECK(!std::numeric_limits<SetMyInfo::UInt16>::is_signed);
            BOOST_CHECK(std::numeric_limits<SetMyInfo::SInt16>::is_signed);
        }

        BOOST_AUTO_TEST_CASE(int32_lengths) {
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::Int), 4);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::UInt), 4);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::Int32), 4);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::UInt32), 4);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::SInt32), 4);

            BOOST_CHECK(std::numeric_limits<SetMyInfo::Int>::is_signed);
            BOOST_CHECK(!std::numeric_limits<SetMyInfo::UInt>::is_signed);
            BOOST_CHECK(std::numeric_limits<SetMyInfo::Int32>::is_signed);
            BOOST_CHECK(!std::numeric_limits<SetMyInfo::UInt32>::is_signed);
            BOOST_CHECK(std::numeric_limits<SetMyInfo::SInt32>::is_signed);
        }

        BOOST_AUTO_TEST_CASE(int64_lengths) {
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::Int64), 8);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::UInt64), 8);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::SInt64), 8);

            BOOST_CHECK(std::numeric_limits<SetMyInfo::Int64>::is_signed);
            BOOST_CHECK(!std::numeric_limits<SetMyInfo::UInt64>::is_signed);
            BOOST_CHECK(std::numeric_limits<SetMyInfo::SInt64>::is_signed);
        }

        BOOST_AUTO_TEST_CASE(float_types_lengths) {
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::Float32), 4);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::Float), 4);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::Double64), 8);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::Double), 8);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::LongDouble), 16);//128 bit
        }

        BOOST_AUTO_TEST_CASE(pointer_types_lengths) {
            #ifdef __LP64__
                BOOST_CHECK_EQUAL(sizeof(SetMyInfo::Pointer), 8);
                BOOST_CHECK_EQUAL(sizeof(SetMyInfo::UPointerInt), 8);
            #else
                BOOST_CHECK_EQUAL(sizeof(SetMyInfo::Pointer), 4);
                BOOST_CHECK_EQUAL(sizeof(SetMyInfo::UPointerInt), 4);
            #endif

        }

        BOOST_AUTO_TEST_CASE(misc_types_lengths) {
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::Type), 8);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::UPosition), 8);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::SPosition), 8);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::Position), 8);
        }

        BOOST_AUTO_TEST_CASE(date_time_types_lengths) {
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::Date), 8);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::Time), 16);
            BOOST_CHECK_EQUAL(sizeof(SetMyInfo::DateTime), 24);
        }

        BOOST_AUTO_TEST_CASE(data_type_enums_values) {
            BOOST_CHECK_EQUAL(SetMyInfo::DataTypes::UINT8, 1);
            BOOST_CHECK_EQUAL(SetMyInfo::DataTypes::SINT8, 2);
            BOOST_CHECK_EQUAL(SetMyInfo::DataTypes::UINT16, 3);
            BOOST_CHECK_EQUAL(SetMyInfo::DataTypes::SINT16, 4);
            BOOST_CHECK_EQUAL(SetMyInfo::DataTypes::UINT32, 5);
            BOOST_CHECK_EQUAL(SetMyInfo::DataTypes::SINT32, 6);
            BOOST_CHECK_EQUAL(SetMyInfo::DataTypes::UINT64, 7);
            BOOST_CHECK_EQUAL(SetMyInfo::DataTypes::SINT64, 8);
            BOOST_CHECK_EQUAL(SetMyInfo::DataTypes::FLOAT, 9);
            BOOST_CHECK_EQUAL(SetMyInfo::DataTypes::DOUBLE, 10);
            BOOST_CHECK_EQUAL(SetMyInfo::DataTypes::LONG_DOUBLE, 11);
            BOOST_CHECK_EQUAL(SetMyInfo::DataTypes::DATE, 12);
            BOOST_CHECK_EQUAL(SetMyInfo::DataTypes::TIME, 13);
            BOOST_CHECK_EQUAL(SetMyInfo::DataTypes::DATE_TIME, 14);
            BOOST_CHECK_EQUAL(SetMyInfo::DataTypes::STRING, 15);
        }

    BOOST_AUTO_TEST_SUITE_END()

BOOST_AUTO_TEST_SUITE_END()

#endif // SET_MY_INFO_DATA_TYPES_TEST_H_
