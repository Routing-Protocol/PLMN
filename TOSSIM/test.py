# test.py for BlinkToRadio Application

# The first thing we need to do is import TOSSIM
# and create a TOSSIM object 
from TOSSIM import *
import sys

# The first thing we need to do is import TOSSIM
# and create a TOSSIM object
t = Tossim([])
r = t.radio()

#create files to write output
logboot = open("logBoot.txt", "w")
logapp = open("logApp.txt", "w")

# open topology file and read
f = open("topo.txt", "r")
lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    print " ", s[0], " ", s[1], " ", s[2];
    r.add(int(s[0]), int(s[1]), float(s[2]))

# We want to send the BlinkC and Boot channel to
# standard output. To do this, we need to import 
# the sys Pyhton package, which lets us refer to 
# standard output.
t.addChannel("PLMNC", sys.stdout)
t.addChannel("Boot", sys.stdout)
t.addChannel("PLMNC", logapp)
t.addChannel("Boot", logboot)

# Create noise model
noise = open("meyer-heavy.txt", "r")
lines = noise.readlines()
for line in lines:
  str = line.strip()
  if (str != ""):
    val = int(str)
    for i in range(1, 5):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(1, 5):
  print "Creating noise model for ",i;
  t.getNode(i).createNoiseModel()

# Booting nodes
t.getNode(0).bootAtTime(10);
t.getNode(1).bootAtTime(10);
t.getNode(2).bootAtTime(10);
t.getNode(3).bootAtTime(10);
t.getNode(4).bootAtTime(10);
t.getNode(5).bootAtTime(10);

#Injecting packets

from InitializationMsg import*

f = open("topoFile.txt", "r")
lines = f.readlines()
for line in lines:
  if (line != "\t\n"):
    s = line.split()
    print " ", s[0], " ", s[1], " ", s[2], " ", s[3];
    a = int(s[0])
    b = int(s[1])
    c = int(s[2])
    d = int(s[3])
    print a, " ", b, " ", c, " ", d;
    msg = InitializationMsg()
    msg.set_UX(b)
    msg.set_UY(c)
    msg.set_DX(0)
    msg.set_DY(0)
    msg.set_ReplenishmentRate(d)
    pkt = t.newPacket()
    pkt.setData(msg.data)
    pkt.setType(msg.get_amType())
    pkt.setDestination(a)
    pkt.deliver(a, t.time() + 20)
    #print "Delivering " + msg;


# runNextEvent returns the next event
for i in range(0, 10000):
  t.runNextEvent()
