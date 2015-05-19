module Tellum
  module HideProtectedFields
    extend ActiveSupport::Concern
    def protected_fields(fields=[:created_at, :updated_at], &block)
      define_method :hide_fields do
        user_fields = self.attributes.keep_if { |k, v| !fields.include?(k.to_sym) }
        block.call(user_fields) if block_given?
        user_fields
      end
    end
  end
end

