# Simple Form, styled for Tailwind.
#
# Simple Form's default wrappers target Bootstrap-era markup, so forms built on
# the defaults look unstyled next to the rest of the UI. This is a one-time
# setup cost, done once here rather than improvised per form.
#
# NOTE: these class strings live in Ruby, not in a .erb file, so Tailwind's
# scanner would not see them. app/assets/tailwind/application.css therefore
# carries a `@source` directive pointing at this file - keep the two in step.
SimpleForm.setup do |config|
  config.wrappers :default,
    class: "mb-5",
    hint_class: "meta mt-1",
    error_class: "error-text",
    valid_class: "" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly

    b.use :label, class: "label"
    b.use :input, class: "input", error_class: "input border-danger"
    b.use :hint, wrap_with: { tag: :p, class: "meta mt-1" }
    b.use :error, wrap_with: { tag: :p, class: "error-text" }
  end

  config.default_wrapper = :default
  config.boolean_style = :nested
  config.button_class = "btn btn-primary"
  config.error_notification_tag = :div
  config.error_notification_class = "card border-danger/40 p-4 text-sm text-danger"
  config.label_class = "label"
  config.generate_additional_classes_for = []
end
