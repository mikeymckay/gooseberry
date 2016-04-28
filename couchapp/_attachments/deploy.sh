echo "Deploying for $1"
echo "Browserifying and uglifying bundle.js"
browserify --verbose -t coffeeify --extension='.coffee' Gooseberry.coffee | uglifyjs > bundle.js
sed 's~http://localhost:5984~'"$1"'~g' -i bundle.js
couchapp push --no-atomic $1
