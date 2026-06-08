// Module implementation unit for partition `core:classes`.
// All implementation details live here. None of the names declared in
// this file are visible to importers of `core`.
module;

#include <memory>
#include <string>
#include <string_view>
#include <vector>

module core;
import :classes;

namespace core {

// ---------------------------------------------------------------------------
// Private helpers -- completely hidden from importers of `core`.
// ---------------------------------------------------------------------------
namespace {

// Internal logger, used by Widget. Not exported; consumers cannot name
// it.
class InternalLogger {
public:
    auto log(std::string_view msg) -> void {
        buffer_ += msg;
        buffer_ += '\n';
    }
    auto dump() const -> std::string { return buffer_; }
private:
    std::string buffer_;
};

} // anonymous namespace

// ---------------------------------------------------------------------------
// Widget::Impl -- the complete type. Defined in this implementation
// unit, never in any interface, so importers of `core` see only the
// pointer in `Widget` and have no access to any field below.
// ---------------------------------------------------------------------------
struct Widget::Impl {
    int id = 0;
    std::string label;
    int call_count = 0;

    // Plenty of "implementation details" that consumers should never
    // need to know about:
    InternalLogger logger;
    std::vector<std::string> call_history;
    std::string secret_token;  // simulated sensitive state
    double cached_value = 0.0;
};

// ---------------------------------------------------------------------------
// Widget -- thin wrapper over Impl*. All real work is forwarded.
// ---------------------------------------------------------------------------

Widget::Widget()
    : impl_(std::make_unique<Impl>()) {
    impl_->label = default_label();
    impl_->logger.log("default-constructed");
}

Widget::Widget(int id)
    : impl_(std::make_unique<Impl>()) {
    impl_->id = id;
    impl_->label = default_label();
    impl_->logger.log("id-constructed");
}

Widget::~Widget() = default;  // unique_ptr<Impl> cleans up

Widget::Widget(Widget const& other)
    : impl_(std::make_unique<Impl>(*other.impl_)) {}

auto Widget::operator=(Widget const& other) -> Widget& {
    if (this != &other) *impl_ = *other.impl_;
    return *this;
}

Widget::Widget(Widget&& other) noexcept = default;
auto Widget::operator=(Widget&& other) noexcept -> Widget& = default;

auto Widget::id() const -> int {
    impl_->call_count += 1;
    impl_->call_history.push_back("id()");
    impl_->logger.log("id() called");
    return impl_->id;
}

auto Widget::label() const -> std::string_view {
    impl_->call_count += 1;
    impl_->call_history.push_back("label()");
    return impl_->label;
}

auto Widget::set_label(std::string_view label) -> void {
    impl_->call_count += 1;
    impl_->call_history.push_back("set_label()");
    impl_->label = label;
    impl_->logger.log("label changed");
}

auto Widget::call_count() const -> int {
    return impl_->call_count;
}

auto Widget::default_label() -> std::string_view {
    return "widget";
}

} // namespace core
