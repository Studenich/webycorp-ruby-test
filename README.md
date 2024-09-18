# Test Assignment

## Description

This project is a Ruby-based application designed to generate invoices for completed orders.

## Background

In a bustling e-commerce company, managing orders and generating invoices manually became a time-consuming task. To streamline the process, the company decided to develop an automated invoicing system. This project is a simplified version of that system, aimed at evaluating the skills of potential Ruby developers.

For this project, we use test APIs from the following services:
- [Fake Store API](https://fakestoreapi.com/docs)
- [Stripe](https://docs.stripe.com/api)

Both services are free for testing. You need to
register and obtain an API Secret key for Stripe.

## Skills Evaluated

This assignment is designed to evaluate the following skills:

1. **Ruby Proficiency**: Understanding of Ruby syntax and language features.
2. **Environment Setup**: Proficiency in using RVM and Bundler for managing Ruby versions and dependencies.
3. **Project Comprehension**: Skill in understanding and navigating an existing codebase.
4. **Version Control**: Experience with Git, including forking repositories, cloning, and working with branches.
5. **API Integration**: Ability to interact with external APIs (Fake Store API and Stripe).
6. **Testing**: Ability to write and run tests using RSpec or another testing framework.
7. **Problem Solving**: Ability to understand and solve real-world problems in an e-commerce context.

## Installation

1. Fork the repository.

2. Clone the repository:
    ```sh
    git clone <repository-url>
    cd <repository-directory>
    ```

3. Ensure the required Ruby version is installed in RVM and create a gemset for the project:
   ```sh
    rvm install 2.7.2
    rvm use 2.7.2@webycorp-ruby-test --create
    ```

3. Install dependencies:
    ```sh
    bundle install
    ```

## Usage

### Development Console

To start the development console, use:

```sh
bin/pry
```

### Running the Linter

To run the linter, use:

```sh
bin/rubocop
```

### Running the Tests

To run the test suite, use:

```sh
bin/rspec
```

## Configuration

This project uses the `config` gem for configuration management. There is a placeholder for the Stripe API key. You can
provide it by setting the environment variable `TEST_APP__STRIPE__API_KEY` or by creating a file
`config/settings/development.local.yml`. (Refer to the `config` gem documentation for more details.)

## Task

You must create a script in the `app/scripts` directory with a `call` method. When invoked, this method should execute the main business logic.

Steps to Create an Invoice in Stripe Using Fake Store API

1. **Fetch Carts from Fake Store API**
   - Use the endpoint `/carts` ([Fake Store API Documentation](https://fakestoreapi.com/docs#c-all)) to retrieve a list of carts.

2. **Create a Customer in Stripe**
   - For each cart, create a corresponding customer in Stripe using the endpoint `/v1/customers` ([Stripe API Documentation](https://docs.stripe.com/api/customers/create?lang=ruby)).
   - You can use the `userId` from the cart to make a request to the endpoint `/users/:userId` ([Fake Store API Documentation](https://fakestoreapi.com/docs#u-single)). From the retrieved data, you need to use the values of the email, firstname, and lastname attributes.

3. **Create Product and Prices**
   - For each product in the cart, create a Stripe product using the endpoint `/v1/products` ([Stripe API Documentation](https://docs.stripe.com/api/products/create)).
   The product's `name` will be used to set the description of the invoice item.
   - To set the product's `name`, you can use the `productId` from the cart to make a request to the endpoint `/products/:productId` ([Fake Store API Documentation](https://fakestoreapi.com/docs#p-single)). From the retrieved data, you need to use the value of the `title` attribute.
   - For each created product in Stripe, create a price using the endpoint `/v1/prices` ([Stripe API Documentation](https://docs.stripe.com/api/prices/create)).
   - To set the `product`, use the `id` of the previously created product. For `currency`, specify `usd`, and for `unit_amount`, use the value of the `price` attribute from the previous request to the endpoint `/products/:productId` ([Fake Store API Documentation](https://fakestoreapi.com/docs#p-single)).

4. **Create Invoice Items**
   - From the previously created products, you need to create invoice items. To do this, use the endpoint `/v1/invoiceitems` ([Stripe API Documentation](https://docs.stripe.com/api/invoiceitems/create)).
   - To set the `customer`, use the `id` of the previously created Customer. To set the `price`, use the `id` of the Price created in the previous step. To set the `quantity`, use the value of the `quantity` attribute from the cart.

5. **Create a draft invoice**
   - To create a draft invoice, use the endpoint `/v1/invoices` ([Stripe API Documentation](https://docs.stripe.com/api/invoices/create)).
   - For `customer`, specify the `id` of the previously created Customer. For `auto_advance`, set it to `false`.

6. **Add invoice line items**
   - You need to link the invoice with the invoice items. To do this, use the endpoint `/v1/invoices/:id/add_lines` ([Stripe API Documentation](https://docs.stripe.com/api/invoice-line_item/bulk-add)).
   - Specify the `id` of the previously created invoice and the `id` of all created Invoice Items for the `invoice_item` attributes.

7. **Finalize the Invoice**
   - Finalize the invoice to make it ready for sending. Use the endpoint `/v1/invoices/:id/finalize` ([Stripe API Documentation](https://docs.stripe.com/api/invoices/finalize)), specifying the `id` of the created invoice.


By following these steps, you can automate the process of creating invoices in Stripe using data from the Fake Store API.

You can verify the result of your work by using the link to the invoice from the response after its creation, or by checking the invoice in the dashboard of your Stripe account. The generated invoice should contain the correct customer and product information. If you see the correct values, you are awesome!

The described business logic is functional but may contain unoptimized or redundant steps. Improvements and simplifications to the logic are welcome but not mandatory.

In the business logic for this test assignment, it is not mandatory to implement error handling or the logic for searching and using already existing entities such as Customer, etc.

### Requirements

* Create a custom library for working with `FakeStoreAPI` using the `faraday` gem (place it in the
`app/lib/fakestoreapi_service` directory).
* Use the `stripe` gem for working with Stripe. You need to add this gem to Gemfile manually.
* Log all requests to both services using the system logger `Application.logger`.
* Ensure that all code passes linting with `rubocop` without errors or warnings. Reasonable exceptions can be added to the
rubocop configuration.
* You need to implement a test for the `call` method using the `rspec` and `VCR` gems. VCR should record the network requests to both services. Ensure that the real API key is not included in the recorded cassettes. (You need to configure VCR yourself.)
* Optional: Achieve 100% test coverage.

### Submission Instructions

1. **Fork the repository**: Create a fork of this repository to your GitHub account.
2. **Create a new branch**: In your forked repository, create a new branch for your work.
3. **Make small commits**: As you work on the assignment, make small, incremental commits to your branch.
4. **Complete your work**: Once you have completed the assignment, ensure all your changes are committed and pushed to your branch.
5. **Submit the link**: Submit the link to your forked repository as your solution to the assignment.
