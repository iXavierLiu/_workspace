// Module partition: class declaration.
// Public API only. Implementation details (data members, helper classes)
// are hidden behind a `Widget::Impl` forward declaration + pointer.
module;

#include <memory>
#include <string_view>

export module core:classes;

export namespace core {

// PIMPL: `Widget` holds a pointer to a complete type that is defined
// only in the implementation unit (`classes-impl.cpp`). Consumers see
// only the public interface below; they cannot name `Widget::Impl`,
// `Widget::Impl::history_`, or any other internal member.
class Widget {
public:
    Widget();
    explicit Widget(int id);
    ~Widget();

    Widget(Widget const&);
    auto operator=(Widget const&) -> Widget&;

    Widget(Widget&&) noexcept;
    auto operator=(Widget&&) noexcept -> Widget&;

    auto id() const -> int;
    auto label() const -> std::string_view;
    auto set_label(std::string_view label) -> void;

    // Demonstrates an API that internally uses private helper types
    // (call history, etc.) -- visible to consumers, but the helper
    // types are not.
    auto call_count() const -> int;

    static auto default_label() -> std::string_view;

private:
    // Forward declaration + pointer: 8 bytes on the consumer's stack,
    // no knowledge of the pointee's layout. The `struct Impl`
    // declaration here is *not* exported (it is inside a non-export
    // region of an exported class), so consumers cannot write
    // `core::Widget::Impl` at all.
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

} // namespace core
