// Header-only configuration test

#ifdef FMT_MODULE
import fmt;
#else
#  include "fmt/base.h"
#  include "fmt/ostream.h"
#  include <string_view>
#endif


auto main() -> int
{
#ifdef FMT_MODULE
  fmt::print("OK");
#else
  constexpr std::string_view text{"constexpr"};
  fmt::print(text);
#endif
}
