## XRay Measurement Study for Google Play

### Running the experiment

Run `rake xray:movies_experiment` to run it with your local env, or run it with
Docker (preferred).

First, install the two dependencies

* [Docker](https://docs.docker.com/installation/)
* [Compose](https://docs.docker.com/compose/install/)

If running this on OS X, you need to install
[boot2docker](http://docs.docker.com/installation/mac/) first.

Build the image, then start the container as a daemon:

    $ docker-compose build
    $ docker-compose up -d

The rake task for the experiment will run.

### Logs

A log is saved at recommendations.log. This contains information on rounds.

To see the logs of the application (progress, debug, etc.), first get the
ID of the container with `docker ps`, then

    $ docker logs -f ID_OF_CONTAINER

There is a problem with the logs currently, where info messages are not flushed
to stdout all the time. I have no idea what's going on.
