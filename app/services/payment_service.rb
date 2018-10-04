module PaymentService

  extend ActionView::Helpers::NumberHelper

  def self.create order, return_url, cancel_url
    payment = PayPal::SDK::REST::Payment.new({
      intent: "sale",
      payer: { payment_method: "paypal" },
      redirect_urls: { return_url: return_url, cancel_url: cancel_url },
      transactions: [
        get_item_list(order)
      ]
    })
    payment.create

    payment
  end

  def self.execute_payment(payment_id:, payer_id:)
    payment = PayPal::SDK::REST::Payment.find(payment_id)
    payment.execute(payer_id: payer_id) unless payment.error

    payment
  end

  private

  def self.get_item_list order
    {
      item_list: {
        items: [
          {
            name: order.name,
            price: number_with_precision(order.price, precision: 2),
            currency: order.currency,
            quantity: order.quantity
          }
        ]
      },
      amount: {
        total: number_with_precision(order.price*order.quantity, precision: 2),
        currency: order.currency,
        description: "Monthly payment for Pokrex"
      }
    }
  end
  private_class_method :get_item_list

end
