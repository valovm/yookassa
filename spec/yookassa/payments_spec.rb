# frozen_string_literal: true

RSpec.describe Yookassa::Payments do
  let(:config) { { shop_id: "SHOP_ID", api_key: "API_KEY" } }
  let(:payment) { described_class.new(**config) }
  let(:idempotency_key) { SecureRandom.hex(1) }

  let(:body) { File.read("spec/fixtures/payment_response.json") }

  before { stub_request(:any, //).to_return(body: body, headers: { "Content-Type" => "application/json" }) }

  shared_examples "returns_payment_object" do
    it "returns success" do
      expect(subject).to be_a Yookassa::Entity::Payment
      expect(subject.id).to eq "2490ded1-000f-5000-8000-1f64111bc63e"
      expect(subject.test).to eq true
      expect(subject.paid).to eq false
      expect(subject.status).to eq "pending"
      expect(subject.captured_at).to eq nil
      expect(subject.created_at).to eq DateTime.parse("2019-06-10T21:26:41.395Z")
      expect(subject.description).to eq nil
      expect(subject.expires_at).to eq nil
      expect(subject.metadata).to eq({})

      expect(subject.amount).to be_a Yookassa::Entity::Amount
      expect(subject.amount.currency).to eq "RUB"
      expect(subject.amount.value).to eq 10.0

      expect(subject.confirmation).to be_a Yookassa::Entity::Confirmation::Redirect
      expect(subject.confirmation.confirmation_url).to eq "https://money.yookassa.ru/payments/external/confirmation?orderId=2490ded1-000f-5000-8000-1f64111bc63e"
      expect(subject.confirmation.type).to eq "redirect"
      expect(subject.confirmation.return_url).to eq "https://url.test"
      expect(subject.confirmation.enforce).to eq nil

      expect(Yookassa::Entity::PaymentMethods.valid?(subject.payment_method)).to be_truthy
      expect(subject.payment_method).to be_a(Yookassa::Entity::PaymentMethod::BankCard)
      expect(subject.payment_method.card).to eq nil
      expect(subject.payment_method.id).to eq "2490ded1-000f-5000-8000-1f64111bc63e"
      expect(subject.payment_method.saved).to eq false
      expect(subject.payment_method.type).to eq "bank_card"
      expect(subject.payment_method.title).to eq nil
    end
  end

  shared_examples "returns_payment_object_with_card_product" do
    it "parses bank_card.card_product + source=mir_pay" do
      expect(subject).to be_a Yookassa::Entity::Payment
      expect(subject.id).to eq "30fea5b4-000f-5001-8000-1ee0c9c8d752"

      expect(subject.payment_method).to be_a(Yookassa::Entity::PaymentMethod::BankCard)
      expect(subject.payment_method.type).to eq "bank_card"
      expect(subject.payment_method.status).to eq "inactive"
      expect(subject.payment_method.title).to eq "Bank card *8159"

      expect(subject.payment_method.card).to be_a(Yookassa::Entity::Card)
      expect(subject.payment_method.card.source).to eq "mir_pay"
      expect(subject.payment_method.card.card_product).to be_a(Yookassa::Entity::CardProduct)
      expect(subject.payment_method.card.card_product.code).to eq "TKN"
      expect(subject.payment_method.card.card_product.name).to eq "MIR Token Debit"
    end
  end

  shared_examples "returns_real_world_mir_pay_payment_object" do
    it "parses masked expiry + 3ds fields" do
      expect(subject).to be_a Yookassa::Entity::Payment
      expect(subject.status).to eq "succeeded"
      expect(subject.paid).to eq true
      expect(subject.refundable).to eq true
      expect(subject.receipt_registration).to eq "succeeded"

      expect(subject.payment_method).to be_a(Yookassa::Entity::PaymentMethod::BankCard)
      expect(subject.payment_method.card.expiry_year).to eq "***"
      expect(subject.payment_method.card.expiry_month).to eq "***"

      expect(subject.authorization_details.rrn).to eq "601818497215"
      expect(subject.authorization_details.auth_code).to eq "070221"
      expect(subject.authorization_details.three_d_secure[:applied]).to eq false
      expect(subject.authorization_details.three_d_secure[:method_completed]).to eq false
      expect(subject.authorization_details.three_d_secure[:challenge_completed]).to eq false
    end
  end

  describe "#create" do
    let(:params) { JSON.parse(File.read("spec/fixtures/payment_request.json")) }
    let(:url) { "https://api.yookassa.ru/v3/payments" }

    subject { payment.create(payment: params, idempotency_key: idempotency_key) }

    it "sends a request" do
      subject
      expect(a_request(:post, url)).to have_been_made
    end

    it_behaves_like "returns_payment_object"
  end

  describe "#find" do
    let(:payment_id) { "2490ded1-000f-5000-8000-1f64111bc63e" }
    let(:url) { "https://api.yookassa.ru/v3/payments/#{payment_id}" }

    subject { payment.find(payment_id: payment_id) }

    it "sends a request" do
      subject
      expect(a_request(:get, url)).to have_been_made
    end

    it_behaves_like "returns_payment_object"
  end

  describe "#find (bank_card with card_product)" do
    let(:body) { File.read("spec/fixtures/payment_response_with_card_product.json") }
    let(:payment_id) { "30fea5b4-000f-5001-8000-1ee0c9c8d752" }
    let(:url) { "https://api.yookassa.ru/v3/payments/#{payment_id}" }

    subject { payment.find(payment_id: payment_id) }

    it "sends a request" do
      subject
      expect(a_request(:get, url)).to have_been_made
    end

    it_behaves_like "returns_payment_object_with_card_product"
  end

  describe "#find (real world mir_pay example)" do
    let(:body) { File.read("spec/fixtures/payment_response_real_world_mir_pay.json") }
    let(:payment_id) { "30fea5b4-000f-5001-8000-1ee0c9c8d752" }
    let(:url) { "https://api.yookassa.ru/v3/payments/#{payment_id}" }

    subject { payment.find(payment_id: payment_id) }

    it "sends a request" do
      subject
      expect(a_request(:get, url)).to have_been_made
    end

    it_behaves_like "returns_real_world_mir_pay_payment_object"
  end

  describe "#capture" do
    let(:payment_id) { "2490ded1-000f-5000-8000-1f64111bc63e" }
    let(:url) { "https://api.yookassa.ru/v3/payments/#{payment_id}/capture" }

    subject { payment.capture(payment_id: payment_id, idempotency_key: idempotency_key) }

    it "sends a request" do
      subject
      expect(a_request(:post, url)).to have_been_made
    end

    it_behaves_like "returns_payment_object"
  end

  describe "#cancel" do
    let(:payment_id) { "2490ded1-000f-5000-8000-1f64111bc63e" }
    let(:url) { "https://api.yookassa.ru/v3/payments/#{payment_id}/cancel" }

    subject { payment.cancel(payment_id: payment_id, idempotency_key: idempotency_key) }

    it "sends a request" do
      subject
      expect(a_request(:post, url)).to have_been_made
    end

    it_behaves_like "returns_payment_object"
  end

  describe "#list" do
    let(:body) { File.read("spec/fixtures/list_payment_response.json") }

    let(:filters) do
      {
        limit: 20,
        "created_at.gt": "2018-07-18T10:51:18.139Z"
      }
    end

    let(:url) { "https://api.yookassa.ru/v3/payments?limit=20&created_at.gt=2018-07-18T10:51:18.139Z" }

    subject { payment.list(filters: filters) }

    it "sends a request" do
      subject
      expect(a_request(:get, url)).to have_been_made
    end

    it "returns a collection" do
      expect(subject).to be_a Yookassa::Entity::PaymentCollection
    end
  end
end
