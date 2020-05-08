# Locust based Stress Testing

Locust is a distributed stress testing system. The system itself and the test specification are programmed in Python and can then be run on N hosts (a swarm) that all query a central server for work assignments. This installation tested about 1000 nodes.

The main server has a webinterface which is used to control the swarm and show statistics. 
By default the webinterface is not secured. This installation frontends it with an nginx server for that purpose and forces SSL and requests a password.

![locust1000](locust1000.png)



The locust package itself is hosted on PyPi.

This installation uses puppet to setup the locust central server and swarm. 
There are optimizations for AWS for quicker installation of the swarm using AWS specific AMI images and the AWS API.

Puppet controls the stress test spec file and restarts locust when a change is detected, allowing for dynamic changes to the spec file.

Here is an example stress test file, which gets an index.html page with a random OK parameter appended. One can specify a User-Agent and a fixed name which is used to group statistics (useful when the URL is diferent every time)

The example gets URL, then waits 0.1 seconds until it is executed again:

`from locust import HttpLocust, TaskSet, between`
`import random`

`def index(l):`
    `r = random.random()`
    `indexstr = "/index.html?ok=" + str(r)`
    `l.client.get(indexstr,headers={"User-Agent":"locust",name="/index.html?ok=[random]"})`

`class UserBehavior(TaskSet):`
    `tasks = {index: 1}`

`class WebsiteUser(HttpLocust):`
    `task_set = UserBehavior`
    `wait_time = between(0.1,0.1)`



## Installation using Vagrant and Puppet:

There are 3 steps in the installation:

1. Setup the puppetmaster server
2. Setup the locustmain server
3. Setup the locustnodes 

The Vagrantfile contains the logic for each step, after each run DNS names or IP addresses need to be adjusted

Puppet classes used

###### locust

  - installs the locust package, creates a locust user and client type startup files (--slave and --master-host)
  - installs the initial test spec (locustfile.py)
###### locustserver
  - installs the locust package, creates a locust user and server type startup files (--master and --webhost)
  - install nginx, certificates and a password file


Files: 
- locust
  - manifests/init.pp
  - files/locustfile.py
- locustserver/init.pp
  - manifests/init.pp
  - files/locustfile.py
  - files/dhparam.pem
  - files/nginx-selfsigned.crt
  - files/nginx-self-signed.key
  - files/htpasswd
  - files/default


Test on AWS
-----------

###### Prep: AWS Setup

- create access keys IAM, Users, Security Credentails
- create a security group called ssh
- AWS Access Keys are in the environment

###### vagrant up puppetmaster

- get IP of machine created: 
  - aws ec2 describe-instances --filters Name=instance-state-name,Values=running --output table | egrep 'InstanceType|PublicIpAddress'
  - Web GUI
- generate 2 Puppet classes: locust and locustserver and copy relevant files from local storage
- update puppetmaster.clouddomain.expert that is used to set the puppetmaster in Vagrantfile
  - in $nodescript puppet.conf

###### vagrant up locustmain

- get IP of machine created: 
  - aws ec2 describe-instances --filters Name=instance-state-name,Values=running --output table | egrep 'InstanceType|PublicIpAddress'
  - update locustmain.clouddomain.expert with IP. This DNS name is used by the locust swarm to connect to and get work
  - wait for 10 minutes until a puppet run has happened.
  - try https://locustmain.clouddomain.expert
    - accept the self-signed cert

###### vagrant up

- creates the initial nodes (10)
- as an optimization uses the base Ubuntu 18.04 image with puppet-agent and locust preinstalled
- drive_vagrant.sh can be used to incrementally add nodes
  - initial testing with simply creating 100 nodes has hit throttling by AWS, 
    the incremental route seems more productive
  - throughput: 1 node per minute +/-
- can be run in parallel on multiple AWS accounts
  - needs a keypair definition

###### Use AWS API/CLI for node creation

- Objective: faster than +/- 1 server per minute, work well almost instantaneous (< 2 minutes for 100 nodes)
- Uses an image that has locust and puppet preinstalled, similar to before, but also auto-starts locust and puppet (in cron every 5 minutes).
- puppet integration site.pp needs pattern/default for these nodes with names like ip-172-1-2-3.us-east-2.compute.internal /ip-172*compute.internal/ works as a pattern
- aws ec2 run-instances --image-id ami-0ed16d798cb7255ef --count 1 --instance-type t2.nano --key-name x1c --security-group-ids sg-07867fe9616aeffd9 --subnet-id subnet-65fa3429
  - AMI is the complete preconfigured image, just missing to register with puppet
  - security group is the id for a group that has SSH open
  - subnet-id: copied from AWS GUI, create an instance to see it
- adjust count to create more nodes

AMI images used:

- ami-07c1207a9d40bc3bd - base ubuntu 18.04, puppet installs everything
- ami-03d74b1461741236f - locust puppet installed, puppet configures
- ami-0ed16d798cb7255ef - locust running, puppet scheduled, pre configured can be launched through AWS API

