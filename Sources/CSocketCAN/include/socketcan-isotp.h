// This file is part of Swift-SocketCAN - (C) Dr. Michael 'Mickey' Lauer <mlauer@vanille-media.de>
#ifndef SWIFT_SOCKETCAN_ISOTP_H
#define SWIFT_SOCKETCAN_ISOTP_H

#include <linux/can.h>
#include <linux/can/raw.h>
#include <linux/can/isotp.h>
#include <time.h>

#define CAN_UNSUPPORTED -1
#define IFACE_NOT_FOUND -2
#define IFACE_NOT_CAN   -3
#define READ_ERROR      -4
#define TIMEOUT         -5

typedef struct timeval struct_timeval;

int socketcan_isotp_open(const char* iface);
int socketcan_isotp_read(int fd, unsigned char*, struct timeval* tv, int timeout);
int socketcan_isotp_write(int fd, const struct can_frame* frame);
void socketcan_close(int fd);

#endif //SWIFT_SOCKETCAN_ISOTP_H
