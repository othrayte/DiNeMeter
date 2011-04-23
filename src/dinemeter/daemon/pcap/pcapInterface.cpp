#include <stdlib.h>
#include <string.h>
#define IMPLEMENT_API
#define NEKO_WINDOWS
#define WINDOWS
#include <hx/CFFI.h>
#include <iostream>
#include <errno.h>
#include <winsock2.h>

/*
 *  This file is part of WebMonitorDaemon.
 *
 *  WebMonitorDaemon is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  any later version.
 *
 *  WebMonitorDaemon is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with WebMonitorDaemon.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * @author Adrian Cowan (Othrayte)
 */
 
 
#define MAX_PACKET_SIZE 65535
#define GROUP_PACKETS_TO_MS 10
#define NUM_PACKETS -1
#define SIZE_ETHERNET 14

/* Ethernet addresses are 6 bytes */
#define ETHER_ADDR_LEN	6

#define IP_HL(ip)               (((ip)->ip_vhl) & 0x0f)

#include <pcap.h>

extern "C" {

void got_packet(u_char * args, const struct pcap_pkthdr * header, const u_char * packet);




/* Ethernet header */
struct sniff_ethernet {
        u_char  ether_dhost[ETHER_ADDR_LEN];    /* destination host address */
        u_char  ether_shost[ETHER_ADDR_LEN];    /* source host address */
        u_short ether_type;                     /* IP? ARP? RARP? etc */
};

/* IP header */
struct sniff_ip {
        u_char  ip_vhl;                 /* version << 4 | header length >> 2 */
        u_char  ip_tos;                 /* type of service */
        u_short ip_len;                 /* total length */
        u_short ip_id;                  /* identification */
        u_short ip_off;                 /* fragment offset field */
        #define IP_RF 0x8000            /* reserved fragment flag */
        #define IP_DF 0x4000            /* dont fragment flag */
        #define IP_MF 0x2000            /* more fragments flag */
        #define IP_OFFMASK 0x1fff       /* mask for fragmenting bits */
        u_char  ip_ttl;                 /* time to live */
        u_char  ip_p;                   /* protocol */
        u_short ip_sum;                 /* checksum */
        struct  in_addr ip_src,ip_dst;  /* source and dest address */
};
#define IP_HL(ip)               (((ip)->ip_vhl) & 0x0f)
#define IP_V(ip)                (((ip)->ip_vhl) >> 4)

/* TCP header */
typedef u_int tcp_seq;

struct sniff_tcp {
        u_short th_sport;               /* source port */
        u_short th_dport;               /* destination port */
        tcp_seq th_seq;                 /* sequence number */
        tcp_seq th_ack;                 /* acknowledgement number */
        u_char  th_offx2;               /* data offset, rsvd */
#define TH_OFF(th)      (((th)->th_offx2 & 0xf0) >> 4)
        u_char  th_flags;
        #define TH_FIN  0x01
        #define TH_SYN  0x02
        #define TH_RST  0x04
        #define TH_PUSH 0x08
        #define TH_ACK  0x10
        #define TH_URG  0x20
        #define TH_ECE  0x40
        #define TH_CWR  0x80
        #define TH_FLAGS        (TH_FIN|TH_SYN|TH_RST|TH_ACK|TH_URG|TH_ECE|TH_CWR)
        u_short th_win;                 /* window */
        u_short th_sum;                 /* checksum */
        u_short th_urp;                 /* urgent pointer */
};
	


value *f;


value run(value devices, value local, value mask, value callback) {
	char errbuf[PCAP_ERRBUF_SIZE];
	pcap_t *handle;
	struct bpf_program fp;			/* compiled filter program (expression) */
	u_char args[2];
	int i, j;
	int count = val_array_size(devices);
	
	if( !val_is_array(devices)  || !val_is_string(local)|| !val_is_string(mask) || !val_is_function(callback) ) return val_null;
	args[0] = inet_addr(val_string(mask));
	args[1] = inet_addr(val_string(local));
	
	/* prepare the error buffer */
	errbuf[0] = '\0';
	
	/* open capture device */
	pcap_t** handles = (pcap_t**) malloc(sizeof(pcap_t*)*count);
	j=0;
	for (i=0;i<val_array_size(devices);i++) {
		if (!val_is_string(val_array_i(devices,i))) {
			count--;
			continue;
		}
		value device = val_array_i(devices,i);
		
		handles[j] = pcap_open_live(val_string(device), MAX_PACKET_SIZE, false, GROUP_PACKETS_TO_MS, errbuf);
		if (handles[j] == NULL || errbuf[0] != '\0') {
			fprintf(stderr, "Couldn't open device %s: %s\n", val_string(device), errbuf);
			getchar();
			count--;
			continue;
		}

		/* make sure we're capturing on an Ethernet device [2] */
		if (pcap_datalink(handles[j]) != DLT_EN10MB) {
			fprintf(stderr, "%s is not an Ethernet\n", val_string(device));
			count--;
			continue;
		}

		/* compile the filter expression */
		if (pcap_compile(handles[j], &fp, "ip", true, 0) == -1) {
			fprintf(stderr, "Couldn't parse filter %s: %s\n", "ip", pcap_geterr(handle));
			count--;
			continue;
		}

		/* apply the compiled filter */
		if (pcap_setfilter(handles[j], &fp) == -1) {
			fprintf(stderr, "Couldn't install filter %s: %s\n", "ip", pcap_geterr(handle));
			count--;
			continue;
		}
		j++;
	}
	if( f == NULL )
	f = alloc_root();

	*f = callback;
	
	int res, packets;
	struct pcap_pkthdr *header;
	const u_char *pkt_data;
	do {
		for (j=0;j<count;j++){
			for (packets=0;packets<1000;packets++) {
				res = pcap_next_ex(handles[j], &header, &pkt_data);
				if (res != 1) break;
				got_packet(args, header, pkt_data);
			}
			if (res<0) break;
		}
	} while (res>=0);
	
	pcap_freecode(&fp);
	pcap_close(handle);
	free_root(f);
	free(handles);
	return alloc_null();
}

void got_packet(u_char * args, const struct pcap_pkthdr * header, const u_char * packet) {
	int d = 0, u = 0;
	value addr;
	int mask;
	int local;
	int src_remote, dst_remote;

	/* declare pointers to packet headers */
	const struct sniff_ethernet *ethernet;  /* The ethernet header [1] */
	const struct sniff_ip *ip;              /* The IP header */

	int size_ip;

	mask = args[0];
	local = args[1];

	/* define ethernet header */
	ethernet = (struct sniff_ethernet*)(packet);


	/* define/compute ip header offset */
	ip = (struct sniff_ip*)(packet + SIZE_ETHERNET);
	size_ip = IP_HL(ip)*4;
	if (size_ip < 20) {
		printf("   * Invalid IP header length: %u bytes\n", size_ip);
		return;
	}

	src_remote = ((int) (ip->ip_src.s_addr) ^ local) & mask;
	dst_remote = ((int) (ip->ip_dst.s_addr) ^ local) & mask;
	
	if (!src_remote) {
        if (!dst_remote) {
            //printf("Internal\n");
			return;
        } else {
            //printf("Outgoing\n");
            u = header->len;
			addr = alloc_int(ip->ip_dst.s_addr);
        }
	} else {
        if (!dst_remote) {
            //printf("Incoming\n");
            d = header->len;
			addr = alloc_int(ip->ip_src.s_addr);
        } else {
            //printf("External\n");
			return;
        }
	}
	
	if (val_is_function(*f)) val_call3(*f, alloc_int(d), alloc_int(u), addr);
	
	return;
}

value listDevices() {
    pcap_if_t *alldevs;
    pcap_if_t *d;
    int i=0, total=0;
    char errbuf[PCAP_ERRBUF_SIZE];
	value devs;
    
    /* Retrieve the device list from the local machine */
    if (pcap_findalldevs(&alldevs, errbuf) == -1)
    {
        fprintf(stderr,"Error in pcap_findalldevs_ex: %s\n", errbuf);
        exit(EXIT_FAILURE);
    }
	
    for (d = alldevs; d != NULL; d = d->next) total++;
	
	if (total == 0) {
		pcap_freealldevs(alldevs);
		return val_null;
	}
	
	devs = alloc_array(total*2);
	
    for(d = alldevs; d != NULL; d = d->next) {
        val_array_set_i(devs, i++, alloc_string(d->name));
        val_array_set_i(devs, i++, alloc_string(d->description));
    }
	
	pcap_freealldevs(alldevs);
	
	return devs;
}


DEFINE_PRIM(run,4); // function sum with 2 arguments
DEFINE_PRIM(listDevices,0); // function append with 0 arguments


}
