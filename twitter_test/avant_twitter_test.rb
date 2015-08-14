require 'tweetstream'
require 'pqueue'
require 'yaml'

class AvantTwitterTest
  def initialize
    @stop_words = YAML::load_file('stop_words.yml')[:words]
    TweetStream.configure do |config|
      config.consumer_key       = 'ow2VF0I00XiFsDam1mB00ZMzq'
      config.consumer_secret    = 'HfBlItsNTiwlIsD1Beo8Ep3LurgdldVTV8RUUgJF7AbAKFGhrj'
      config.oauth_token        = '2320082814-gAEbIB3tqa3JeZnwxVoeJGFXcJkMn3nWZukr74L'
      config.oauth_token_secret = 'lwgtjVB80b4inWDYu0aVn4tDcx8Ld7DR31NkLobd2CoFC'
      config.auth_method        = :oauth
    end 
  end

  # Gets an array of the most common words from tweets over a given time interval
  #
  # ==== Parameters
  #
  # * +limit+ - the number of words to get
  # * +interval+ - The time interval to collect tweets over (in minutes)
  def get_most_common_words_from_tweets_over_interval(limit, interval)
    puts "gathering tweets..."
    words = collect_words_from_tweets_over_interval(interval)
    puts "calculating most used words..."
    return get_most_common_words(limit, words)
  end
  
  # Gets an array of the most words in the given hash of words => count
  #
  # ==== Parameters
  #
  # * +limit+ - the number of words to get
  # * +words_hash+ - a hash of words associated with their count
  def get_most_common_words(limit, words_hash)
    pq = PQueue.new(words_hash.to_a) { |a, b| a[1] > b[1] }

    ret = Array.new
    limit.times do
      ret.push pq.pop
    end

    return ret
  end
  
  # Collects tweets from the twitter streaming API over the course of the interval
  #   and stores the count of each word in a hash, which it returns
  #
  # ==== Parameters
  #
  # * +interval+ - the time interval (integer number of minutes)
  def collect_words_from_tweets_over_interval(interval)
    word_freq_hash = Hash.new
    word_freq_hash.default = 0
    
    EM.run do
      client = TweetStream::Client.new
      client.sample(language: "en") do |status|
        status.text.split.each do |word|
          word_freq_hash[word] += 1 unless @stop_words.include? word.downcase
        end
      end

      EM::PeriodicTimer.new(interval * 60) do
        client.stop
      end
    end

    return word_freq_hash
  end
end
