# frozen_string_literal: true

require_relative "./types"
require_relative "./card_product"

module Yookassa
  module Entity
    class Card < Dry::Struct
      Sources = Types::String.enum("apple_pay", "google_pay", "mir_pay")
      ExpiryField = Types::Coercible::Integer | Types::String

      # first6 [string, optional]
      # First 6 digits of the card’s number (BIN). For payments with bank cards saved in YooMoney
      # and other services, the specified BIN might not correspond with the last4, expiry_year, expiry_month values.
      # For payments with bank cards saved in Apple Pay or Google Pay, the parameter contains Device Account Number.
      attribute? :first6, Types::Coercible::Integer

      # last4 [string, required]
      # Last 4 digits of the card's number.
      attribute :last4, Types::Coercible::Integer

      # expiry_month [string, required]
      # Expiration date, month, MM.
      attribute? :expiry_month, ExpiryField

      # expiry_year [string, required]
      # Expiration date, year, YYYY.
      attribute? :expiry_year, ExpiryField

      # card_type [string, required]
      # Type of bank card. Possible values: MasterCard (for Mastercard and Maestro cards), Visa (for Visa and Visa Electron cards),
      # Mir, UnionPay, JCB, AmericanExpress, DinersClub, and Unknown.
      attribute :card_type, Types::String.enum("MasterCard", "Visa", "Mir", "UnionPay", "JCB", "AmericanExpress", "DinersClub", "Unknown")

      # issuer_country [string, optional]
      # Code of the country where the bank card was issued according to ISO-3166 alpha-2. Example: RU.
      attribute? :issuer_country, Types::String

      # issuer_name [string, optional]
      # Name of the issuing bank.
      attribute? :issuer_name, Types::String

      # card_product [object, optional]
      # Card product details (returned for some cards, e.g. tokenized Mir cards).
      attribute? :card_product, CardProduct

      # source [string, optional]
      # Source of bank card details. Possible values: apple_pay, google_pay, mir_pay.
      # For payments where the user selects a card saved in Apple Pay or Google Pay.
      attribute? :source, Sources
    end
  end
end
