TEST=$(basename "${0%.sh}")
OUTPUT=$(realpath $(dirname $0))/output
OUT=$OUTPUT/$TEST.out
EOUT=$OUTPUT/$TEST.eout
LOG=$OUTPUT/$TEST.log
LOBO="./lobo-vm-sim.py"
PYTHON=`which python3`

test "tests" != "$(basename $(dirname $(realpath $0)))" && { echo "FAIL: $0 not in 'tests'"; exit 1; }
! test -f $LOBO && { echo "FAIL: $LOBO must exist"; exit 2; }
mkdir -p $OUTPUT
rm -f $OUT $EOUT
#
# Behavior tested: Tests that when an eviction happens the evicted page does have present cleared 
# and not re-accessible until it is loaded back in
#

#
# Test Case
#
cat >$LOG << 'EOF'
Description:
---
Testing evicted pages aren't reaccessible until loaded back in.
Command: 
---
python3 ./lobo-vm-sim.py -s 0 -a 32 -P 8 -C 2 -p FIFO -A 6,10,6,10,18,6,6,10
---
EOF

$PYTHON $LOBO -s 0 -a 32 -P 8 -C 2 -p FIFO -A 6,10,6,10,18,6,6,10 >$OUT 2>&1

#
# Expected output
#
cat >$EOUT << 'EOF'
ARG address space size 32
ARG page size 8
ARG frames 2
ARG policy FIFO
ARG addresses 6,10,6,10,18,6,6,10

VA 0x00000006 VPN    0 offset 0x0006 PAGEFAULT -> PFN   0 PA 0x00000006 Replaced:-
VA 0x0000000a VPN    1 offset 0x0002 PAGEFAULT -> PFN   1 PA 0x0000000a Replaced:-
VA 0x00000006 VPN    0 offset 0x0006 HIT -> PFN   0 PA 0x00000006 Replaced:-
VA 0x0000000a VPN    1 offset 0x0002 HIT -> PFN   1 PA 0x0000000a Replaced:-
VA 0x00000012 VPN    2 offset 0x0002 PAGEFAULT -> PFN   0 PA 0x00000002 Replaced:0
VA 0x00000006 VPN    0 offset 0x0006 PAGEFAULT -> PFN   1 PA 0x0000000e Replaced:1
VA 0x00000006 VPN    0 offset 0x0006 HIT -> PFN   1 PA 0x0000000e Replaced:-
VA 0x0000000a VPN    1 offset 0x0002 PAGEFAULT -> PFN   0 PA 0x00000002 Replaced:2

FINALSTATS hits 3 faults 5 hitrate 37.50
EOF
#
# Analyze results
#
diff $EOUT $OUT >> $LOG
echo "---------" >> $LOG

diff $EOUT $OUT >/dev/null && echo "PASS $TEST" || echo "FAIL $TEST"
