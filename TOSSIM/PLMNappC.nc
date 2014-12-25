#include <Timer.h>
#include "PLMN.h"


configuration PLMNappC{
}
implementation{
	
	components MainC;
	components PLMNC as App;
	
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
	
	components LocalTimeMilliC;
	
	components ActiveMessageC;
	
	components new AMSenderC(AM_REQ) as SendREQ;
	components new AMSenderC(AM_ONE_HOP_MSG) as SendOneHop;
	components new AMSenderC(AM_ONE_HOP_REPLY_MSG) as SendOneHopReply;	
	components new AMSenderC(AM_REP) as SendREP;
	components new AMSenderC(AM_PLMN) as SendPLMN;
	
	components LedsC;
	
	components new AMReceiverC(AM_INITIALIZATION_MSG) as InitializationReceiver;
	components new AMReceiverC(AM_REQ) as REQReceiver;	
	components new AMReceiverC(AM_ONE_HOP_MSG) as OneHopReceiver;
	components new AMReceiverC(AM_ONE_HOP_REPLY_MSG) as OneHopReplyReceiver;	
	components new AMReceiverC(AM_REP) as REPReceiver;
	components new AMReceiverC(AM_PLMN) as PLMNReceiver;
	
	
	
	App.Boot -> MainC;
	App.PeriodicMonitoring -> Timer0;
	App.Timer1 -> Timer1;
	App.LocalTime -> LocalTimeMilliC;
	
	App.AMControl -> ActiveMessageC;
	
	App.SendREQ -> SendREQ;
	App.REQPacket -> SendREQ;
	App.REQAMPacket -> SendREQ;
	
	App.SendOneHop -> SendOneHop;
	App.OneHopPacket -> SendOneHop;
	App.OneHopAMPacket -> SendOneHop;
	
	App.SendOneHopReply -> SendOneHopReply;
	App.OneHopReplyPacket -> SendOneHopReply;
	App.OneHopReplyAMPacket -> SendOneHopReply;
	
	App.SendREP -> SendREP;
	App.REPPacket -> SendREP;
	App.REPAMPacket -> SendREP;
	
	App.SendPLMN -> SendPLMN;
	App.PLMNPacket -> SendPLMN;
	App.PLMNAMPacket -> SendPLMN;
		
		
	
	App.PacketAck -> ActiveMessageC;
	
	//App.BatteryVoltage -> Battery;
	
	App.Leds -> LedsC;
	
	App.InitializationReceiver -> InitializationReceiver;
	App.REQReceiver -> REQReceiver;
	App.OneHopReceiver -> OneHopReceiver;
	App.OneHopReplyReceiver -> OneHopReplyReceiver;
	App.REPReceiver -> REPReceiver;
	App.PLMNReceiver -> PLMNReceiver;
	
	
}
