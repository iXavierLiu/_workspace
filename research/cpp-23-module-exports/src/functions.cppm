//
// Module partition: free function declarations.
// Partition is owned by `core`. The primary interface re-exports it
// via `export import :functions;`, so importers of `core` see these
// names.
module;

#include <string>
#include <string_view>

export module core:functions;

export namespace core {

auto add(int a, int b) -> int;
auto greet(std::string_view name) -> std::string;

} // namespace core
