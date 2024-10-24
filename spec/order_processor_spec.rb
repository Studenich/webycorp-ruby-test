# frozen_string_literal: true

require_relative '../app/scripts/order_processor'
require 'vcr'
require 'json'

RSpec.describe OrderProcessor, :vcr do
  before do
    allow(FakeStore).to receive(:all_carts).and_call_original
    allow(FakeStore).to receive(:get_user).and_call_original
    allow(FakeStore).to receive(:get_product).and_call_original

    allow(Stripe::Customer).to receive(:create).and_call_original
    allow(Stripe::Product).to receive(:create).and_call_original
    allow(Stripe::Price).to receive(:create).and_call_original
    allow(Stripe::InvoiceItem).to receive(:create).and_call_original
    allow(Stripe::Invoice).to receive(:create).and_call_original
    allow(Stripe::Invoice).to receive(:add_lines).and_call_original
    allow(Stripe::Invoice).to receive(:finalize_invoice).and_call_original
  end

  describe 'FakeStore methods' do
    it 'tests all_carts' do
      carts = FakeStore.all_carts
      expect(carts).to be_a(Array)
      carts.each do |cart|
        expect(cart).to be_a(Hash)
        expect(cart).to have_key('userId')
        expect(cart).to have_key('products')
        expect(cart['products']).to be_a(Array)
        expect(cart['products']).to all(
          be_a(Hash)
            .and(have_key('productId'))
            .and(have_key('quantity'))
        )
      end
    end

    it 'tests get_product' do
      product_id = 1
      product = FakeStore.get_product(product_id)
      expect(product).to be_a(Hash)
      expect(product).to have_key('title')
      expect(product).to have_key('price')
      expect(product['price']).to be_a(Float)
    end

    it 'tests get_user' do
      user_id = 1
      user = FakeStore.get_user(user_id)
      expect(user).to be_a(Hash)
      expect(user).to have_key('email')
      expect(user).to have_key('name')
      expect(user['name']).to be_a(Hash)
      expect(user['name']).to have_key('firstname')
      expect(user['name']).to have_key('lastname')
    end
  end

  describe 'OrderProcessor private methods' do
    let(:carts) do
      [
        { 'id' => 1, 'userId' => 1, 'date' => '2020-03-02T00:00:00.000Z',
          'products' => [{ 'productId' => 1, 'quantity' => 4 },
                         { 'productId' => 2, 'quantity' => 1 },
                         { 'productId' => 3, 'quantity' => 6 }],
          '__v' => 0 },
        { 'id' => 2, 'userId' => 2, 'date' => '2020-01-02T00:00:00.000Z',
          'products' => [{ 'productId' => 2, 'quantity' => 4 },
                         { 'productId' => 1, 'quantity' => 10 },
                         { 'productId' => 5, 'quantity' => 2 }],
          '__v' => 0 }
      ]
    end

    it 'tests create_customers' do
      customers = described_class.send(:create_customers, carts)
      expect(customers.size).to eq(2)
      customers.each_value do |customer_id|
        expect(customer_id).to match(/^cus_.*/)
      end
    end

    it 'tests create_products' do
      products = described_class.send(:create_products, carts)
      expect(products.size).to eq(4)
      products.each_value do |product|
        expect(product[:stripe_id]).to match(/^prod_.*/)
        expect(product[:stripe_price]).to match(/^price_.*/)
      end
    end

    it 'tests create_invoice_items' do
      customers = described_class.send(:create_customers, carts)
      products = described_class.send(:create_products, carts)
      invoice_items = described_class.send(:create_invoice_items, carts, customers, products)
      expect(invoice_items.size).to eq(2)
      expect(invoice_items[1].size).to eq(3) # "userId"=>1 - key for invoice_items hash
      expect(invoice_items[2].size).to eq(3) # "userId"=>2 - key for invoice_items hash
      expect(invoice_items.values.flatten).to all(match(/^ii_.*/))
    end

    it 'tests create_draft_invoices' do
      customers = described_class.send(:create_customers, carts)
      invoices = described_class.send(:create_draft_invoices, customers)
      expect(invoices.size).to eq(2)
      invoices.each_value do |invoice_id|
        expect(invoice_id).to match(/^in_.*/)
      end
    end
  end

  describe '#call' do
    it 'processes orders correctly and completes all steps' do
      described_class.call

      expect(FakeStore).to have_received(:all_carts)
      expect(FakeStore).to have_received(:get_user).at_least(:once)
      expect(FakeStore).to have_received(:get_product).at_least(:once)
      expect(Stripe::Customer).to have_received(:create).at_least(:once)
      expect(Stripe::Product).to have_received(:create).at_least(:once)
      expect(Stripe::InvoiceItem).to have_received(:create).at_least(:once)
      expect(Stripe::Invoice).to have_received(:create).at_least(:once)
      expect(Stripe::Invoice).to have_received(:add_lines).at_least(:once)
      expect(Stripe::Invoice).to have_received(:finalize_invoice).at_least(:once)
    end
  end
end
