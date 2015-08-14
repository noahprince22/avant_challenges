require_relative '../avant_twitter_test'

describe ("AvantTwitterTest") do
  it ("can get the most common words from a words_hash") do
    words_hash = {
      "a" => 5,
      "b" => 2,
      "c" => 7,
      "d" => 8,
      "e" => 10,
      "f" => 1,
      "g" => 12,
      "h" => 4,
      "i" => 3,
      "j" => 20
    }
    result = AvantTwitterTest.new.get_most_common_words(3, words_hash)

    expect(result[0][0]).to eq("j")
    expect(result[1][0]).to eq("g")
    expect(result[2][0]).to eq("e")
  end

  # Note that we can't really test what it's going to pull, and mocking out
  #   the TweetStream client would be overkill for this project
  it ("can extract the most common words from tweets") do
    result = AvantTwitterTest.new.get_most_common_words_from_tweets_over_interval(10, 5)

    result.each_with_index do |result, index|
      puts "#{index + 1}: #{result[0]}"
    end
    
    expect(result.size).to eq(10)
  end
end
