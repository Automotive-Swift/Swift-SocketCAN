// This file is part of Swift-SocketCAN - (C) Dr. Michael 'Mickey' Lauer <mlauer@vanille-media.de>
#ifndef SWIFT_SOCKETCAN_ISOTP_H
#define SWIFT_SOCKETCAN_ISOTP_H

#include "common.h"

#include <linux/can.h>
#include <linux/can/raw.h>
#include <linux/can/isotp.h>
#include <time.h>

typedef struct timeval struct_timeval;
typedef struct socketcan_isotp* SSI;

int socketcan_isotp_open(const char* iface, int bitrate, __u8 vlc, __u8 padding, SSI* ssi);
int socketcan_isotp_configure(SSI ssi, __u8 vlc, __u8 padding);
int socketcan_isotp_read(SSI ssi, unsigned char*, struct timeval* tv, int timeout);
int socketcan_isotp_set_arbitration(SSI ssi, canid_t requestId, canid_t replyId);
int socketcan_isotp_write(SSI ssi, const unsigned char* const data, __u16 count);
void socketcan_isotp_close(SSI ssi);

#endif //SWIFT_SOCKETCAN_ISOTP_H
