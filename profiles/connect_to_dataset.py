"""This profile creates a node that connects to a remote dataset, either a long term dataset or a short term dataset, created via the Portal. 

Instructions:
Log into your node, your dataset file system in mounted at `/mydata`.
"""

import geni.portal as portal
import geni.rspec.pg as RSpec
import geni.rspec.igext

pc = portal.Context()
pc.defineParameter( "s", "Storage",
		    portal.ParameterType.STRING, "urn:publicid:IDN+clemson.cloudlab.us:basemod-pg0+stdataset+ngs-assembly" )

params = pc.bindParameters()

IMAGE = "urn:publicid:IDN+emulab.net+image+emulab-ops:CENTOS7-64-STD"

# Create a Request object to start building the RSpec.
request = pc.makeRequestRSpec()

node = request.RawPC("jumpnode")
node.disk_image = IMAGE

# We need a link to talk to the remote file system, so make an interface.
iface = node.addInterface()
fslink = request.Link("fslink")
fslink.addInterface(iface)

# The remote file system is represented by special node.
fsnode = request.RemoteBlockstore("fsnode", "/mydata")
# This URN is displayed in the web interfaace for your dataset.
fsnode.dataset = params.s

# Now we add the link between the node and the special node
fslink.addInterface(fsnode.interface)

# Special attributes for this link that we must use.
fslink.best_effort = True
fslink.vlan_tagging = True

# Print the RSpec to the enclosing page.
pc.printRequestRSpec(request)