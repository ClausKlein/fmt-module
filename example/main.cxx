#include <string>

void hello_world(std::string const& name);

int main(int argc, char* argv[])
{
  const char* name = "Voldemort?";
  hello_world(name);
  while (--argc > 0) {
    hello_world(argv[argc]);
  }
  return 0;
}
