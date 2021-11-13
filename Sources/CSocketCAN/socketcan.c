// This file is part of Swift-SocketCAN - (C) Dr. Michael 'Mickey' Lauer <mlauer@vanille-media.de>

#include "socketcan.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>

#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/time.h>

#include <linux/sockios.h>

int socketcan_open(const char* iface) {

    int fd;
    if ((fd = socket(PF_CAN, SOCK_RAW, CAN_RAW)) < 0) {
       perror("Socket");
       return CAN_UNSUPPORTED;
    }
    struct sockaddr_can addr;
    struct ifreq ifr;

    strcpy(ifr.ifr_name, iface );
    if (ioctl(fd, SIOCGIFINDEX, &ifr) < 0) {
        perror("ioctl");
        return IFACE_NOT_FOUND;
    }

    memset(&addr, 0, sizeof(addr));
    addr.can_family = AF_CAN;
    addr.can_ifindex = ifr.ifr_ifindex;

    if (bind(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("Bind");
        return IFACE_NOT_CAN;
    }

    /*
    int flags = fcntl(fd, F_GETFL);
    fcntl(fd, F_SETFL, flags | O_NONBLOCK);
    */
    return fd;
}

int socketcan_read(int fd, struct can_frame* frame, struct timeval* tv, int timeout) {
    if (timeout) {
        struct timeval tvTimeout = {
            .tv_sec = timeout / 1000,
            .tv_usec = (timeout % 1000) * 1000,
        };
        fd_set rfds;
        FD_ZERO(&rfds);
        FD_SET(fd, &rfds);
        int result = select(fd + 1, &rfds, NULL, NULL, &tvTimeout);
        if (result == -1) {
            perror("select");
            return READ_ERROR;
        } else if (result == 0) {
            return TIMEOUT;
        }
    };
    int nbytes = read(fd, frame, sizeof(struct can_frame));
    if (nbytes < 0) {
        perror("Read");
        return READ_ERROR;
    }
    if (tv) {
        int res = ioctl(fd, SIOCGSTAMP, tv);
        if (res < 0) {
            gettimeofday(tv, 0);
        }
    }
    return nbytes;
}

int socketcan_write(int fd, const struct can_frame* frame) {
    int nbytes = write(fd, frame, sizeof(struct can_frame));
    if (nbytes < 0) {
        perror("Write");
        return -1;
    }
    return nbytes;
}

void socketcan_close(int fd) {
    close(fd);
}