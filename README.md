# Engine Room Log

A logging application to help measuring and keeping the daily round
records for Greenpeace ships' engine departments.

### General information

Its server side is written with sinatra (ruby), with jQuery on the client side and
materialize as css framework. To evade complex forms and web interfaces, the
system mainly relies on handling .csv files and .xlsx sheets.

The system has no database connection. Daily data is saved as .json files,
as well as appended to the engine\_log.csv file to prevent acidentally removing intact
records. **Retrieval code not implemented yet.** 

### Admin access

Admin access is regulated over client computer's IP address. If granted, it
appears on the top menu and allows the user to manipulate or export the data -
everything other than collecting the daily measurements.

To grant it to a machine, simply edit to the regex string (separated by pipe '|') and restart the application. Search for "def access" in the `web.rb` file. Currently the ChEng's computer (.199), RR3 (.181) and WTS (.25) have access. 

### Setting up local development environment

It's pretty easy for this project for it does not rely on any native libraries.
Just install a secure version of ruby (preferably with rbenv or rvm) and run
`bundle` in the root folder (`gem install bundler` if it fails). To run
the local server, run `ruby web.rb` and for interactive console, just `tux`.

## TODO

Visualization of collected data is a great feature, hope to get it done after some more data have been collected.

Cheers!

Yakup - ycetinka@greenpeace.org

