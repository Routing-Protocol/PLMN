PLMN
====

This is a routing protocol based on Power Line Monitoring Network (PLMN). 

Working:
Packets are injected into the system so that each node has its position based on a coordinate system, a harvesting rate, and the destination SubStation.
Periodic transmissions of messages take place on each node. An 'REQ' is broadcast to the neighbouring nodes when a message needs to be sent ot the SubStation by the SourceNode. The node receiveing an 'REQ', NextHopNode, will send out a 'one_hop_msg' braodcast to all its neighbours to obtain all the coordinates of all its neighbours. Using this information, the NextHopNode calculates if it is the best candidate to forward the packet based on both the battery life consumption for receiving and forwarding the SourceNodePackets and also based on the distacen that cna be convered by forwarding the pacekt through that node adn its one hop neighbours. Of all the NextHopNodes that receive the REQ, the one with the best metric will send the REP first. The SourceNode will then use this as the next hope node to forward the measyred signal.

Testing:
The packets are injected from the file topFile.txt. This file contains the coordinats of each node along with individual harvesting rates. Running the test.py file wil create two log files, Boot and PLMNC, which will each log separates parts of the outputs. PLMNC logs whether the messages are received and the status of the nodes while Boot logs the content of the messages inside the received messages.
