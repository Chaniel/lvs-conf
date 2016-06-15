#!/bin/bash
#

VIP=192.168.0.30
# cluster port
CPORT=80

# realserver port
RPORT=80
# lvs type m|g|t
TYPE=g
FAIL_BACK=127.0.0.1

# real server
RS=(192.168.0.21 192.168.0.22)

# real server status, 1 => online, 0 => offline.
RSTATUS=(1 1)

# real server weight
RW=(2 1)

function add() {
    ipvsadm -a -t $VIP:$CPORT -r $1:$RPORT -$TYPE -w $2
    [ $? -eq 0 ] && return 0 || return 1
}

function del() {
    ipvsadm -d -t $VIP:$CPORT -r $1:$RPORT
    [ $? -eq 0 ] && return 0 || return 1
}


while true; do
    let COUNT=0
    for I in ${RS[*]}; do
        if curl --connect-timeout 1 http://$I &> /dev/null; then 
            if [ ${RSTATUS[$COUNT]} -eq 0 ]; then
                add $I ${RW[$COUNT]} 
                [ $? -eq 0 ] && RSTATUS[$COUNT]=1
              fi
    
        else
            if [ ${RSTATUS[$COUNT]} -eq 1 ]; then
                del  $I
                [ $? -eq 0 ] && RSTATUS[$COUNT]=0
            fi
        fi 
        let COUNT++
        echo $COUNT
    done
    sleep 5
done
