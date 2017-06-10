#!/bin/bash -e

tempfile=$1

if [[ $tempfile == '' ]]; then
  tempfile=/tmp/benchmarking_testfile
fi

printf 'sequential write: '
# write 1GB data and print throughput
dd if=/dev/zero of=$tempfile bs=1M count=1024 conv=fdatasync,notrunc \
  2>&1 | tail -n 1 | awk '{split($0,a,", "); print a[4]}'

printf 'sequential read (w/o cache): '
# drop buffer caches
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
dd if=$tempfile of=/dev/null bs=1M count=1024 \
  2>&1 | tail -n 1 | awk '{split($0,a,", "); print a[4]}'
printf 'sequential read (w cache): '
dd if=$tempfile of=/dev/null bs=1M count=1024 \
  2>&1 | tail -n 1 | awk '{split($0,a,", "); print a[4]}'

rm $tempfile

printf 'random write: '
fio --rw=randwrite --name=test --size=1024M --direct=1 --bs=1024k --output-format=terse \
  | awk '{split($0,a,";"); print a[48] " KB/s"}'

printf 'random read: '
fio --rw=randread --name=test --size=1024M --direct=1 --bs=1024k --output-format=terse \
  | awk '{split($0,a,";"); print a[7] " KB/s"}'
