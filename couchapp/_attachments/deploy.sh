#!/bin/bash
echo "Deploying gooseberry design_docs and views to $1/gooseberry"
echo "Browserifying and uglifying bundle.js"
./node_modules/browserify/bin/cmd.js -t coffeeify --extension='.coffee' Gooseberry.coffee | ./node_modules/uglifyjs/bin/uglifyjs > bundle.js
#exit
sed 's~http://localhost:5984~'"$1"'~g' -i bundle.js
sed 's~http://localhost:8012~'"$1"'~g' -i bundle.js
sed 's~http://localhost:9393~'"$1"'~g' -i bundle.js
couchapp push --no-atomic $1/gooseberry
echo "Pushing views to $1/gooseberry"
cd ../../__views
./pushViews.rb $1 gooseberry
echo 'Executing views, takes a while on first run'
coffee executeViews.coffee $1/gooseberry
