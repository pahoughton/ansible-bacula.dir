#!/bin/bash
# 2015-06-17 (cc) <paul4hough@gmail.com>
#
status=0
echo -n exists /etc/bacula/bacula-dir.conf:
if [ -f /etc/bacula/bacula-dir.conf ] ; then
  echo pass
else
  echo FAIL
  status=1
fi

echo -n running service bacual-dir:
if service bacula-dir status ; then
  echo pass
else
  echo FAIL
  status=1
fi
exit $status
