// Header-only configuration test

#ifdef FMT_MODULE
import fmt;
#else
#  include "fmt/base.h"
#  include "fmt/ostream.h"
#endif

auto main() -> int
{
  fmt::print("OK");
}
