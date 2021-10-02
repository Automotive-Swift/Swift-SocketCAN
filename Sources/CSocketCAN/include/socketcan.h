// This file is part of Swift-SocketCAN - (C) Dr. Michael 'Mickey' Lauer <mlauer@vanille-media.de>

#include <linux/can.h>
#include <linux/can/raw.h>
#include <time.h>

#define CAN_UNSUPPORTED -1
#define IFACE_NOT_FOUND -2
#define IFACE_NOT_CAN   -3
#define READ_ERROR      -4
#define TIMEOUT         -5

typedef struct timeval struct_timeval;

int socketcan_open(const char* iface);
int socketcan_read(int fd, struct can_frame* frame, struct timeval* tv, int timeout);
int socketcan_write(int fd, const struct can_frame* frame);
void socketcan_close(int fd);
