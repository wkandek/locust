Locust is a distributed stress testing system. The system itself and the test specification are programmed in Python and can then be run
 on N hosts (a swarm) that all query a central server for work assignments. 
 
The main server has a webinterface which is used to control the swarm and show statistics. 
By default the webinterface is not secured. This installation frontends it with a nginx server for that purpose and
forces SSL and requests a password.

The locust package itslef is hosted on PyPi.

Puppet is used to setup the locust central server and swarm. 
There are optimizations for AWS for quicker installation using AWS specific images and API.

Puppet controls the stress test spec file and restarts locust when a change is detected, allowing for dynamic changes to the spec.

Here is an example stress test file, which gets an index.html page with a random OK parameter appended.
One can specify a User-Agent and a fixed name which is used to group statistics (useful when the URL is diferent every time)
It waits 0.1 seconds until it is executed again:

from locust import HttpLocust, TaskSet, between
import random

def index(l):
    r = random.random()
    indexstr = "/index.html?ok=" + str(r)
    l.client.get(indexstr,headers={"User-Agent":"locust",name="/index.html?ok=[random]"})

class UserBehavior(TaskSet):
    tasks = {index: 1}

class WebsiteUser(HttpLocust):
    task_set = UserBehavior
    wait_time = between(0.1,0.1)



Installation using Vagrant and Puppet:
--------------------------------------

There are 3 steps in the installation:

1. Setup the puppetmaster server
2. Setup the locustmain server
3. Setup the locustnodes 

The Vagrantfile contains the logic for each step, after each run DNS names or IP addresses need to be adjusted

Puppet classes used
= locust
  - installs the locust package, creates a locust user and client type startup files (--slave and --master-host)
  - installs the initial test spec (locustfile.py)
  - installs a monitoring script for changes (watchlocust.py)
= locustserver
  - installs the locust package, creates a locust user and server type startup files (--master and --webhost)
  - install nginx, certificates and a password file


Files: in pmodules.tgz
- locust
  - manifests/init.pp
  - files/locustfile.py
- locustserver/init.pp
  - mainfests/init.pp
  - files/locustfile.py
  - files/dhparam.pem
  - files/nginx-selfsigned.crt
  - files/nginx-self-signed.key
  - files/htpasswd
  - files/default


Test on AWS
-----------

- seems to have a 64 VM launch limit in a window.
- Experiment with using multiple accounts.
  - see kandek subdir (uses kandek.com AWS) 
  - things to modify
    - exclude puppetmaster and locustmain
    - adapt the ssh key to the key downloaded (and probably named distinctly)

  
Prep: AWS Setup
- create access keys IAM, Users, Security Credentails
- create a security group called ssh
- AWS Access Keys are in the environment


1. vagrant up puppetmaster
- get IP of machine created: 
  - aws ec2 describe-instances --filters Name=instance-state-name,Values=running --output table | egrep 'InstanceType|PublicIpAddress'
  - Web GUI
- update puppetmaster.clouddomain.expert that is used to set the puppetmaster in Vagrantfile
  - $nodescript puppet.conf

2. vagrant up locustmain
- get IP of machine created: 
  - aws ec2 describe-instances --filters Name=instance-state-name,Values=running --output table | egrep 'InstanceType|PublicIpAddress'
  - update locustmain.clouddomain.expert with IP. This DNS name is used by the locust swarm to connect to and get work
  - wait for 10 minutes until a puppet run has happened.
  - try https://locustmain.clouddomain.expert
    - accept the self-signed cert

3. vagrant up
- creates the initial nodes (10)
- as an optimization uses the base Ubuntu 18.04 image with puppet-agent and locust preinstalled
- drive_vagrant.sh can be used to incrementally add nodes
  - initial testing with simply craeting 100 nodes has hit throttling by AWS, the incremental route seems more productive
  - 1 node per minute +/-
- can be run in parallel on multiple AWS accounts
  - needs a keypair definition

3a. Use AWS API/CLI for node creation
- Objective: faster than 3. (+/- 1 server per minute), work very well almost instantaneous (< 2 minutes for 100 nodes)
- puppet integration site.pp needs pattern/default for these nodes with name like ip-172-1-2-3.us-east-2.compute.internal
- aws ec2 run-instances --image-id ami-0ed16d798cb7255ef --count 1 --instance-type t2.nano --key-name x1c --security-group-ids sg-07867fe9616aeffd9 --subnet-id subnet-65fa3429


Images:
ami-07c1207a9d40bc3bd - base ubuntu 18.04, puppet installs everything
ami-03d74b1461741236f - locust puppet installed, puppet configures
ami-0ed16d798cb7255ef - locust running, puppet scheduled, pre configured can be launched through AWS API


Test On Virtaulbox
------------------






1. Puppetserver.clouddomain.expert on DO:
- 4GB machine in SF
- firewall: needs port 5557
apt-get update
apt-get upgrade
reboot
set hostname to puppetmaster.clouddomain.expert
echo "deb http://apt.puppetlabs.com bionic puppet5" > /etc/apt/sources.list.d/puppet5.list
cp puppet5-keyring.gpg /etc/apt/trusted.gpg.d/
apt-get install puppetserver
systemctl enable puppetserver
systemctl start puppetserver
ln -s /opt/puppetlabs/bin/puppet /usr/local/bin/puppet

for troubleshooting:
netstat -antp
journalctl -xe
 
install pmodules.tgz (has locust and locustserver) installs in /etc/puppetlabs/code/environment/productions/modules
modify site.pp:
node 'locustmain' {
  include locustserver
}
node /node*/ {
  include locust
}



Vagrantfile: see https://github.com/scottslowe/learning-tools/blob/master/vagrant/multi-provider/Vagrantfile
- edit NODE_COUNT to bring up nodes called node0, node1, etc
- the script will put a entry in /etc/crontab to run puppet every 5 minutes

- modify DNS of the puppetmaster (e.g. puppetmaster.clouddomain.expert) in vmscript
- modify locust/files/locust.service with DNS (or IP but DNS better) of the locustmain server
  - e.g. locustmain.clouddomain.expert
  after vagrant up locustmain and IP is known and updated then vagrant up can be used to 



Ansible for quick fixes:
------------------------
= on the puppetmaster
= StrictHostChecking off in /etc/ssh/ssh_config
= apt-get install ansible
= copy x1c.pem to /home/ubuntu/.ssh
= /etc/ansible/hosts
[testlocust:vars]
ansible_python_interpreter=/usr/bin/python3
[testlocust]
18.221.29.109
3.16.162.167
3.19.61.164
3.22.233.165
13.58.75.130
18.225.9.106
18.189.26.98
3.23.60.220
3.136.157.18
3.15.179.51
= ansible testlocust -s -m shell -a 'ls -l /home/' --private-key ~/.ssh/x1c.pem -u ubuntu
= aws ec2 describe-instances to populate the ansible/hosts file


Notes:
------
= for i in `puppet cert list --all | grep node | awk '{ print $2 }'`; do   j=`echo $i | sed 's/\"//g'`; puppet cert clean $j; done
= aws ec2 run-instances --image-id ami-0ed16d798cb7255ef --count 1 --instance-type t2.nano --key-name x1c --security-group-ids sg-07867fe9616aeffd9 --subnet-id subnet-65fa3429
= aws ec2 describe-instances --output table | grep PublicIPAddress
= aws ec2 describe-instances --filter "Name=instance-state-name,Values=running" --output table | grep PublicIpAddress | awk '{ print $4 }'






# install locust on server, nginx as a 443 frontend to the server running on 127.0.0.1:8089
apt-get update
apt install python3-pip
pip3 install locust

edit locustfile.py

from locust import HttpLocust, TaskSet, between

def index(l):
    l.client.get("/")

class UserBehavior(TaskSet):
    tasks = {index: 1}

class WebsiteUser(HttpLocust):
    task_set = UserBehavior
    wait_time = between(5.0, 9.0)


# nginx proxy for port 8089

apt install nginx apache2-utils

edit /etc/nginx/sites-enabled/default

server {
        listen 80;
        listen [::]:80;

        access_log /var/log/nginx/reverse-access.log;
        error_log /var/log/nginx/reverse-error.log;

        location / {
                    proxy_pass http://127.0.0.1:8089;
  }
}
for test

# now SSL and password on port 443:
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt

server {
    listen 443 http2 ssl;
    listen [::]:443 http2 ssl;

    server_name server_IP_address;

    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
    ssl_dhparam /etc/ssl/certs/dhparam.pem;

    access_log /var/log/nginx/reverse-access.log;
    error_log /var/log/nginx/reverse-error.log;

    location / {
        proxy_pass http://127.0.0.1:8089;
        auth_basic           "Admin Area";
        auth_basic_user_file /etc/nginx/htpasswd; 
    }
}

htpasswd -c /etc/nginx/htpasswd wkandek

# improved locustfile.py

from locust import HttpLocust, TaskSet, between
import random


def index(l):
    r = random.random()
    indexstr = "/index.html?ok=" + str(r)
    l.client.get(indexstr,headers={"User-Agent":"locust",name="/index.html?ok=[random]"})


class UserBehavior(TaskSet):
    tasks = {index: 1}

class WebsiteUser(HttpLocust):
    task_set = UserBehavior
    wait_time = between(0.1,0.1)

