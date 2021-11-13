// This file is part of Swift-SocketCAN - (C) Dr. Michael 'Mickey' Lauer <mlauer@vanille-media.de>

#include "socketcan-isotp.h"

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

struct socketcan_isotp {
    int fd;
    struct sockaddr_can addr;
    struct ifreq ifr;
};

int socketcan_isotp_open(const char* iface, __u8 vlc, __u8 padding, SSI* ssi) {

    struct socketcan_isotp* handle = malloc(sizeof(struct socketcan_isotp));

    if ((handle->fd = socket(PF_CAN, SOCK_DGRAM, CAN_ISOTP)) < 0) {
        perror("socket");
        return CAN_UNSUPPORTED;
    }
    strcpy(handle->ifr.ifr_name, iface );
    if (ioctl(handle->fd, SIOCGIFINDEX, &handle->ifr) < 0) {
        perror("ioctl");
        return IFACE_NOT_FOUND;
    }
    struct can_isotp_options opts = {0};
    if (vlc) {
        opts.flags = 0;
        opts.txpad_content = 0;
    } else {
        opts.flags = CAN_ISOTP_TX_PADDING;
        opts.txpad_content = padding;
    }
    if (setsockopt(handle->fd, SOL_CAN_ISOTP, CAN_ISOTP_OPTS, &opts, sizeof(opts)) < 0) {
        perror("setsockopt");
        return IFACE_NOT_CAN;
    }

    memset(&handle->addr, 0, sizeof(handle->addr));
    handle->addr.can_family = AF_CAN;
    handle->addr.can_ifindex = handle->ifr.ifr_ifindex;
    handle->addr.can_addr.tp.rx_id = 0x7E0; // just for testing
    handle->addr.can_addr.tp.tx_id = 0x7E8; // just for testing
    if (bind(handle->fd, (struct sockaddr *)&handle->addr, sizeof(handle->addr)) < 0) {
        perror("bind");
        return IFACE_NOT_CAN;
    }

    if (ssi) {
        *ssi = handle;
    }
    return 0;
}

int socketcan_isotp_set_arbitration(SSI ssi, canid_t requestId, canid_t replyId) {
    ssi->addr.can_addr.tp.tx_id = requestId;
    ssi->addr.can_addr.tp.rx_id = replyId;
    if (bind(ssi->fd, (struct sockaddr *)&ssi->addr, sizeof(ssi->addr)) < 0) {
        perror("bind");
        return IFACE_NOT_CAN;
    }
    return 0;
}

int socketcan_isotp_write(SSI ssi, const unsigned char* const data, __u16 count) {
    int nbytes = write(ssi->fd, data, count);
    if (nbytes < 0) {
        perror("write");
        return -1;
    }
    return nbytes;
}

int socketcan_isotp_read(SSI ssi, unsigned char* data, struct timeval* tv, int timeout) {
    if (timeout) {
        struct timeval tvTimeout = {
            .tv_sec = timeout / 1000,
            .tv_usec = (timeout % 1000) * 1000,
        };
        fd_set rfds;
        FD_ZERO(&rfds);
        FD_SET(ssi->fd, &rfds);
        int result = select(ssi->fd + 1, &rfds, NULL, NULL, &tvTimeout);
        if (result == -1) {
            perror("select");
            return READ_ERROR;
        } else if (result == 0) {
            return TIMEOUT;
        }
    };
    int nbytes = read(ssi->fd, data, 4096);
    if (nbytes < 0) {
        perror("Read");
        return READ_ERROR;
    }
    if (tv) {
        int res = ioctl(ssi->fd, SIOCGSTAMP, tv);
        if (res < 0) {
            gettimeofday(tv, 0);
        }
    }
    return nbytes;
}

void socketcan_isotp_close(SSI ssi) {
    if (ssi->fd >= 0) {
        close(ssi->fd);
    }
}