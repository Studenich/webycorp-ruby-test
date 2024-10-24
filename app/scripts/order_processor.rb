# frozen_string_literal: true

require_relative '../lib/fakestoreapi_service/fake_store'
require 'json'

module OrderProcessor
  def self.call
    Application.logger.info 'Starting to process orders...'
    # 1. Fetch Carts from Fake Store API
    carts = FakeStore.all_carts
    Application.logger.info 'Part 1 has been done successfully.'

    # 2. Create a Customer in Stripe
    customers = create_customers(carts)

    # 3. Create Product and Prices
    products = create_products(carts)

    # 4. Create Invoice Items
    invoice_items = create_invoice_items(carts, customers, products)

    # 5. Create a draft invoice
    invoices = create_draft_invoices(customers)

    # 6. Add invoice line items
    add_invoice_line_items(customers, invoices, invoice_items)

    # 7. Finalize the Invoice
    finalize_invoices(invoices)

    Application.logger.info 'All orders have been processed successfully.'
  end

  def self.create_customers(carts)
    customers = {}
    Application.logger.info carts
    unique_user_ids = carts.map { |cart| cart['userId'].to_i }.uniq
    Application.logger.info unique_user_ids
    unique_user_ids.each do |user_id|
      user = FakeStore.get_user(user_id)
      stripe_customer = Stripe::Customer.create({
                                                  name: "#{user['name']['firstname']} #{user['name']['lastname']}",
                                                  email: user['email']
                                                })
      Application.logger.info "Created stripe customer '...#{stripe_customer['id'].chars.last(3).join}' successfully."
      customers[user_id] = stripe_customer['id']
    end
    Application.logger.info 'Part 2 has been done successfully.'
    customers
  end

  def self.create_products(carts)
    products = {}
    unique_product_ids = carts.flat_map { |cart| cart['products'].map { |product| product['productId'] } }.uniq
    unique_product_ids.each do |product_id|
      product = FakeStore.get_product(product_id)
      stripe_product = Stripe::Product.create({
                                                name: product['title']
                                              })
      Application.logger.info "Created stripe product '...#{stripe_product['id'].chars.last(3).join}' successfully."
      stripe_price = Stripe::Price.create({
                                            currency: 'usd',
                                            unit_amount: (product['price'] * 100).to_i,
                                            product: stripe_product['id']
                                          })
      Application.logger.info "Created stripe price '...#{stripe_price['id'].chars.last(3).join}' successfully."
      products[product_id] = { stripe_id: stripe_product['id'], stripe_price: stripe_price['id'] }
    end
    Application.logger.info 'Part 3 has been done successfully.'
    products
  end

  def self.create_invoice_items(carts, customers, products)
    invoice_items = Hash.new { |k, v| k[v] = [] }
    carts.each do |cart|
      cart['products'].each do |product|
        stripe_invoice_item = Stripe::InvoiceItem.create({
                                                           customer: customers[cart['userId']],
                                                           price: products[product['productId']][:stripe_price],
                                                           quantity: product['quantity']
                                                         })
        Application.logger.info "Created stripe invoice item '...#{stripe_invoice_item['id'].chars.last(3).join}' successfully."
        invoice_items[cart['userId']] << stripe_invoice_item['id']
      end
    end
    Application.logger.info 'Part 4 has been done successfully.'
    invoice_items
  end

  def self.create_draft_invoices(customers)
    invoices = {}
    customers.each_value do |stripe_customer_id|
      stripe_invoice = Stripe::Invoice.create({
                                                customer: stripe_customer_id,
                                                auto_advance: false
                                              })
      Application.logger.info "Created draft stripe invoice '...#{stripe_invoice['id'].chars.last(3).join}' successfully."
      invoices[stripe_customer_id] = stripe_invoice['id']
    end
    Application.logger.info 'Part 5 has been done successfully.'
    invoices
  end

  def self.add_invoice_line_items(customers, invoices, invoice_items)
    customers.each do |user_id, stripe_customer_id|
      invoice_items_param_array = invoice_items[user_id].map do |invoice_items_stripe_id|
        { invoice_item: invoice_items_stripe_id }
      end
      Stripe::Invoice.add_lines(
        invoices[stripe_customer_id],
        {
          lines: invoice_items_param_array
        }
      )
      Application.logger.info "Added lines to draft stripe invoice '...#{invoices[stripe_customer_id].chars.last(3).join}' successfully."
    end
    Application.logger.info 'Part 6 has been done successfully.'
  end

  def self.finalize_invoices(invoices)
    invoices.each_value do |stripe_invoice_id|
      Stripe::Invoice.finalize_invoice(stripe_invoice_id)
      Application.logger.info "Finalized stripe invoice '...#{stripe_invoice_id.chars.last(3).join}' successfully."
    end
    Application.logger.info 'Part 7 has been done successfully.'
  end

  private_class_method :create_customers,
                       :create_products,
                       :create_invoice_items,
                       :create_draft_invoices,
                       :add_invoice_line_items,
                       :finalize_invoices
end
