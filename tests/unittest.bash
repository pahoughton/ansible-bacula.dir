#!/bin/bash
# 2015-06-01 (cc) <paul4hough@gmail.com>
#
# FIXME - need a lock step for renaming vm
#
[ -n "$DEBUG" ] && set -x
targs="$0 $@"
# cfg
guestname=r7j_ansible_bacula_dir
guestnum=24
baseimg="/var/lib/libvirt/images/r7test-base.qcow2"
imgfn="`pwd`/r7test.qcow2"
ssh_opts="-i r7t_jenkins.id -o StrictHostKeyChecking=no"

function Dbg {
  [ -n "$DEBUG" ] && echo $@
}

function Die {
  echo Error - $? - $@
  virsh shutdown $guestname
  chmod 644 r7t_jenkins.id
  exit 1
}
#DoOrDie
function DoD {
  $@ || Die $@
}

if [ -z "$REUSE" ] ; then
  echo $imgfn
  DoD cp "$baseimg" "$imgfn"
  DoD chmod +w "$imgfn"
  DoD chmod 600 r7t_jenkins.id

  sed  \
    -e "s~%imgfn%~$imgfn~g" \
    -e "s~%guestname%~$guestname~g" \
    -e "s~%guestnum%~$guestnum~g" \
    r7test.xml.tmpl > r7test.xml
fi

DoD virsh create r7test.xml
  sleep 10

vgip=`cat $testname.vgip`
while [ -z "$vgip" ]; do
  vgip=`awk -e '/r7jenkins/ {print $3}' /var/lib/libvirt/dnsmasq/default.leases`
  if [ -n "$vgip" ] ; then
    echo $testname > hostname
    echo $vgip > $testname.vgip
    DoD scp $ssh_opts hostname root@$vgip:/etc/hostname
    ssh $ssh_opts root@$vgip shutdown -r now
    sleep 40
    # make sure our new host name has come up.
    DoD grep $guestname /var/lib/libvirt/dnsmasq/default.leases > /dev/null

    # config node with ansible
    cat <<EOF  > unittest.inv
[unittest]
$vgip          ansible_ssh_private_key_file=`pwd`/r7t_jenkins.id
EOF
    break;
  fi
  let tcnt=tcnt+1
  if [ $tcnt -gt 5 ] ; then exit 1; fi
done

aparg=
if [ -n "$DEBUG" ] ; then aparg='-v' ; fi
DoD ansible-playbook $aparg -i unittest.inv unittest.yml

# guest specific tests
DoD ssh $ssh_opts root@$vgip bash unittest.guest.bash

# cleanup
DoD virsh shutdown $testname
chmod 644 r7t_jenkins.id
echo $targs complete.
exit 0
