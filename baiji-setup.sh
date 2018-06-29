#!/bin/sh -

dn="$(mktemp -d)"

trap "rm -rf $dn" 0

fakeroot /usr/sbin/debootstrap --foreign --variant=buildd jessie $dn

fakeroot tar -C $dn -c . | docker import - baiji:jessie

docker build -t baiji:jessie - <<-'EOF'
	FROM baiji:jessie
	RUN sed -i '/mount -t proc /d; /mount -t sysfs /d' /debootstrap/functions && /debootstrap/debootstrap --second-stage
	RUN apt-get update && apt-get install -y --no-install-recommends build-essential fakeroot git
EOF
