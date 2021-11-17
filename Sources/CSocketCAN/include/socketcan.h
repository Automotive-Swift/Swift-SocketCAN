// This file is part of Swift-SocketCAN - (C) Dr. Michael 'Mickey' Lauer <mlauer@vanille-media.de>
#ifndef SWIFT_SOCKETCAN_H
#define SWIFT_SOCKETCAN_H

#include "common.h"

#include <linux/can.h>
#include <linux/can/raw.h>
#include <time.h>

typedef struct timeval struct_timeval;

int socketcan_open(const char* iface, int bitrate);
int socketcan_read(int fd, struct can_frame* frame, struct timeval* tv, int timeout);
int socketcan_write(int fd, const struct can_frame* frame);
void socketcan_close(int fd);

#endif //SWIFT_SOCKETCAN_H
