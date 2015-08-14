##twitter test challenge

To see the top ten words in the past five minutes on the twitter stream, just run

    bundle exec rspec

Optional Part B. Although I did not implement this functionality, if I did I would use ruby's `rescue SystemExit, Interrupt` to trigger code that would dump the current results and time into a YAML file. Then, on initialization of the class, or with some other user facing method, this YAML dump could be loaded back into memory. 
