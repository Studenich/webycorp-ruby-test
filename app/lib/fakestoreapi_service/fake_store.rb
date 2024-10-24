# frozen_string_literal: true

require 'faraday'
require 'json'

module FakeStore
  BASE_URL = 'https://fakestoreapi.com'

  def self.all_carts
    get('/carts')
  end

  def self.get_user(user_id)
    get("/users/#{user_id}")
  end

  def self.get_product(product_id)
    get("/products/#{product_id}")
  end

  def self.get(endpoint)
    response = Faraday.get("#{BASE_URL}#{endpoint}")
    Application.logger.info "Called to FakeStore #{endpoint} successfully."
    JSON.parse(response.body)
  end

  private_class_method :get
end
