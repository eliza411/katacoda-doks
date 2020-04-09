## Step 1: Authenticate this Environment with Your DigitalOcean Account

1. [Sign up for a DigitalOcean account](https://cloud.digitalocean.com/registrations/new)
2. [Generate a token](https://cloud.digitalocean.com/account/api/tokens/new)
with read and write access, and name it anything you like.

Save the token string somewhere safe, it won't be displayed again!

Let's authenticate `doctl` with your account using that token. Paste in the
token string when prompted.

`doctl auth init`{{execute}}

## Step 2: Let's build a simple Python app

This app just reports its process ID to the screen, and tries to connect to a
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

To deploy this, you'd probably run something like `pip` to install your
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

`docker run -p 80:80 friendlyhello`

You should see a notice that Python is serving your app at http://0.0.0.0:80.

### Execute it

`node newFile2.js`{{execute}}
