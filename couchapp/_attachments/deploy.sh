echo "Deploying for $1"
echo "Browserifying and uglifying bundle.js"
./node_modules/browserify/bin/cmd.js --verbose -t coffeeify --extension='.coffee' Gooseberry.coffee | ./node_modules/uglifyjs/bin/uglifyjs > bundle.js
sed 's~http://localhost:5984/gooseberry~'"$1"'~g' -i bundle.js
couchapp push --no-atomic $1
