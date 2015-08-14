## Twitter Test Challenge

To see the top ten words in the past five minutes on the twitter stream, just run

    bundle exec rspec

Optional Part B. Although I did not implement this functionality, if I did I would use ruby's `rescue SystemExit, Interrupt` to trigger code that would dump the current results and time into a YAML file. Then, on initialization of the class, or with some other user facing method, this YAML dump could be loaded back into memory.

This implementation uses both the TweetStream gem and the pqueue gem. The tweetstream gem provides a ruby interface for the twitter streaming api, and the pqueue gem was used to sort out the top 10 words efficiently
