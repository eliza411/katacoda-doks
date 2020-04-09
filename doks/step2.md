## Step 1: Authenticate this Environment with Your DigitalOcean Account

1. [Sign up for a DigitalOcean account](https://cloud.digitalocean.com/registrations/new)
2. [Generate a token](https://cloud.digitalocean.com/account/api/tokens/new)
with read and write access, and name it anything you like.

Save the token string somewhere safe, it won't be displayed again!

Let's authenticate `doctl` with your account using that token. Paste in the
token string when prompted.

`doctl auth init`{{execute}}

## Step 2: Let's build a simple Python app

This app just reports its hostname to the screen, and tries to connect to a
visitor counter, reporting that it can't if one isn't running.

Click this link to create `app.py`{{open}}

Now click the **Copy to Editor** to slot in our source code to `app.py`:

<pre class="file" data-filename="app.py" data-target="replace">
from flask import Flask
from redis import Redis, RedisError
import os
import socket

# Connect to Redis
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

As you can see, it's depending on the Python libraries for Flask and Redis. The way we express that dependency in Python is usually with a text file, so click this link to create `requirements.txt`{{open}}.

And click **Copy to Editor** to express our requirements in our new file.

<pre class="file" data-filename="requirements.txt" data-target="replace">
Flask
Redis
</pre>

## Step 3: Build a Docker Image

To deploy this, you'd normally run something like `pip` to install your
requirements and get your environment just so, then make sure you had a Python
runtime that was compatible with your code. But that creates a reproducibility
problem. "It works on my machine," you might say as you provide this code to
someone who doesn't have the same environment as you.

But, if we simply define the environment we need to run this code in a
`Dockerfile`, we can create an image, which is a build of not only our code, but
the runtime and the dependencies our code needs to run anywhere. That way when
we deploy, the code and everything it needs to run all travels together.

Click this link to create a `Dockerfile`{{open}}.

And click **Copy to Editor** to slot in the following code:

<pre class="file" data-filename="Dockerfile" data-target="replace">
# Use an official Python runtime as a parent image
FROM python:2.7-slim

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

Now click this command to create your Docker image based on the `Dockerfile` you defined. We're going to tag it with `-t` so it has a friendly name:

`docker build -t friendlyhello .`{{execute}}

Where is your built image? It’s in your machine’s local Docker image registry:

`docker images`{{execute}}

Let's run it and at long last see your application at work:

`docker run -p 80:80 friendlyhello`{{execute}}

You should see a notice that Python is serving your app at http://0.0.0.0:80.

To see the output, click the plus sign (*+*) to the right and select **View HTTP port 80 on Host 1**. Sure enough, our app says "Hello World!" a hostname provided by the Docker environment, and a message that it can't connect to Redis. (After all, we haven't installed Redis itself, just the Python library that connects to it.)

Try clicking this to run the app again:

`docker run -p 80:80 friendlyhello`{{execute interrupt}}

 You'll notice the hostname has changed. This tells us that every instance of
 our app is unique. In fact, the hostname is actually just the ID of the app's container -- the runtime instance of our image.

## Upload it

This is all well and good for your local environment, but the image we made is sitting in our local registry. To run it in production, we'll need to upload the image to a remote registry. DigitalOcean provides such a thing. Since you've already authenticated this environment with your DigitalOcean account in the beginning, you can create a registry now and log into it with Docker.

`doctl registry create do-katacoda`{{execute interrupt}}
`doctl registry login`{{execute}}

Now that you have a destination and Docker knows where it's pointing, have Docker `tag` your local image as being equivalent to the destination image, and send your local image on its way.

`docker tag myimage registry.digitalocean.com/do-katacoda/friendlyhello`{{execute}}
`docker push registry.digitalocean.com/do-katacoda/friendlyhello`{{execute}}

All uploaded! Now any machine on DigitalOcean that's run that same login step can pull your image from the DigitalOcean registry in the cloud and run it, with no Python setup, no `pip` installation, or anything. The command is much the same, except now we use the DigitalOcean registry's version of the image.

`docker run -p 80:80 registry.digitalocean.com/do-katacoda/friendlyhello`{{execute}}

You'll see Docker pull the image from the registry and run it. Again, you can see the output if you click the plus sign (*+*) to the right and select **View HTTP port 80 on Host 1**.

## Up next: Orchestrating

It's all well and good to oiawefoiawjfoiwjef
