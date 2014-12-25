#ifndef PLMN_H
#define PLMN_H


enum
{
	AM_PLMN = 6,
	AM_INITIALIZATION_MSG = 8,
	AM_ONE_HOP_MSG = 9,
	AM_ONE_HOP_REPLY_MSG = 7,
	AM_REQ = 5,
	AM_REP = 4,
//	AM_LOCATIONMSG = 12,
	TIMER_PERIODIC_MILLI_0 = 5240, 
	TIMER_PERIODIC_MILLI_1 = 5240
};

//enum  //*******************************Sub-stations have pre-determined locations***************************//
//{
//	D_X = 0,  //***********************Sub-station location (0,0)*****************************//
//	D_Y = 0,
//};

typedef nx_struct initialization_msg
{
	nx_uint16_t UX;
	nx_uint16_t UY;
	nx_uint16_t DX;
	nx_uint16_t DY;
	nx_uint16_t ReplenishmentRate;
}initialization_msg_t;


typedef nx_struct PLMNMsg
{
	nx_uint16_t nodeid;
	nx_uint16_t counter;
	nx_uint16_t MeasuredSignal;
	nx_uint16_t retransmissions;
}PLMNMsg;

typedef nx_struct REQ
{
	nx_uint16_t N;
	nx_uint16_t L;
	nx_uint16_t uXPosition;
	nx_uint16_t uYPosition;
	nx_uint16_t DXPosition;
	nx_uint16_t DYPosition;
	nx_uint32_t REQTime;
	nx_uint16_t CurrentNode;
	nx_uint16_t Acknowledged;
	nx_uint16_t LostPackets;
}REQ;

typedef nx_struct REP
{
	nx_uint16_t is_next_hop;
}REP;

typedef nx_struct one_hop_msg
{
	nx_uint16_t v_node;	
	nx_uint16_t Acknowledged;
	nx_uint16_t LostPackets;
}one_hop_msg_t;

typedef nx_struct one_hop_reply_msg
{
	nx_uint16_t W_node;
	nx_uint16_t WX;
	nx_uint16_t WY;
}one_hop_reply_msg_t;



#endif /* PLMN_H */
