beb
===

beb (Better ElasticBeanstalk) is a commandline tool for
building and deploying self-contained AWS ElasticBeanstalk builds.

It is built out of frustration with the `eb` tool that AWS provides,
and currently supports only what i need to not go insane.


Install
----------------

Clone this repo and symlink the `beb.sh` to somewhere on your `$PATH` so that it will be callable
with the command `beb`.
Validate the install by simply running `beb` and should should get something like:
```
$ beb
Usage:

    /Users/tbug/bin/beb [-d] [-q] <module> [-h] [<args>...]

    -d      Log at debug level
    -q      Log at warning level

Modules available:

    build
    environment
    release
    upload
    version
```


AWS EB Platforms
----------------

Currently Supported Platforms:

- PHP (with Composer)



Dependencies
------------

Beb is written in bash and utilizes the [AWS CLI][awscli] for all
interaction with AWS.

You can build without these dependencies, as only modules that use
them, will check for their presence.

To build and deploy a PHP composer projekt you will need:

- Build (build the zip artifact)
    - `git`
    - `zip`
    - `composer` (and ofc `php`)
- Upload (upload the artifact to s3)
    - `aws`
- Create (create an ElasticBeanstalk application version)
    - `aws`
- Release (deploy an application version to an environment)
    - `aws`


- - - 
**note**
You'll also need bash >4, as the bashbooster requires it.
I'll be working on fixing this, as the bashbooster library is not
really what we need anyway.



[awscli]: http://aws.amazon.com/cli/

