//
// Module implementation unit: shared, file-internal helpers.
// Not exported -- contains only module-internal entities.
module;

#include <cctype>
#include <string>
#include <string_view>

module core;

namespace core::detail {

// Private free function: not visible to importers of `core`.
auto to_upper(std::string_view s) -> std::string {
    std::string out{s};
    for (auto& c : out) {
        c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
    }
    return out;
}

// Private constant: not visible to importers of `core`.
inline constexpr int kInternalMagic = 42;

} // namespace core::detail
