// Header-only configuration test

#include <string_view>

#ifdef FMT_MODULE
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
