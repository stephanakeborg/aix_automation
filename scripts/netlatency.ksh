#!/bin/ksh
usage () {
MESSAGE=$*
echo $0 -i INTERFACE -d dest_ip [ -c nb_packet ]
exit 3
}
tcpdump_latency () {
INTERFACE=$1
DEST_HOST=$2
COUNT=`echo "$3 * 2" | bc`
tcpdump -c$COUNT -tti $INTERFACE icmp and host $DEST_HOST 2>/dev/null | awk '
BEGIN { print "" }
/echo request/ { REQUEST=$1 ; SEQUENCE=$12 }
/echo reply/ && $12==SEQUENCE { COUNT=COUNT+1 ; REPLY=$1 ; LATENCY=(REPLY-REQUEST)*1000 ;
SUM=SUM+LATENCY ; print "Latency Packet " COUNT " : " LATENCY " ms"}
END { print ""; print "Average latency (RTT): " SUM/COUNT " ms" ; print""}
' &
}
COUNT=10
while getopts ":i:d:c:" opt
do
case $opt in
i) INTERFACE=${OPTARG} ;;
d) DEST_HOST=${OPTARG} ;;
c) COUNT=${OPTARG} ;;
\?) usage USAGE
return 1
esac
done
##########################
# TEST Variable
[ -z "$INTERFACE" ] && usage "ERROR: specify INTERFACE"
[ -z "$DEST_HOST" ] && usage "ERROR: specify Host IP to ping"
############################
# MAIN
tcpdump_latency $INTERFACE $DEST_HOST $COUNT
sleep 1
OS=`uname`
case "$OS" in
AIX) ping -f -c $COUNT -o $INTERFACE $DEST_HOST > /dev/null ;;
Linux) ping -A -c$COUNT -I $INTERFACE $DEST_HOST > /dev/null ;;
\?) echo "OS $OS not supported" ;exit 1
esac
exit 0
