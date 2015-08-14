## line of credit challenge

#### Implementation

The implementation of the challenge is in `line_of_credit.rb`

The interface is as follows:

To create a new line of credit for $1000 at 35% apr:

    credit = LineOfCredit.new(1000, 0.35)

To draw $50 on that credit:

    credit.draw(50)

To pay $50 on the credit:

    credit.pay(50) # Payments will first subtract from interest, then from balance

To get information about the line of credit:

    credit.remaining_credit # The remaining credit limit
    credit.balance # The principle balance
    credit.interest # The total interest accrued that hasn't been paid
    credit.total_payoff # The total amount that needs to be paid, principle = interest
    
#### Testing

The rspec test contains my interpretation of the challenge interface.

While it's not holistic, it covers enough test cases to ensure that the class is functioning as intended. It will also serve to show the expected use and my interpretation of the problem. To run these tests, simply run

    bundle exec rspec


Note that this interface, once created, kicks off a thread that runs once a month. When the garbage collector comes for this instance, the thread is properly killed. This thread functionality cannot be tested with rspec, so close_payment_period must be called manually

The tests depend on the Delorian gem, which allows the tests to, with some limitations, mimic the user interacting over the course of several days.
