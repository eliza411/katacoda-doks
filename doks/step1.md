## Connect to your DigitalOcean Account

1. [Sign up for a DigitalOcean account](https://cloud.digitalocean.com/registrations/new)
2. [Add a payment method](https://cloud.digitalocean.com/account/billing)
3. [Generate a token](https://cloud.digitalocean.com/account/api/tokens/new)
with read and write access, and name it anything you like.

Save the token string somewhere safe, it won't be displayed again!

Let's authenticate `doctl` with your account using that token. Paste in the
token string when prompted.

`doctl auth init`{{execute}}

Great!

Now let's spin up an empty Kubernetes cluster to work with:

`doctl kubernetes cluster create mycluster --region sfo2`{{execute}}

As you'll see in the terminal output this also automatically configured
`kubectl` to connect with that cluster. Easy enough!

> Yep, at this point, you can run arbitrary kubectl commands and they'll
> deploy on DOKS. Easy as pie.

## New File Open

`newFile2.js`{{open}}

<pre class="file" data-filename="newFile2.js" data-target="replace">var http = require('http');
var requestListener = function (req, res) {
  res.writeHead(200);
  res.end('Hello, World!');
}

var server = http.createServer(requestListener);
server.listen(3000, function() { console.log("Listening on port 3000")});
</pre>{{open}}
