#### Engine Room Logbook

<br/>

###### <span style="font-weight: normal;">A logging application for measuring and keeping the daily records for Greenpeace ships' engine departments.</span>

<br/>

##### General information

Its server side code is written with Sinatra (Ruby), with jQuery on the client side and
Materialize as CSS framework. To evade complex forms and web interfaces, the
system mainly relies on handling **.CSV** files and **.XLSX** sheets.

The system has no database connection. Daily data is saved as .json files,
as well as appended to the engine\_log.csv file to prevent acidentally removing intact
records. **Retrieval code not implemented yet.** 

<br/>

##### Setting up local development environment

It's pretty easy for this project for it does not rely on any native libraries.
Just install a secure version of ruby (preferably with rbenv or rvm) and run
`bundle` in the root folder (`gem install bundler` if it fails). To run
the local server, run `ruby web.rb` and for interactive console, just `tux`.

<br/>

##### Features

###### Data retention

The measurements taken will be stored locally on the tablet until they are sent
to server or intentionally cleared. In case of connection problems or device
failure (dead battery) it will still be possible to continue from the point
where you left.

###### Back reference

It is possible to go back to any date and load the values entered by a specific
time.

###### Visualisation

On the Dashboard (<i class="material-icons" style="display:inline-flex;vertical-align:bottom">insert_chart</i>)
page you can select multiple measurements and see their trends over the history.

<br/>

##### Admin access

Admin access is regulated over client computer's IP address. If granted, it
appears on the top menu and allows the user to manipulate or export the data -
everything other than collecting the daily measurements.
<br/><br/>

To grant it to a machine, simply edit to the regex string (separated by pipe '|')
and restart the application. Search for "def access" in the `web.rb` file. 
Currently the ChEng's computer (.199), RR3 (.181) and WTS (.25) have access 
on Esperanza Shipnet. 
<br/><br/>

Once in the Admin page, you can access and update the structure and the
representation of the application. There are 6 functions:

- **Download log sheet:**
Download the values for printing. The page arrangement is read from the
current Layout template. You can pick a date from the interface, only dates
with valid data are selectable.
<br/><br/>

- **Edit previous records:**
Older data can be restored to the application using the date picker. The form
can be cleared by clicking the "Clear current form" link, be warned though that
all the information will be lost unless it was submitted to the server before.
<br/><br/>

- **Layout:**
Download the layout template by date, and upload new one. More information
below.
<br/><br/>

- **Mapping:**
Download the structure file by date, and upload new one. More information
below.
<br/><br/>

- **Lubrication info:**
Download the lubrication file by date, and upload new one. More information
below.
<br/><br/>

- **Download logging history:**
Download all the measurements taken since the beginning, in a large .CSV file.
Not intended for the end user though.
<br/><br/>

##### Editing the systems structure

A mapping file with .CSV format is used to define the structure of the systems.
They are organized in a hierarchical tree, consisting of 3 layers:

1. Room
  1. System
  <ol><li>Measurement</li><li>Measurement</li></ol>
  2. System
  <ol><li>Measurement</li></ol>
2. Room
  1. System
  <ol><li>Measurement</li><li>...</li></ol>
  2. ...
3. ...

###### File structure

The CSV file contains 11 columns:

- **Required:**
  <br/><br/>

  - **ID:** The unique identifier of the measurement, to be used as reference on
    the *Layout Sheet*. Collision of this values (same ID on multiple
    measurements, or rows) will lead to errors on retrieving the data sheets.
  <br/><br/>

  - **Room:** The system is organized by rooms as the first hierarchical unit. It
    should be designed considering the trajectory of the daily rounds, where the
    duty engineer goes earlier, should come first on the CSV file. More on ordering below.
  <br/><br/>

  - **System:** It can be a machine, a distribued network of devices, or a
    concept that would help to group some *measurements* together. A system may
    occur in multiple rooms, if this is more convenient to get the values.
  <br/><br/>

  - **Measurement:** This is the main unit of the structure. Please take care
    to name it uniquely for each system. For example, if `System A` has a
    `Measurement` called `Gas Pressure`, it is OK for `System B` to have the
    same `Measurement` as long as the `ID` column has a different value. It
    should be avoided, for the sake of clarity, to give multiple Measurements
    under the same system the same name.
  <br/><br/>

  - **Unit:** This is an important piece of data that defines how the
    measurement will be represented on the form. More on units below.
  <br/><br/>

- **Optional:**
  <br/><br/>

  - **Min, Max, Opt:** Minimum, maximum and default values for the measurement.
    Please note that `Min` and `Max` define the possible range, not the convenient
    range. `Opt`, as the default value, will be used on some form elements like
    sliders to make it easier for the duty engineer.
  <br/><br/>

  - **Notes:** Obviously, some explanation on the measurement or its
    attributes. Not parsed by the system.
  <br/><br/>

  - **Data:** Some unit types utilize this column to work correctly. More
    on units below.
  <br/><br/>

  - **Port:** Indicates if the measurement should be shown on a round done
    while alongside. if the value is "1" it will, otherwise it won't.

###### Ordering of measurements

The file is read by the system row by row, honoring the order of precedence, meaning
that if a Room is listed earlier than the other, the first one will precede the
latter on the application.
<br/> <br/>

Same for the Systems that appear on one Room or another, or Measurements inside
Systems.

<br/>

###### Units

The Units column (#5 on the CSV file) is programmed to recognize special types,
which include:

- **scale:** Shows a slider instead of a standard number input. Min and Max
  default to 0 and 10, and Data column could be used to indicate step size.
  Step defaults to 1.
<br/><br/>

- **enum:** Short for "Enumerated list", creates a dropdown box for multiple
  selection. On the Data column, opssible options should be entered with a unix
  pipe symbol (|) as delimiter. For example, "SB|PS" is a valid value.
  If no value is given on the Data column, the numbers on Min and Max columns
  will be used. Make sure that a hash sign (#) is used at the Measurement name,
  for it will be replaced with the corresponding number on the dropdown box.
<br/><br/>

- **binary:** Indicates a switch input, default valus are "on" and "off".
  Again, a pipe-delimited value can be entered to the Data column to change the
  values, like "yes|no".
<br/><br/>

- **trinary:** A three-option checkbox for indicating L,M,H (Low, Medium, High) 
  values mainly for vaguely readable level and temperature gauges. Does not yet
  utilize the Data column for alternative values.

The rest of the units are arbitrary, yet there is a hard-coded setting to make
some of them more precise. Normally all the units have a precision of 0.1, but
the following have 0.01: 
**cube, bar, cm, C**
<br/><br/>

Other units that have been used so far include:
**A, cc/min, deg, Hz, kW, l, l/min, mV, percent, ppm, rpm, μs/cm**
<br/><br/>

###### Further remarks

- Please do not change the order of columns for it is critical for the
  system to work correctly. 
  <br/><br/>

- The first row of the CSV file is spared as header, listing the titles for each
  column. Please note that if there's data for a Measurement, it will be omitted.
  <br/><br/>

- Needles to say, make sure that the rows or columns don't get shifted while
  editing the document. A case is observed when using the "paste copied values as
  new row" option of MS Excel, only the copied 5 columns were shifted down,
  so the data got broken and the representation on the application was faulty.

<br/><br/>


##### The Layout file

The layout file is a .XLSX document, used as a template for outputting daily
values to be printed and stored in the physical folder.
<br/><br/>

It is a normal Excel sheet, and all its functions can be used normally; like
print properties, formulas, styles and so on. Macros are not tested and wouldn't
be necessary but should be working fine as well.
<br/><br/>

The only trick on this file is that the Measurement values are represented by their 
"ID" numbers, as entered in the Mapping file, preceded by a Dollar sign ($).
Thus, the cell type becomes "string".
<br/><br/>

As an example, a Measurement indicated with an id of 12 will be represented on
the layout file as "$12". Simple stuff.
<br/><br/>

If the system encounters a cell with value starting with "$", it will register
it to change with the corresponding measurement's value. If there's no value
for that Measurement for that day, a dash (-) will be put there.
<br/><br/>

###### Special cases

There are 2 cases for which the above convention can be extended:

- **Yesterday's values:** If you put a lowercase "y" between the dollar sign
  and yhe ID number, the system will try to take the value for the same
  Measurement from the day before. Useful for calculating consumption or
  production, in an additional cell with the help of a formula. Will look like
  "$y12".
  <br/><br/>

- **Lubrication:** The variables "$lu", "$lt" and "$la" will be parsed by the
  system to enter information about lubrication.
  These variables should be on the same row to work correctly. They can be
  repeated to allow multiple rows.
    - **$lu:** Lubricated unit, the machine in this case.
    - **$lt:** Lubrication oil type.
    - **$la:** Amount of oil used, in liters.
  <br/><br/>

- **Other information:** There are a couple of standard variables needed for
  each day's rounds:
  - **$date:** Date of the day the Measurements are taken.
  - **$user:** Name of the duty engineer who took the measurements.
  - **$from_port:** Indicates last called or current port.
  - **$to_port:** Next port in schedule. Can be omitted if already in port.
  - **$notes:** Notes and remarks taken during the round, aggrgated by the
    room order.

Sice the output will be downloaded as an .XSLX file, every value can be edited
before print.
<br/><br/>

##### The Lubrication file

There is one more file to be considered if you want to enter lubrication
information. It's a .CSV file with 3 columns: Room, System, Default oil.

If a room is indicated in that file, a Lubrication box will be appended to the
end of the list in that room's page, before the Notes section, that will allow
to add lubrication information.

When the plus button in the box is clicked, a dialog will appear. It has 3
fields to be filled:

- **Unit:** The system to be lubricated. Only options are the systems mentioned
  in the Lubrication file for that room.

- **Type of oil:** Type of oil used for lubrication of the unit selected above.
  Note that once the unit is selected, this field will change to match the
  default type of oil enteredd in the lubrication file. Other options are
  compiled from the file, but mostly not necessary.

- **Amount in liters:** Self explanatory.

Once the "ADD LUBRICATION" button is clicked, the dialoge is closed and the
entered information is appended to a table in the Lube box. To delete the info,
please click on the red trash icon 
(<i class="material-icons" style="display:inline-flex;vertical-align:bottom">delete</i>).
<br/><br/>

The remarks for the Mapping CSV file also apply to this file.
<br/><br/>

##### Conclusion

The codebase for this project is at:
<https://github.com/greenpeace/ecr_logbook>

Please contact me at *ycetinka [at] greenpeace [dot] org* for issues.
<br/><br/>

*This document was created by Yakup Çetinkaya on January 2020, o/b MY Esperanza, in Antarctica.*
<br/><br/>

