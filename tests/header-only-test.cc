// Header-only configuration test

#ifdef FMT_USE_MODULES
import fmt;
#else
#  include "fmt/base.h"
#  include "fmt/ostream.h"
#endif

// #ifndef FMT_HEADER_ONLY
// #  error "Not in the header-only mode."
// #endif

#include "gtest/gtest.h"

TEST(header_only_test, format)
{
  EXPECT_EQ(fmt::format("foo"), "foo");
}
