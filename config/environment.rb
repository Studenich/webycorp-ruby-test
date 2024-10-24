# frozen_string_literal: true

require 'dotenv/load'

ENV['RACK_ENV'] ||= 'development'
ENV['TZ'] = 'UTC'

require 'bundler/setup'
Bundler.require(:default, ENV.fetch('RACK_ENV'))

require_relative 'application'
Application.load_app!

require_relative '../app/scripts/order_processor'
