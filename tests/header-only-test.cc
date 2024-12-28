// Header-only configuration test

#ifdef FMT_MODULE

#ifdef HAS_STDLIB_MODULES
import std;
import std.compat;
#else
#  include <string_view>
#endif

import fmt;

#else

#  include "fmt/base.h"
#  include "fmt/ostream.h"

#endif

auto main() -> int
{
  constexpr std::string_view text{"constexpr"};
  fmt::print(text);
}
