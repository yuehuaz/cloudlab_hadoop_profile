import geni.portal as portal
import geni.rspec.pg as RSpec
import geni.rspec.igext

pc = portal.Context()

pc.defineParameter( "n", "Number of slave nodes",
		    portal.ParameterType.INTEGER, 3 )
		    
pc.defineParameter( "s", "Storage",
		    portal.ParameterType.STRING, "urn:publicid:IDN+clemson.cloudlab.us:basemod-pg0+stdataset+test-dataset" )

params = pc.bindParameters()

IMAGE = "urn:publicid:IDN+emulab.net+image+emulab-ops//hadoop-273"
SETUP = "https://github.com/yuehuaz/cloudlab_hadoop_profile/raw/master/hadoop-2.7.3-setup.tar.gz"

request = pc.makeRequestRSpec()

lan = request.LAN()
lan.best_effort = True
lan.vlan_tagging = True
lan.link_multiplexing = True

node = request.RawPC( "namenode" )
node.hardware_type = 'c8220'
node.disk_image = IMAGE
node.addService( RSpec.Install( SETUP, "/tmp" ) )
node.addService( RSpec.Execute( "sh", "sudo /tmp/setup/hadoop-setup.sh" ) )
iface = node.addInterface( "if0" )
lan.addInterface( iface )

node = request.RawPC( "resourcemanager" )
node.hardware_type = 'c8220'
node.disk_image = IMAGE
node.addService( RSpec.Install( SETUP, "/tmp" ) )
node.addService( RSpec.Execute( "sh", "sudo /tmp/setup/hadoop-setup.sh" ) )

iface = node.addInterface( "if1" )
lan.addInterface( iface )

# We need a link to talk to the remote file system, so make an interface.
iface = node.addInterface()
fslink = request.Link("fslink")
fslink.addInterface(iface)

for i in range( params.n ):
    node = request.RawPC( "slave" + str( i ) )
    node.hardware_type = 'c8220'
    node.disk_image = IMAGE
    node.addService( RSpec.Install( SETUP, "/tmp" ) )
    node.addService( RSpec.Execute( "sh", "sudo /tmp/setup/hadoop-setup.sh" ) )
    iface = node.addInterface( "if0" )
    lan.addInterface( iface )

# The remote file system is represented by special node.
fsnode = request.RemoteBlockstore("fsnode", "/mydata")
# This URN is displayed in the web interface for your dataset.
fsnode.dataset = params.s

# Now we add the link between the node and the special node
fslink.addInterface(fsnode.interface)

# Special attributes for this link that we must use.
fslink.best_effort = True
fslink.vlan_tagging = True

from lxml import etree as ET

tour = geni.rspec.igext.Tour()
tour.Description( geni.rspec.igext.Tour.TEXT, "A cluster running Hadoop 2.7.3. It includes a name node, a resource manager, a remote dataset, and as many slaves as you choose." )
tour.Instructions( geni.rspec.igext.Tour.MARKDOWN, "After your instance boots (approx. 5-10 minutes), you can log into the resource manager node and submit jobs.  [The HDFS web UI](http://{host-namenode}:50070/) and [the resource manager UI](http://{host-resourcemanager}:8088/) will also become available." )
request.addTour( tour )

pc.printRequestRSpec( request )