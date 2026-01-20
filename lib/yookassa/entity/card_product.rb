# frozen_string_literal: true

require_relative "./types"

module Yookassa
  module Entity
    # Card product details (e.g. tokenized card product info)
    class CardProduct < Dry::Struct
      attribute? :code, Types::String
      attribute? :name, Types::String
    end
  end
end

