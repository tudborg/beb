beb
===

beb (Better ElasticBeanstalk) is a commandline tool for
building and deploying self-contained AWS ElasticBeanstalk builds.

It is built out of frustration with the `eb` tool that AWS provides,
and currently provides only what i need to not go insane.


AWS EB Platforms
----------------

Currently Supported Platforms:

- PHP (with Composer)



Dependencies
------------

Beb is written in bash and utilizes the [AWS CLI][awscli] for all
interaction with AWS. It uses [`jq`][jq] to parse the returned json.

You can build without these dependencies, as only modules that use
them, will check for their presence.

To build and deploy a PHP composer projekt you will need:

- Build (build the zip artifact)
    - `git`
    - `zip`
    - `composer` (and ofc `php`)
- Upload (upload the artifact to s3)
    - `aws`
    - `jq`
- Create (create an ElasticBeanstalk application version)
    - `aws`
    - `jq`
- Deploy (deploy an application version to an environment)
    - `aws`
    - `jq`











[awscli]: http://aws.amazon.com/cli/
[jq]: http://stedolan.github.io/jq/

