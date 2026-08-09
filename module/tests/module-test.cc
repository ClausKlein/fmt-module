// Header-only configuration test

#ifdef FMT_MODULE

#  ifdef FMT_IMPORT_STD
import std;
import std.compat;
#  else
#    include <string_view>
#  endif

import fmt;

#else

#  include "fmt/base.h"
#  include "fmt/ostream.h"

#endif

// NOLINTNEXTLINE(bugprone-exception-escape)
auto main() -> int {
  constexpr std::string_view text{"constexpr"};
  fmt::print(text);
}
