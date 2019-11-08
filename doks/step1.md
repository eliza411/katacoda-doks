## Let the setup finish!

We're setting up the environment with `doctl`, the command-line interface
for DigitalOcean accounts, and `kubectl`, the command-line interface for
Kubernetes.

When you see the terminal read `ALL DONE! CONTINUE...`, you're ready to
start running some commands!

## All done!

[Generate a token](https://cloud.digitalocean.com/account/api/tokens/new)
with read and write access, and name it anything you like.

Save the token string somewhere safe, it won't be displayed again!

Let's authenticate `doctl` with your account using that token. Paste in the
token string when prompted.

```
doctl auth init
```{{execute}}

Great!

Now let's spin up an empty Kubernetes cluster to work with:

```
doctl kubernetes cluster create mycluster --region sfo2
```{{execute}}

As you'll see in the terminal output this also automatically configured
`kubectl` to connect with that cluster. Easy enough!

> Yep, at this point, you can run arbitrary kubectl commands and they'll
> deploy on DOKS. Easy as pie.
