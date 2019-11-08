## All done!

[Generate a token](https://cloud.digitalocean.com/account/api/tokens/new)
with read and write access, and name it anything you like.

Save the token string somewhere safe, it won't be displayed again!

Let's authenticate with your account. Run `doctl auth init`{{execute}}, and
paste in the token string when prompted.

Great!

Let's spin up an empty Kubernetes cluster to work with:

`doctl kubernetes cluster create mycluster --region sfo2`{{execute}}

As you'll see in the terminal output this also automatically configured
`kubectl` to connect with that cluster. Easy enough!

TODO: STUFF WITH YOUR CLUSTER
