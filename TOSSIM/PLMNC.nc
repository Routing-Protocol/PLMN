#include <math.h>
#include <Timer.h>
#include "PLMN.h"

#define min(a,b) ( (a>b) ? b : a )
#define max(a,b) ( (a>b) ? a : b )


module PLMNC{
	
	uses interface Boot;///////////Nodes have to be synchronized. Timestamps have to be the same
	
	uses interface Timer<TMilli> as PeriodicMonitoring;
	uses interface Timer<TMilli> as Timer1;
	
	uses interface SplitControl as AMControl;
	
	uses interface Packet as REQPacket;
	uses interface AMPacket as REQAMPacket;
	uses interface AMSend as SendREQ;
	
	uses interface Packet as OneHopPacket;
	uses interface AMPacket as OneHopAMPacket;
	uses interface AMSend as SendOneHop;
	
	uses interface Packet as OneHopReplyPacket;
	uses interface AMPacket as OneHopReplyAMPacket;
	uses interface AMSend as SendOneHopReply;	
		
	uses interface Packet as REPPacket;
	uses interface AMPacket as REPAMPacket;
	uses interface AMSend as SendREP;
		
	uses interface Packet as PLMNPacket;
	uses interface AMPacket as PLMNAMPacket;
	uses interface AMSend as SendPLMN; 
	
	uses interface LocalTime<TMilli>;
	
	uses interface PacketAcknowledgements as PacketAck;
	
	//uses interface Read<uint16_t> as BatteryVoltage;
	
	uses interface Leds;
	
	uses interface Receive as InitializationReceiver;
	uses interface Receive as REQReceiver;
	uses interface Receive as OneHopReceiver;
	uses interface Receive as OneHopReplyReceiver;
	uses interface Receive as REPReceiver;
	uses interface Receive as PLMNReceiver;	
	
}
implementation{
	
	uint16_t PeriodicCounter = 0x00;/////Period of sensing  dT
	uint16_t MeasuredSignal = 0x00;
	uint16_t counter = 0x00;
	uint16_t SentNodeID = 0x00;
	
	uint16_t SubStationID = 0x00; //********************************SubStation has to have node ID 0*************//
	
	uint8_t NretxMax = 0x08;

    
    //Link Rate Determination
    uint16_t L_ud = 0x00;/////Average length of each packet to be transmitted
    uint16_t N_ud = 0x00;/////Number of packets to be transmitted
    uint16_t r = 0x00;////////Link Rate
    uint32_t REQSendTime = 0x00;
    
    
    //Values needed for Metric calculations
    
    uint16_t BatteryLevel = 0x00;
    uint16_t HarvestingRate = 0x00;
    double PowerLevel = 0.00;
    float PRR = 0x01;      
    double ActiveCurrentDraw = 0.00;
    
    double CV_uD = 0.00;
    double C_ADV = 0.00;
    
    bool SelectionDone = FALSE;
      
    //Distance Calculation ///////////////////////////////in meters///////////////////////////
    uint16_t u_X = 0x00;///////Current Node Location
    uint16_t u_Y = 0x00;
    uint16_t d_X = 0x00;///////Destination NOde Location
    uint16_t d_Y = 0x00;
    double d_uv = 0.00;///////Distance between current and next hop node
        
    
    uint16_t R = 300;
        

    
    //Energy Distance Estimation
    uint16_t w_X[10];
    uint16_t w_Y[10];
    uint16_t neighbour_node[10];
    uint16_t dvw[10];
    
    double d_vw = 0.00;
    
    
    //Battery Level
    //AA: (2.85 Ah) x (1.5 V) x (3600 s) = 15,390 J
    
    uint16_t Bmax = 30780;//Maximum battery level in J
    uint16_t Bv = 0;//Current battery level
    
    uint16_t processorCurrent = 8;//mA
    uint16_t sendCurrent = 10;//mA
    uint16_t receiveCurrent = 16;//mA
    
    uint16_t EnergyConsumed = 0x00;
    
    //Time variables
    uint32_t startTime = 0x00;
    uint32_t rstartTime = 0x00;
    uint32_t rstopTime = 0x00;
    
    uint32_t rTime = 0x00;
    
    uint32_t sendStartTime = 0x00;
    uint32_t sendDoneTime = 0x00;
    
    uint32_t rsendTime = 0x00;
    uint32_t rreceiveTime = 0x00;
    uint32_t processorTime = 0x00;
    
    uint32_t REPsentTime = 0x00;
  
  
    //Variables for application
    message_t pkt;
    
    bool RADIO = FALSE;
    bool BUSY = FALSE;
    
    
    //Variable for Acknowledgment Count	
	uint16_t REQacknowledged = 0x00;
	uint16_t REQretransmissions = 0x00;
	uint8_t REQretx = 0x00;
	uint16_t REQLostPackets = 0x00;
	
	
	//Receiving the REQ packet 	
	uint16_t PacketN;
	uint16_t PacketL;
	uint16_t SourceXPosition;
	uint16_t SourceYPosition;
	uint16_t DestinationXPosition;
	uint16_t DestinationYPosition;
	uint32_t REQTimeSent;
	uint16_t SourceNode;
	uint16_t Acknowledged;
	uint16_t LostPackets;
	
	uint32_t ForwardTime;
	uint32_t REQTimeReceived;
	
	//Forward Selection
	uint16_t AwakeNodes = 0x00;
	uint32_t Tref = 0x00;
	
	
	uint16_t Next_Hop = 0x00;	    
  
	
	event void Boot.booted()
	{		
		startTime = call LocalTime.get();
		
		MeasuredSignal = 0x00;//Clearing Stored Measure
		
	    dbg("PLMNC", "Booted\n");
		call AMControl.start();
		call PeriodicMonitoring.startPeriodic(TIMER_PERIODIC_MILLI_0);	
		
		
	}
	
	event void AMControl.startDone(error_t err)
	{
		if (err == SUCCESS)
		{
			rstartTime = call LocalTime.get();
			
			dbg("PLMNC", "Radio Swtiched On\n");
			RADIO = TRUE;
		}
		
		else
		{
			call AMControl.start();
		}
	}
	
	
	event void AMControl.stopDone(error_t err)
	{
		//rstopTime = call LocalTime.get();
	}	

	

	task void DoNothing();
	
	task void TaskSendREQ();
	
	task void TaskSendOneHop();
	
	task void TaskSendOneHopReply();
	
	task void TaskMetricCalculation();
	
	task void TaskVForwardTime();
	
	task void TaskDistanceCalculation();
	
	task void TaskSendREP();
	
	task void TaskSendPLMN();

	
	
	
	event void PeriodicMonitoring.fired()
	{
		MeasuredSignal = 0x25525;//Storing Sensed Information				
		SentNodeID = TOS_NODE_ID;
		
		REQretx = 0x00;
				
		post TaskSendREQ();		
		
		
		AwakeNodes = 0x00;
		
		counter++;
		
	}
	
	
	event void Timer1.fired()
	{
		post TaskSendREP();
	}
	

	
	//Receiving messages
	
	
	event message_t* PLMNReceiver.receive(message_t* plmnMsg, void* payload, uint8_t len)
	{
		uint16_t counterl = counter;
		uint16_t REQretransmissionsl = REQretransmissions;
		
		if (len != sizeof(PLMNMsg))
		{
			dbg("Boot", "Nothing inside PLMN message\n");
		}
		else
		{
			PLMNMsg* plmn = (PLMNMsg*)payload;
			
			SentNodeID = plmn->nodeid;
			counter = plmn->counter;
			MeasuredSignal = plmn->MeasuredSignal;
			REQretransmissions = plmn->retransmissions;
			
			
			if (call PLMNAMPacket.isForMe(plmnMsg) == TRUE)
			{
				dbg("Boot", "SubStation recived message\n");////////////Include the message************************8
				post DoNothing();
			}
			else
			{				
				if (SelectionDone == TRUE)
				{
					if (call SendPLMN.send(Next_Hop, &pkt, sizeof(PLMNMsg)) == SUCCESS)
					{
						BUSY = TRUE;
					}
				}
				else
				{
					post TaskSendREQ();
				}
			}
		}	
		
		return plmnMsg;
	}
	
	
	
	//Receiving Injected Packets
	
	event message_t* InitializationReceiver.receive(message_t* initMsg, void* payload, uint8_t len)
	{
		if (len != sizeof(initialization_msg_t))
		{
			dbg("Boot", "Nothing inside Initialization message\n");
			return initMsg;
		}
		else
		{			
			initialization_msg_t* im = (initialization_msg_t*)payload;
			u_X = im->UX;
			u_Y = im->UY;
			d_X = im->DX;
			d_Y = im->DY;
			HarvestingRate = im->ReplenishmentRate; 
			dbg("PLMNC", "Initialization Message Received; Being Written on Node\n");
		}
		
		dbg("Boot", "node: %hhu \n \t\t\t\t u_X : %hhu \n \t\t\t\t u_Y : %hhu \n \t\t\t\t d_X : %hhu \t\t\t\t \n \t\t\t\t d_Y : %hhu \n \t\t\t\t Harveting Rate : %hhu \n ", TOS_NODE_ID, u_X, u_Y, d_X, d_Y, HarvestingRate);
		
		return initMsg;
	}
	
	
	
	//Asking Neighbors To Send Their Locations
		
	uint16_t OneHopReplyNode = 0x00;
	
	event message_t* OneHopReceiver.receive(message_t* onehopMsg, void* payload, uint8_t len)
	{
		if (len != sizeof(one_hop_msg_t))
		{
			dbg("PLMNC", "Nothing inside OneHop Message\n");
			return onehopMsg;
		}
		else
		{
			one_hop_msg_t* ohm = (one_hop_msg_t*)payload;
			OneHopReplyNode = ohm->v_node;
		}
		dbg("Boot", "One Hop Broadcaster Received: Node: %hhu", OneHopReplyNode);
		
		post TaskSendOneHopReply();
		
		return onehopMsg; 
	}
	
	
	
	//Receiving neighbors request for the request for their locations
	
	int i = 0;		
	double TbfV = 0.00;
	double Tbf = 0.00;
	
	event message_t* OneHopReplyReceiver.receive(message_t* onehopreplyMsg, void* payload, uint8_t len)
	{
		if (len != sizeof(one_hop_reply_msg_t))
		{
			dbg("PLMNC", "Nothing inside OneHopReply Message\n");
			return onehopreplyMsg;
		}
		else
		{
			one_hop_reply_msg_t* ohrm = (one_hop_reply_msg_t*)payload;
			w_X[i] = ohrm->WX;
			w_Y[i] = ohrm->WY;			
			neighbour_node[i] = ohrm->W_node;
			
			i++;
			
			dbg("Boot", "One Hop Locations Received: Neighbour Node:%hhu \n \t\t\t Coordinates: X - %hhu    Y - %hhu \n", neighbour_node[i], w_X[i], w_Y[i]);	 	
		}
		dbg("PLMNC","One Hop Neighbour \n");
		
		post TaskMetricCalculation();
		
				
    
		post TaskDistanceCalculation();
		
		C_ADV = (( d_uv + d_vw)/ (2 * R)) * CV_uD;		
		
		
		
		Tref = REPsentTime - REQTimeSent;
		
		Tbf = AwakeNodes * Tref;
		
		TbfV = ( 1 - C_ADV) * Tbf;
		
		call Timer1.startPeriodic(TbfV);
			
		
		return onehopreplyMsg;
		     
	}
	
	
	event message_t* REPReceiver.receive(message_t* REPmsg, void* payload, uint8_t len)
	{
			
		if (len != sizeof(REP))
		{
			dbg("Boot", "Nothin inside  REP Message\n");
			return REPmsg;		
		}
		else
		{
			REP* repmsg = (REP*)payload;
			
			Next_Hop = repmsg->is_next_hop;
			
			dbg("PMNC", "REP message received\n");
			
			post TaskSendPLMN();
			
			SelectionDone = TRUE;
		}
		
		return REPmsg;
		
		
		
	}

	
	
	event message_t* REQReceiver.receive(message_t* REQmsg, void* payload, uint8_t len)
	{
		REQTimeReceived = call LocalTime.get();
		
		if (len != sizeof(REQ))
		{
			dbg("Boot", "Nothing inside REQ Message\n");
			return REQmsg;
		}
		else
		{
			REQ* rmsg = (REQ*)payload;
			
			PacketN = rmsg->N;
			PacketL = rmsg->L;
			SourceXPosition = rmsg->uXPosition;
			SourceYPosition = rmsg->uYPosition;
			DestinationXPosition = rmsg->DXPosition;
			DestinationYPosition = rmsg->DYPosition;
			REQTimeSent = rmsg->REQTime;
			SourceNode = rmsg->CurrentNode;
			Acknowledged = rmsg->Acknowledged;
			LostPackets = rmsg->LostPackets;
		
			
			dbg("PLMNC", "REQ message received\n");	
			
			post TaskVForwardTime();
			
			post TaskSendOneHop();		
		}
		
		return REQmsg;
	} 
	

	//AMSend.sendDone Implementation
	event void SendREQ.sendDone(message_t* msg, error_t err)
	{
		rsendTime = 0x00;
		
		sendDoneTime = call LocalTime.get();
		rsendTime = sendDoneTime - sendStartTime;
		
		if (&pkt == msg)
		{
			BUSY = FALSE;
			dbg("PLMNC", "REQ Message was sent @ %s, \n", sim_time_string());
		}
		
		
		if (call PacketAck.wasAcked(msg))
		{
			REQSendTime = call LocalTime.get();
			
			REQretransmissions = 0;
			REQacknowledged++;
			
			AwakeNodes++;
		}
		else
		{
			REQretx++;
			REQretransmissions = REQretx;
			REQLostPackets++;
			
			if (REQretx < NretxMax)
			{
				post TaskSendREQ();
			}
			else
			{
				post DoNothing();
			}
		}
	}
		
	event void SendOneHop.sendDone(message_t* msg, error_t err)
	{
		sendDoneTime = call LocalTime.get();
		rsendTime = rsendTime + (sendDoneTime - sendStartTime);
		
		BUSY = FALSE;
		return;
	}	
	
	event void SendOneHopReply.sendDone(message_t* msg, error_t err)
	{
		sendDoneTime = call LocalTime.get();
		rsendTime = rsendTime + (sendDoneTime - sendStartTime);
		
		BUSY = FALSE;
		return;
	}
	
	event void SendREP.sendDone(message_t* msg, error_t err)
	{
		REPsentTime = call LocalTime.get();
		
		sendDoneTime =  call LocalTime.get();
		rsendTime = rsendTime + (sendDoneTime - sendStartTime);
		
		BUSY = FALSE;
		return;
	}
	
	event void SendPLMN.sendDone(message_t* msg, error_t err)
	{
		BUSY = FALSE;
		return;
	}

	
	
	
	
	
    task void DoNothing()
	{}
	
	
	
	
	task void TaskSendREQ()
	{
		REQ* REQpkt = (REQ*)(call REQPacket.getPayload(&pkt, sizeof(REQ)));
		
		if (REQpkt == NULL)
		{
			return;
		}
		
		N_ud = 1;
		L_ud = 28;
		
		REQpkt->N = N_ud;
		REQpkt->L = L_ud;
		REQpkt->uXPosition = u_X;
		REQpkt->uYPosition = u_Y;
		REQpkt->DXPosition = d_X;
		REQpkt->DYPosition = d_Y;
		REQpkt->REQTime = REQSendTime;
		REQpkt->CurrentNode = TOS_NODE_ID;
		REQpkt->Acknowledged = REQacknowledged;
		REQpkt->LostPackets = REQLostPackets;
		
		
		call PacketAck.requestAck(&pkt);
		if (call SendREQ.send(AM_BROADCAST_ADDR, &pkt, sizeof(REQ)) == SUCCESS)
		{
			REQTimeSent = call LocalTime.get();
			
			sendStartTime = call LocalTime.get();
			
			BUSY = TRUE;
		}
	}
	
	
	
		
	task void TaskSendOneHop()
	{
		one_hop_msg_t* ohpkt = (one_hop_msg_t*)(call OneHopPacket.getPayload(&pkt, sizeof(one_hop_msg_t)));
		
		if (ohpkt == NULL)
		{
			return;
		}
		
		ohpkt->v_node = TOS_NODE_ID;
		
		
		if (call SendOneHop.send(AM_BROADCAST_ADDR, &pkt, sizeof(one_hop_msg_t)) == SUCCESS)
		{
			sendStartTime = call LocalTime.get();
			
			BUSY = TRUE;
		}		
	}
			
	task void TaskSendOneHopReply()
	{
		one_hop_reply_msg_t* ohrpkt = (one_hop_reply_msg_t*)(call OneHopReplyPacket.getPayload(&pkt,sizeof(one_hop_reply_msg_t)));
		
		if (ohrpkt == NULL)
		{
			return;
		}
		
		ohrpkt->W_node = TOS_NODE_ID;
		ohrpkt->WX = u_X;
		ohrpkt->WY = u_Y;
		
		
		call PacketAck.requestAck(&pkt);
		if (call SendOneHopReply.send(OneHopReplyNode, &pkt, sizeof(one_hop_reply_msg_t)) == SUCCESS)
		{
			sendStartTime = call LocalTime.get();
			
			BUSY = TRUE;
		}
	}
	
			
	task void TaskSendREP()////////////////////////////Need to Include Metric Selection and Time Delay
	{
		REP* rpkt = (REP*)(call REPPacket.getPayload(&pkt, sizeof(REP)));
		
		if (rpkt == NULL)
		{
			return;
		}
		
		rpkt->is_next_hop = TOS_NODE_ID;
		
		if (call SendREP.send(SourceNode, &pkt, sizeof(REP)) == SUCCESS)
		{
			sendStartTime = call LocalTime.get();
			
			BUSY = TRUE;
		}
	}
	
    uint8_t BatteryVoltage = 3;

	task void TaskMetricCalculation()
	{		
		double etx = 0.00;
				
		double ReceptionPower = 0.00; 
		double ReceiveCurrentDraw = 0.016;//Receive Mode
		
		
		ActiveCurrentDraw = 0.008;//8mA Active Mode; 8uA Sleep Mode
		
		
				
		PRR = (float)( REQacknowledged / ( REQacknowledged + REQLostPackets ) );
						
		etx = ( min( (1/PRR) , NretxMax ) ) * PowerLevel;
		ReceptionPower = ReceiveCurrentDraw * BatteryVoltage;
		PowerLevel = ActiveCurrentDraw * BatteryVoltage;			
		
		
		CV_uD = ( BatteryLevel + ( ForwardTime * HarvestingRate ) - (PacketN * PacketL * etx) - (ReceptionPower * ForwardTime)) / Bmax;
		
		
	}
	
	task void TaskVForwardTime()
	{
		r = REQTimeReceived - REQTimeSent;
		
		ForwardTime = (PacketN * PacketL) / r;
	}
	
    uint8_t j = 0;
    
	task void TaskDistanceCalculation()
	{
		d_uv = sqrt( ( pow(( u_X - SourceXPosition ),2) ) + ( pow (( u_Y - SourceYPosition),2) ) );
		
		
		for (j= 0 ; j < 11; j++)
		{
			if (neighbour_node[j] != SourceNode)
			{
				if (w_X[j] || w_Y[j] != 0)
				{
					d_vw = ( d_vw + sqrt ( ( pow(( w_X[j] - u_X ),2) ) + ( pow (( w_Y[j] - u_Y),2) ) ) / (j+1) );
				}			
			}
		}
		
		j = 0;
		
	}
    
    
    task void TaskSendPLMN()
	{		
		PLMNMsg* PLMNpkt = (PLMNMsg*)(call PLMNPacket.getPayload(&pkt, sizeof(PLMNMsg)));
		
		if (PLMNpkt == NULL)
		{
			return;
		}
		
		PLMNpkt->nodeid = SentNodeID;
		PLMNpkt->counter = counter;
		PLMNpkt->MeasuredSignal = MeasuredSignal;
		PLMNpkt->retransmissions = REQretransmissions;
		
		if (call SendPLMN.send(Next_Hop, &pkt, sizeof(PLMNMsg)) == SUCCESS)
		{
			BUSY = TRUE;
		}		
	}	
		
}
	
	

