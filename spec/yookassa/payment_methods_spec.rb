# frozen_string_literal: true

RSpec.describe Yookassa::Entity::PaymentMethods do
  let(:hash) do
    {
      type: "bank_card",
      id: "3105c1cf-000f-5000-b000-1bec770ded40",
      saved: false,
      status: "inactive",
      title: "Bank card *0659",
      card: {
        first6: "220024",
        last4: "0659",
        expiry_year: "2031",
        expiry_month: "11",
        card_type: "Mir",
        card_product: { code: "PRD", name: "MIR Advanced" },
        issuer_country: "RU",
        issuer_name: "VTB"
      }
    }
  end

  it "coerces a symbol-key hash into BankCard" do
    pm = described_class[hash]
    expect(pm).to be_a(Yookassa::Entity::PaymentMethod::BankCard)
    expect(pm.type).to eq("bank_card")
    expect(pm.title).to eq("Bank card *0659")
    expect(pm.card).to be_a(Yookassa::Entity::Card)
    expect(pm.card.card_product).to be_a(Yookassa::Entity::CardProduct)
  end

  it "coerces a string-key hash into BankCard" do
    string_key_hash = JSON.parse(hash.to_json)
    pm = described_class[string_key_hash]
    expect(pm).to be_a(Yookassa::Entity::PaymentMethod::BankCard)
    expect(pm.type).to eq("bank_card")
  end
end

