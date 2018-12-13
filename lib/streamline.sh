#!/bin/bash          

sass sass/materialize.scss > ../public/css/materialize.css

cd ../public/js/
cat jquery-3.3.1.min.js materialize.js > main.js
# java -jar ../../lib/yui.jar --type js all.js > main.js

cd ../css/
cat materialize.css style.css > all.css
java -jar ../../lib/yui.jar --type css ./all.css > ./main.css

echo "css updated on `date`"


