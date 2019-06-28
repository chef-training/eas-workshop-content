# Introduction

This repository contains the reference architecture for the Effortless Config pattern. It will provide an opinionated repository structure and usage methodology for the pattern, alongside documentation on the motivations for this pattern and its typical usage.

Please contact Jon Cowie (jcowie@chef.io) or John Snow (jsnow@chef.io) if you have questions or would like more information!

# Building Effortless Config Apps

## Requirements

To configure and build a Effortless Config application, you will need Habitat installed and configured on your development workstation. If you want to upload the package to Habitat Bldr, you'll also need to have configured an origin and downloaded its keys into your local Habitat key cache.

You can find instructions on how to work with Habitat Bldr [here](https://www.habitat.sh/docs/using-builder/)

## Introduction

Before we build and test an Effortless Config application, it's important to understand what the application actually contains and does. This section will give you an overview of those topics.

The Effortless Config application uses the policyfiles feature of Chef to encapsulate an application which runs chef-solo against a compiled policyfile and the collection of cookbooks it needs.  This is done in the underlying habitat code by running the ``chef install`` command against a Policyfile and then the ``chef export`` command to produce a working copy of the compiled policy file and all cookbooks. This is then bundled up as a habitat application, and executed using the application hooks provided to actually run Chef on the desired node.

It's possible to leverage the ``include_policy`` feature of Policyfiles to layer multiple policy files on top of eachother - we provide examples of doing this in the ``policyfiles`` directory. 

It's important to note that as the Effortless Config application you're building is specific to the policyfile it runs, the name of the artefact produced will be ``chef-<policyfile>``. So for example if you build Effortless Config for the ``base.rb`` policy, the resulting application artefact will be called ``chef-base``. 

If you're layering multiple policyfiles using `include_policy`, the application will be named for the 'leaf node' in the tree. So for example if you build Effortless Config for the ``production.rb`` policy which in turn includes ``base.rb``, the resulting artefact will be called ``chef-production``.

## Directory Structure

Before we build the app, this section will outline the contents of the directories that comprise it.

* cookbooks: This directory contains the cookbooks our application will run that aren't downloaded from a supermarket
* habitat: This directory contains the plan.sh and config files to build the habitat application for Effortless Config on Linux operating systems
* habitat-win: This directory contains the plan.ps1 and config files to build the habitat application for Effortless Config on Windows operating systems
* policyfiles: This directory contains the chef policyfiles that will control what Effortless Config runs and the attributes used to configure it
* test: This directory contains test kitchen tests for running local testing environments for Habitat-mamaged Chef applications.


## Preparing to Build Effortless Config

Now that you're familiar with what the Effortless Config application does and the structure of the directories we've included here, you're ready to try building your own application!

The first step is to prepare a policyfile for your application. We'd suggest you use ``policyfiles/base.rb`` as this is ready to go out of the box, but if you'd like to customize the policyfile you're going to run this is your chance!

Before building the application, you're also going to need to configure the server URL and token for the Automate 2 server your nodes will report to. These need to be set in two locations:

* ``habitat/default.toml``: Change the ``server_url`` and ``token`` fields to match your A2 environment.
* ``policyfiles/base.rb``: Change the URL and token fields in the attribute hash at the bottom of this file to match your A2 environment. Please note that in the ``reporter`` section you'll need to make sure you have ``/data-collector/v0`` after your A2 hostname.
 

## Building Effortless Config

Now that we have prepared the Policyfile we're going to use to build our Effortless Config application, it's time to build the application itself.

The process for building this application is the same as any other habitat application, with the addition of an environment variable we set to let Habitat know which Policyfile we want to build from (we will default to using ``base.rb`` if none is specified). To build your Effortless Config application, run the following commands from the root of the repository and substitute ```<policy>``` for the policyfile you wish to build:

(please note lines beginning ```[1][default:/src:0]#``` indicate commands run inside hab studio - this portion of the line should not be typed.)

```
$> hab studio enter
[1][default:/src:0]# cd chef-client
[1][default:/src:0]# env CHEF_POLICYFILE=<policy> build
```

Once the build process has successfully completed, you should see lines similar to the following at the end of the build output:

```
   chef-base: Source Path: /src/chef-client
   chef-base: Installed Path: /hab/pkgs/jonlives/chef-base/0.1.0/20180703121923
   chef-base: Artifact: /src/chef-client/results/jonlives-chef-base-0.1.0-20180703121923-x86_64-linux.hart
   chef-base: Build Report: /src/chef-client/results/last_build.env
   chef-base: SHA256 Checksum: b65874a34e23fae343e2ac235c377a62a11a3476a4a16b09b9b993a01b1865a5
   chef-base: Blake2b Checksum: 1f5086b25e196dc29fd867e1dd6a406548aff08f19595703cd14121b1a353207
   chef-base: 
   chef-base: I love it when a plan.sh comes together.
   chef-base: 
   chef-base: Build time: 1m38s
```

The artifact line shows you the path to your newly-build Effortless Config artifact which can now be uploaded to bldr or exported to a docker container to run locally.

## Testing Effortless Config Locally

Once you have built a local copy of your Effortless Config application as described in the above section, you can use TestKitchen to verify that the chef-run it contains functions as you expect.

First, if you didn't build from the ```base.rb``` policyfile you'll need to change ```chef-client/.kitchen.yml``` to specify the correct package name in the ```suites``` section shown here:

```
suites:
  - name: base
    provisioner:
      arguments: ["<%= ENV['HAB_ORIGIN'] %>", "chef-base"]
    verifier:
      inspect_tests:
        test/integration/base
```

Once you've verified the package name, you can run the following commands to create a docker container running your Effortless Config application, and run the tests contained in the ```chef-client/test``` directory against it:

```
$> kitchen converge
$> kitchen verify
```