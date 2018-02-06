# Kubepi

Bash scripts I'm using to provision my raspberry kubernetes cluster.

![cluster](cluster.jpg)

## Should I be using this?

The short answer: **NO**!

The longer answer: I'm building this to learn more about kubernetes. It's not meant as something that will work anywhere to setup a raspberry cluster. It works only for me.  
If your intent is to learn too, then you can use this repository as a starting point but will need to hack on it to fully understand what it does and why it does it.

## Usage

### image.sh

This script will initialize an SD card with raspbian. All SD cards on the cluster need to be initialized with it.  
It expects the SD card to be connected directly to your computer with a card reader, not through a raspberry pi.

In addition to installing the OS, it will:

* Enable SSH on the host
* Enable cgroups on the host

### master.sh [node ip]

This script will setup the master node, which need to be the first one we setup.  
The master node will be used as:

* Wifi router. It will be the only node connecting to wifi, and will proxy internet connection to ethernet nodes.
* DHCP server, for the IP range 10.0.0.x.
* Kubernetes master node.

The host's hostname will always become `kubemaster`.  
At the end of this script, a new `raspberry` cluster will be configured locally. That cluster will also become your current one.

**Note**: As this is the first node to be setup, it needs another DHCP server on ethernet to have an easy to find IP address.

So the setup needs to happen in 2 steps. The first time, connect the node to the main DHCP server (your main wifi router) using ethernet.  
At the end of the DHCP setup, the script will tell you to reboot the machine on the permanent network. Rerunning the script will then pick things up.

### node.sh [node name] [node ip] [--ingress]

This script will setup a node. You can set any name you wish.  
The node will automatically be configured to connect to the master node on `10.0.0.1`.

#### --ingress

You may want to transform one of the nodes into a Load Balancer, so your apps can send HTTP traffic and you can open that in a browser more easily.  
Adding the `--ingress` flag to the node.hs command will turn it into a load balancer:

* The node will connect to the wifi network
* The node will run [ingress-nginx](https://github.com/kubernetes/ingress-nginx)

You will then be able to setup ingress rules on your deployments to redirect traffic to pods.

### login.sh [master node ip]

If using a second machine, you may need to login again. This command will retrieve the master certificates, and configure the local cluster configuration.

### Pointing hostnames to the cluster

I am using [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) to point a wildcard top-level domain `.kube` to the ingress pod.  
I can then use hostname-routing to go to one app or another one.
