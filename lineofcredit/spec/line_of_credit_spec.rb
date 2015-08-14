require_relative '../line_of_credit'
require 'delorean'

RSpec.configure do |config|
  config.include Delorean
end

class Fixnum
  SECONDS_IN_DAY = 24 * 60 * 60

  def days
    self * SECONDS_IN_DAY
  end

  def ago
    Time.now - self
  end
end

def calculate_interest(amount, apr, days)
  return ((amount * apr)/(365)) * days
end

describe LineOfCredit, '#draw' do
  before(:each) do
    time_travel_to 30.days.ago
    @credit_total = 1000
    @apr = 0.35

    @credit = LineOfCredit.new(@credit_total, @apr)
  end

  after(:each) { back_to_the_present } 

  it ("does not accept negative draws")  do
    expect { @credit.draw(-0.5) }.to raise_error
  end

  it ("does not accept over draws") do
    expect { @credit.draw(@credit_total + 0.01) }.to raise_error
  end

  context "single draw" do
    before(:each) do
      @credit.draw @credit_total
    end

    it ("updates the remaining credit") do
      jump 1.days
      expect(@credit.remaining_credit).to(eq(0))
    end

    it ("updates the remaining balance") do
      jump 1.days
      expect(@credit.balance).to(eq(@credit_total))
    end

    it ("appropriately adds interest after 30 days and resets") do
      jump 30.days
      
       # Must call close_payment_period because Delorian does not affect thread sleeping
      @credit.close_payment_period

      total_payoff = @credit_total + calculate_interest(@credit_total, @apr, 30)
      expect(@credit.total_payoff).to(eq(total_payoff))

      # Check that the credit limit reset
      @credit.draw 20
      expect(@credit.total_payoff).to(eq(total_payoff+20))
    end

    it ("compounds only on principle") do
      jump 30.days
      
       # Must call close_payment_period because Delorian does not affect thread sleeping
      @credit.close_payment_period
      
      total_payoff = @credit_total + calculate_interest(@credit_total, @apr, 30)

      jump 30.days
      @credit.close_payment_period
      total_payoff += calculate_interest(@credit_total, @apr, 30)
    end
  end

  context "multiple draw" do
    before(:each) do
      @draw1 = 200
      @draw1_days = 5
      
      @draw2 = 300
      @draw2_days = 10
      
      @draw3 = 100.25
      @draw3_days = 15

      @credit.draw @draw1
      jump @draw1_days.days

      @credit.draw @draw2
      jump @draw2_days.days

      @credit.draw @draw3
      jump @draw3_days.days
    end

    it ("updates the remaining credit") do
      expect(@credit.remaining_credit).to(eq(@credit_total - @draw1 - @draw2 - @draw3))
    end

    it ("updates the remaining balance") do
      expect(@credit.balance).to(eq(@draw1 + @draw2 + @draw3))
    end

    it ("appropriately adds interest after 30 days and resets") do
      jump (30 - @draw3_days - @draw2_days - @draw1_days).days

      # Must call close_payment_period because Delorian does not affect thread sleeping
      @credit.close_payment_period

      interest1 = calculate_interest(@draw1, @apr, @draw1_days)
      interest2 = calculate_interest(@draw1+@draw2, @apr, @draw2_days)
      interest3 = calculate_interest(@draw1+@draw2+@draw3, @apr, @draw3_days)

      total_balance = @draw1+@draw2+@draw3 + interest1+interest2+interest3
      expect(@credit.total_payoff).to(eq(total_balance))
    end
  end
end

describe LineOfCredit, '#pay' do
  before(:each) do
    @credit_total = 1000
    @apr = 0.35

    time_travel_to 30.days.ago
    @credit = LineOfCredit.new(@credit_total, @apr)
  end

  after(:each) { back_to_the_present } 

  it ("cannot pay over the balance") do
    expect { @credit.pay(20) }.to raise_error
  end

  it ("only accepts postive payments") do
    expect { @credit.pay(-20) }.to raise_error
  end

  context "multiple payments" do
    before(:each) do
      @draw1 = 200
      @draw1_days = 5

      @pay1 = 200
      @pay1_days = 5
      
      @draw2 = 300
      @draw2_days = 10
      
      @pay2 = 200
      @pay2_days = 5
      
      @credit.draw @draw1
      jump @draw1_days.days

      @credit.pay @pay1
      jump @pay1_days.days

      @credit.draw @draw2
      jump @draw2_days.days

      @credit.pay @pay2
      jump @pay2_days.days
    end

    it ("updates the does not change the remaining credit") do
      expect(@credit.remaining_credit).to(eq(@credit_total - @draw1 - @draw2))
    end

    it ("updates the remaining balance") do
      expect(@credit.balance).to(eq(@draw1 + @draw2  - @pay1 - @pay2))
    end

    it ("appropriately adds interest after 30 days") do
      # Jump to the end of the month
      jump (31-@pay2_days-@pay1_days-@draw1_days-@draw2_days).days

      # Must call close_payment_period because Delorian does not affect thread sleeping
      @credit.close_payment_period

      interest1 = calculate_interest(@draw1, @apr, @draw1_days)
      interest2 = calculate_interest(@draw1-@pay1, @apr, @pay1_days)
      interest3 = calculate_interest(@draw1-@pay1+@draw2, @apr, @draw2_days)
      interest4 = calculate_interest(@draw1-@pay1+@draw2-@pay2, @apr, 30 - @pay1_days - @draw1_days - @draw2_days)

      total_principle = @draw1-@pay1+@draw2-@pay2
      total_payoff = total_principle + interest1+interest2+interest3+interest4
      expect(@credit.total_payoff).to(eq(total_payoff))
    end
  end
end
