require 'pry'

class LineOfCredit
  attr_reader :remaining_credit, :balance, :interest, :apr
  
  def initialize(credit, apr)
    @total_credit = credit
    @remaining_credit = credit
    @apr = apr
    @balance = 0
    @interest = 0

    @ledger = Array.new

    @payment_period_start = Time.now
    
    monthly_update_thread = Thread.new {
      sleep(1.months)

      close_payment_period
    }

    # Stop the thread when garbage collected
    ObjectSpace.define_finalizer(self, proc { monthly_update_thread.exit }) 
  end

  # Pays a given amount from this line of credit
  #
  # ==== Attributes
  #
  # * +amount+ - The amount to pay for this line of credit
  #                  must be greater than 0 and less than or equal to the payoff
  def pay(amount)
    raise "Cannot pay a negative amount" if amount < 0
    raise "Cannot pay more than the current total payoff" if amount > total_payoff
    
    @balance = @balance - amount
    
    @ledger.push({
      amount: -amount,
      time: Time.now
    })
  end


  # Draws a given amount from this line of credit
  #
  # ==== Attributes
  #
  # * +amount+ - The amount to draw from this line of credit.
  #                  must be greater than 0 and less than or equal to
  #                  the remaining credit
  def draw(amount)
    raise "Cannot draw more than the remaining credit" if amount > remaining_credit
    raise "Cannot draw a negative amount" if amount < 0
    
    @balance = @balance + amount

    @ledger.push({
      amount: amount,
      time: Time.now
    })

    @remaining_credit = @remaining_credit - amount
  end

  # The principle balance totaled with the acrued interest
  def total_payoff
    return @balance + @interest
  end


  # Adds the interest for the payment period and closes the ledger for this period
  #   THIS IS NOT A PUBLIC METHOD, executes on a monthly basis
  #   Will only execute at the end of a 30 day period
  def close_payment_period
    if days_between(Time.now, @payment_period_start) >= 30
      
      aggregated_balance = 0
      aggregated_interest = 0
      @ledger.each_with_index do |item, index|
        if index == (@ledger.size - 1)
          next_item_time = @payment_period_start + 30.days
        else
          next_item_time = @ledger.at(index+1)[:time]
        end
        
        days_to_next_item = days_between(item[:time], next_item_time)
        
        aggregated_balance += item[:amount]
        aggregated_interest += calculate_interest(aggregated_balance,
                                                  days_to_next_item)
      end
      
      # Leave a single entry in the ledger with the rollover for this month
      # Note that this implementation just whipes the ledger to save on memory
      #   and increase performance. Depending on the project requirements, old
      #   data could be dumped into a yaml file
      @ledger = Array.new
      @ledger.push({
                amount: aggregated_balance,
                time: Time.now
              })
      
      @payment_period_start = Time.now
      @remaining_credit = @total_credit
      @interest += aggregated_interest
    end    
  end

  def calculate_interest(amount, days)
    return ((amount * @apr)/(365)) * days
  end

  def days_between(t1, t2)
    return ((t1 - t2).to_i / (24 * 60 * 60)).abs
  end
end

