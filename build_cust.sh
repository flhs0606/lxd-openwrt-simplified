#!/bin/sh
set -e
export LC_ALL=C
ver=$(basename "$1"|cut -d'-' -f 2)
dist=$(basename "$1"|cut -d'-' -f 1)
type=$2
usage() {
	echo "Usage: $0 <rootfs tarball> <lxd|plain> "
	exit 1
}
if [ "$type" != plain ] && [ "$type" != lxd ] ; then
usage
exit 1
fi
revision=$(basename "$1"|cut -d'-' -f 3-4)
rootfs="$1"
arch_lxd="$(tar xf "$rootfs" ./etc/openwrt_release -O|grep DISTRIB_ARCH|sed -e "s/.*='\(.*\)'/\1/")"
if [ ! "$arch_lxd" ]; then
echo "Unknown CPU arch. Possible an invalid OpenWRT rootfs tarball. Failed."
exit 1
fi 
tarball=bin/${dist}-${ver}-${revision}-${arch_lxd}-${type}.tar.gz
metadata=bin/metadata.yaml
build_tarball() {
	local opts=""
	if test "${type}" = lxd; then
		opts="$opts -m $metadata"
	fi
	local cmd=""
	cmd="scripts/build_rootfs_cs.sh"
	"$cmd" "$rootfs" $opts -o "$tarball" --disable-services="sysfixtime sysntpd led"
}
build_metadata() {
	local desc=""
	desc="$(tar xf "$rootfs" ./etc/openwrt_release -O|grep DISTRIB_DESCRIPTION|sed -e "s/.*='\(.*\)'/\1/")"
	test -e bin || mkdir bin
	cat > $metadata <<EOF
architecture: "$arch_lxd"
creation_date: $(date +%s)
properties:
 architecture: "$arch_lxd"
 description: "$desc"
 os: "$dist"
 release: "$ver"
templates:
EOF
}
build_metadata
build_tarball
echo "Tarball built: $tarball"
