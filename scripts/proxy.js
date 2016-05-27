var http = require('http'),
    connect = require('connect'),
    compression = require('compression'),
    morgan = require('morgan'),
    httpProxy = require('http-proxy');

var port = 8012;

var proxy = httpProxy.createProxyServer({
  target: 'http://localhost:5984/'
});

var app = connect();

// Log the requests, useful for debugging
app.use(morgan('combined'));

app.use(compression());
app.use(
  function(req, res) {
    proxy.web(req, res);
  }
).listen(port);

console.log('proxy  started  on port ' +  port);
