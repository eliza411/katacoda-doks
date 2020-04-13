In this module, we're going to create a small app, build it as a portable
artifact called an *image*, and securely run it in an environment called a
cluster. We'll be using the DigitalOcean Kubernetes platform to do this, which
manages away a lot of complexity for us. But first, you'll need to have a
DigitalOcean account at the ready.

## Step 1: Authenticate this Environment with Your DigitalOcean Account

1. [Sign up for a DigitalOcean account](https://cloud.digitalocean.com/registrations/new)
2. [Generate a token](https://cloud.digitalocean.com/account/api/tokens/new)
with read and write access, and name it anything you like.

*Save the token string somewhere safe, it won't be displayed again!*

Let's authenticate `doctl` using that token. Paste it in when prompted:

`doctl auth init`{{execute}}

## Step 2: Build a Simple Python App

This app just reports its hostname to the screen, and tries to connect to a
visitor counter, reporting that it can't if one isn't running. (It won't be,
yet!)

#### Create app.py

Click this link to **create `app.py`{{open}}**

Now click the **Copy to Editor** to slot in our source code to `app.py`:

<pre class="file" data-filename="app.py" data-target="replace">

from flask import Flask
from redis import Redis, RedisError
import os
import socket

redis = Redis(host="redis", db=0, socket_connect_timeout=2, socket_timeout=2)

app = Flask(__name__)

@app.route("/")
def hello():
    try:
        visits = redis.incr("counter")
    except RedisError:
        visits = "<i>cannot connect to Redis, counter disabled</i>"

    html = "<h3>Hello {name}!</h3>" \
           "<b>Hostname:</b> {hostname}<br/>" \
           "<b>Visits:</b> {visits}"
    return html.format(name=os.getenv("NAME", "world"), hostname=socket.gethostname(), visits=visits)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80)

</pre>

As you can see, it's depending on the Python libraries for Flask and Redis. The way we express that dependency in Python is usually with a text file.

Everything you do in this file is automatically saved, so let's move on.

#### Create requirements.txt

Click this link to **create `requirements.txt`{{open}}**.

And click **Copy to Editor** to express our requirements in our new file.

<pre class="file" data-filename="requirements.txt" data-target="replace">
Flask
Redis
</pre>

## Step 3: Build a Docker Image

To deploy this in the old days, you'd run `pip` to install your requirements and
get your environment just so, then make sure you had a Python runtime that was
compatible with your code. But that creates a reproducibility problem. "It works
on my machine," you might say as you provide this code to someone who doesn't
have the same environment as you.

But, if we define the environment we need to run this code in a `Dockerfile`, we
can create an image, which is a build of not only our code, but the runtime and
the dependencies our code needs to run anywhere. That way when we deploy, the
code and everything it needs to run all travels together. The reproducibility
problem is thus solved!

#### Create Dockerfile

Click this link to **create a `Dockerfile`{{open}}**.

And click **Copy to Editor** to slot in the following code:

<pre class="file" data-filename="Dockerfile" data-target="replace">
# Use an official Python runtime as a parent image
FROM python:slim

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
ADD . /app

# Install any needed packages specified in requirements.txt
RUN pip install -r requirements.txt

# Make port 80 available to the world outside this container
EXPOSE 80

# Define environment variable
ENV NAME World

# Run app.py when the container launches
CMD ["python", "app.py"]
</pre>

It doesn’t seem like you’ve really set up an environment with Python and Flask
pre-installed, defined an environment variable it needs, and defined the command
that runs your app, but with these seven commands, you have. The use of
container images enables this kind of environment composability. Now your app
will run anywhere.

Now click this command to create an image based on the `Dockerfile` you
defined. We're going to tag it with `-t` so it has a friendly name:

`docker build -t my-python-app .`{{execute}}

Where is your built image? It’s in your machine’s local image registry:

`docker images | grep my-python-app`{{execute}}

Let's run it and at long last see your application at work:

`docker run -p 80:80 my-python-app`{{execute}}

You should see a notice that Python is serving your app at port 80.

To see the output, click the plus sign (**+**) to the right and select **View
HTTP port 80 on Host 1**. Sure enough, our app prints out "Hello World," a
hostname provided by the Docker environment, and a message that it can't connect
to Redis. (After all, we haven't installed Redis itself, just the Python library
that connects to it.)

Try clicking this to run the app again:

`docker run -p 80:80 my-python-app`{{execute interrupt}}

 If you view the output again, you'll notice the hostname has changed. This
 tells us that every instance of our app is unique. In fact, the hostname is
 actually just the ID of the *container* -- the runtime instance of our
 image.

## Upload it

This is all well and good for your local environment, but the image we made is
sitting in our local registry. To run it in production, we'll need to upload the
image to a remote registry. DigitalOcean provides that very thing.

Since you've already authenticated this environment with your DigitalOcean
account in the beginning, you can create a registry now and log into it with
Docker. We're going to name your registry with the randomly-generated
`do-katacoda-[[KATACODA_HOST]]-[[HOST_SUBDOMAIN]]` because registry names have to be globally
unique.

`doctl registry create do-katacoda-[[KATACODA_HOST]]-[[HOST_SUBDOMAIN]]`{{execute interrupt}}

`doctl registry login`{{execute}}

> **Note**: This was your first authenticated action. If you encountered trouble, remember to [generate an API token in your DigitalOcean dashboard](https://cloud.digitalocean.com/account/api/tokens/new), and paste it into the terminal after running `doctl auth init`{{execute}}.

Now that you have a registry and Docker is authorized to use it, `tag` your local image with it's fully-qualified destination path, and send your local image on its way to your registry.

`docker tag my-python-app registry.digitalocean.com/do-katacoda-[[KATACODA_HOST]]-[[HOST_SUBDOMAIN]]/my-python-app`{{execute}}

`docker push registry.digitalocean.com/do-katacoda-[[KATACODA_HOST]]-[[HOST_SUBDOMAIN]]/my-python-app`{{execute}}

All uploaded! Now any machine on DigitalOcean that's run that same `doctl registry login` step can pull your image from the DigitalOcean registry in the cloud and create a running container with it, with no Python setup, no `pip` installation, or anything. The command is much the same as when you create a container locally, except now we use the DigitalOcean registry's version of the image.

`docker run -p 80:80 registry.digitalocean.com/do-katacoda-[[KATACODA_HOST]]-[[HOST_SUBDOMAIN]]/my-python-app`{{execute}}

## Create Your First Cluster

It's well and good to have a single machine `docker run` a container for you. But that just runs one container. And we haven't launched a container for Redis yet. And even if we did, then what? How do we connect a container running our app to a database running in another container? What if our app gets wildly popular and we need to run at scale? What if we know we are going to need more than one machine to have the right capacity? How do we start managing things like state, and secrets, at that point? What transforms what we've done with `docker run` into a true cloud application that load balances and auto-scales properly and behaves in a coordinated way?

To solve these problems, you will need an orchestrator -- an application that coordinates the scheduling of containers and manages their workloads, state, and secrets for you. And that's precisely what Kubernetes, the most popular and versatile orchestrator, can do. With Kubernetes, you can create a *cluster* of machines in the cloud, and run commands on them as though they were one machine, relying on Kubernetes to pack them hyper-efficiently with your container workloads.

Each virtual machine you add to a Kubernetes cluster is called a *node*, and operates as empty capacity for you to use with your containers.

DigitalOcean's Kubernetes product is a managed Kubernetes product that abstracts away a great deal of the complexity of Kubernetes for you. Let's create an empty Kubernetes cluster now on DigitalOcean and deploy our app on it.

`doctl kubernetes cluster create do-katacoda-[[KATACODA_HOST]]-[[HOST_SUBDOMAIN]] --tag do-katacoda --auto-upgrade=true --node-pool "name=mypool;count=2;auto-scale=true;min-nodes=1;max-nodes=3;tag=do-katacoda"`{{execute interrupt}}

This operation will take a long while, so while it's working, let's break this command up into it's parts so we can understand it:

- `doctl kubernetes cluster create do-katacoda-[[KATACODA_HOST]]-[[HOST_SUBDOMAIN]] --tag do-katacoda` tells DigitalOcean to create a cluster named `do-katacoda-[[KATACODA_HOST]]-[[HOST_SUBDOMAIN]]` for us, and `--tag` it as `do-katacoda`.
- `--auto-upgrade=true` tells DigitalOcean to automatically apply release patches to our cluster to protect the security and stability of our cluster.
- `--node-pool name=mypool;count=2;auto-scale=true;min-nodes=1;max-nodes=3;tag=do-katacoda` instructs DigitalOcean to initialize the cluster with a two-node group of virtual machines called a *node pool*, name it "mypool," tag the nodes `do-katacoda`, and allow the pool to automatically scale in size between one and three nodes (depending on the needed capacity).

> **Note**: Another thing `doctl` will do as part of the cluster creation process is automatically configure the Kubernetes command-line interface, `kubectl`, so that all `kubectl` commands are "pointed at" your new cluster. This is why all `kubectl` commands going forward in this tutorial are managing our specific cluster. You can have `doctl` set `kubectl`'s context this way again later if you need to by calling [`doctl`'s `save` command](https://www.digitalocean.com/docs/apis-clis/doctl/kubernetes/cluster/kubeconfig/save/).

You will know your cluster is ready when you finally get output that looks like this:

```
Notice: Cluster is provisioning, waiting for cluster to be running
......................................................
Notice: Cluster created, fetching credentials
Notice: Adding cluster credentials to kubeconfig file found in "/root/.kube/config"
Notice: Setting current-context to do-nyc1-*********
```

## Run Your App on a Cluster

Now we have capacity in the cloud to run our app in a real Kubernetes cluster, and `doctl` has automatically configured `kubectl` for us, so we can proceed to use `kubectl` to start managing our new cluster. The last thing for us to do is authorize our cluster's access to our private registry with the next two commands. The first command tells `doctl` to retrieve a description of the registry as a YAML *manifest* and pipes it directly to `kubectl`.

`doctl registry kubernetes-manifest | kubectl apply -f -`{{execute}}

Last time we used our private registry, we authenticated our local Docker installation, which stored the credentials for our registry on our local machine. This time, we are authenticating our Kubernetes cluster, which stores our registry credentials as a *secret* -- the built-in mechanism Kubernetes offers for securely storing sensitive data.

After running the previous command, you'll see that the secret was uploaded and given a name similar to your registry's name. Now we tell Kubernetes what that secret is for by specifying that the secret is to be used as an `imagePullSecret`. This means that we are instructing Kubernetes to use this secret as an authentication token when pulling our images from our private registry and creating containers:

`kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "registry-do-katacoda-[[KATACODA_HOST]]-[[HOST_SUBDOMAIN]]"}]}'`{{execute}}

Now let's show the power of DigitalOcean Kubernetes by using our two nodes of cluster capacity and running multiple instances of our application at once. To do that, we'll create a *Deployment* of our app, which is the object Kubernetes uses to maintain the desired state of our running containers. This will actually launch the app live in the cluster.

`kubectl create deployment my-python-app --image=registry.digitalocean.com/do-katacoda-[[KATACODA_HOST]]-[[HOST_SUBDOMAIN]]/my-python-app`{{execute}}

One aspect of the Deployment we created is its default *Replica Set*, which is the object Kubernetes uses to maintain a stable number of replicas of your container. Each replica is a separate running instance of your container called a *Pod*. So to recap that, you created a Deployment with no parameters and that means that Kubernetes assumes you just want to run one Pod in that Deployment's Replica Set. We can confirm that by running this command which lists all Replica Sets:

`kubectl get rs`{{execute}}

And see that our Replica Set is just running one Pod, i.e. one replica, i.e. one instance of our application:

`kubectl get pods`{{execute}}

But now, let's scale up to run 10 replicas:

`kubectl scale deployment/my-python-app --replicas=10`{{execute}}

Now when we call `kubectl get rs`{{execute}} and `kubectl get pods`{{execute}} we see a lot more excitement. In fact, you can repeatedly call `kubectl get pods`{{execute}} and watch the **Status** change as Kubernetes gets the 9 new Pods up and running.

Next, let's expose our Deployment to the world, so we're routing traffic to it, by creating a load balancer which will run in the cloud:

`kubectl expose deployment my-python-app --type=LoadBalancer --port=80 --target-port=80`{{execute}}

And just like that, DigitalOcean will expose the 10 load-balanced replicas of our simple Python app to the world. Keep running this command until you see `active` under the **Status** column for the new load balancer:

`doctl compute load-balancer list --format Name,Created,IP,Status`{{execute}}

Navigate to the IP address of the load balancer and hit refresh, and you'll see that the `hostname` we used earlier is changing with every refresh - cycling between the ten container IDs. This confirms that we have ten healthy Pods running and serving traffic.

## Congratulations!

You've created an app, built a Docker iamge of it, created a private registry,
uploaded your image, created a cluster, deployed your application to it, scaled
your app up 10x, and exposed it to the world over a load balancer. Sure, there
is overhead in getting to the point where your app is in a portable image and
running in a container, but the ability to control its scale and reproducibility
so powerfully is what makes DigitalOcean Kubernetes unique.

Up next, we're going to learn how to hook up our GitHub repo so that we
re-deploy our application on DigitalOcean Kubernetes using the latest code
whenever we push a new commit.
