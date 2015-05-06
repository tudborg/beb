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
Validate the install by simply running `beb` and you should see something like:
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

All beb components use `-h` for showing it's help message.
E.g:
```
$ beb version list -h
```


Command Completion
--------------------

The tool also ships with a bash completion file.
Simply source the `completion.bash` and you have tab-completion
on your `beb` commands.


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

To build and deploy a PHP composer project you will need:

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




Usage
============

Here is a short introduction to the available commands.

beb build
-----------

```
beb build [-r <label-file-name>] <git-dir> [<bundle-out-file>]
```

The build command will - based on the type of project detected in the
directory you point at - perform a build step (on a seperate copy of
that git repo) and place the resulting build zip at the defined `<bundle-out-file>`
(or place a zip with the repo's current commit-ish).

### The clone step

Beb will run a clone on the git repo you point it at, to get a copy to work on.
The exact command run is:
```
git clone --depth 1 --recurse-submodules "file://$gitdir" "$compiledir"
```
where `$gitdir` is what you pointed it at, and `$compiledir` is a temp directory
used in the build and artifact step.

If `-r <label-file-name>` is given to `beb build`, this is also the time
a file with the name you passed will be created in the root directory if the
cloned repo. The content of the file will be a git tag-ish that identifies
exactly what git commit was cloned and used in the build.


### The build step

The project detection currently supports the following types:


#### Composer Project

Detected by the presence of a `composer.json` file.

The build step for a composer project is:
```
$COMPOSER_BIN $COMPOSER_INSTALL_ARGS
```
where `$COMPOSER_BIN` defaults to `composer` and `$COMPOSER_INSTALL_ARGS` defaults to
`-v --prefer-dist --no-dev --optimize-autoloader --ignore-platform-reqs`.

You can overide the above variables in your environment to customize the build process.


#### Plain PHP

Detected by the presence of a `php.project` file (the content is not important)

No build step os performed. The files are left as-is.





### The artifact step

If the build step completes, the artifact handler will be run.
Both the Composer project and the Plain PHP project use the zip artifact handler.

The zip artifactor will zip the completed build directory at the destination
you passed to `beb build` (or in your current directory, with a git-tag-ish as the filename)





beb upload
-----------

```
beb upload [-f] <artifact> <bucket> [<key>]
```

Will upload your build artifact to S3.
If the key is already present, the command will fail with
a non-zero exit code.

If you specify `-f` the key will be overwritten.
Note that AWS beanstalk will blindly continue to use it
as a previous deploy, so be very careful with `-f`.

`beb upload` will write the destination bucket and key to
stdout for easy capture.

This is useful if you didn't specify `<key>` on the command line.


Example:

```bash
# Upload and capture output.
# Note that we don't specify the <key> param
DEP_UPLOAD="$(beb upload "$DEP_BUILD_FILE" "$S3_RELEASE_BUCKET")"
# cut the captured output to grab bucket and key
DEP_UPLOAD_BUCKET="$(echo "$DEP_UPLOAD" | cut -f 1)"
DEP_UPLOAD_KEY="$(echo "$DEP_UPLOAD" | cut -f 2)"
```

beb version create
------------------

```
beb version create <application-name> <bucket> <key> <label> [<description>]
```

Create a new AWS Elastics Beanstalk Application Version.
This is what identifies release on beanstalk, and is
what shows up in the web-console.

A version requires an application name (beanstalk application),
an S3 bucket and key to locate the actual deploy, a label
and an optional description.

You will be refering to the application version by label,
so choose something meaningful.
The git-tag-ish is a good option, but anything is fine,
as long as it is unique within the beanstalk application.

Example:

```bash
EB_APPLICATION_NAME="my-eb-application"
DEP_LABEL="myapp.v1.0.0"
DEP_DESC="Some description. This is optional."

DEP_CREATE="$(beb version create "$EB_APPLICATION_NAME" \
    "$DEP_UPLOAD_BUCKET" \
    "$DEP_UPLOAD_KEY" \
    "$DEP_LABEL" \
    "$DEP_DESC")"
```

Note that we already grabbed `$DEP_UPLOAD_BUCKET` and `$DEP_UPLOAD_KEY` in the above example.

The tool will output the application version and label on stdout,
which is why we captured the output in `$DEP_CREATE` in the above example.

You can grab the application name and label with

```bash
DEP_CREATE_APPLICATION="$(echo "$DEP_CREATE" | cut -f 1)"
DEP_CREATE_LABEL="$(echo "$DEP_CREATE" | cut -f 2)"
```


beb release
--------------

```
beb release <label> <environment-name>
```

Tells Elastic Beanstalk to release the application version
with label `<label>` to the environment `<environment-name>`.

The command outputs a progress report and exists when the
deploy succeeds or fails.
Depending on your deploy and the environment, this can take
anything from seconds to minutes.

For a list of available environments, check out
```
beb environment list [<application-name>]
```

For a list of registered application versions, check out
```
beb version list <application-name>
```



[awscli]: http://aws.amazon.com/cli/

