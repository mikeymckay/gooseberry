Command to restart:

cat /var/www/gooseberry-tusome/tmp/pids/unicorn.pid  | xargs kill; unicorn -c unicorn.rb -D
