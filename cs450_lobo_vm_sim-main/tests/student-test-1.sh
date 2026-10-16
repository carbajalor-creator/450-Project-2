
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
# Test Case
#
cat > $LOG << 'EOF'
Description:
------------
Test Clock replacement policy with a hit and repeated page replacements.

Command:
--------
python3 ./lobo-vm-sim.py -s 0 -a 32 -P 8 -C 2 -p CLOCK -A 0,8,0,16,8,24,0,16,8
--------
EOF

#
# Test with LOBO
#
$PYTHON $LOBO -s 0 -a 32 -P 8 -C 2 -p CLOCK -A 0,8,0,16,8,24,0,16,8 > $OUT 2>&1

#
# Expected output
#
# Populate EOUT with the verified output from the simulator.
# Check the Clock hand and reference-bit behavior before finalizing.
#
cat > $EOUT << 'EOF'
ARG address space size 32
ARG page size 8
ARG frames 2
ARG policy CLOCK
ARG addresses 0,8,0,16,8,24,0,16,8

VA 0x00000000 VPN    0 offset 0x0000 PAGEFAULT -> PFN   0 PA 0x00000000 Replaced:-
VA 0x00000008 VPN    1 offset 0x0000 PAGEFAULT -> PFN   1 PA 0x00000008 Replaced:-
VA 0x00000000 VPN    0 offset 0x0000 HIT -> PFN   0 PA 0x00000000 Replaced:-
VA 0x00000010 VPN    2 offset 0x0000 PAGEFAULT -> PFN   1 PA 0x00000008 Replaced:1
VA 0x00000008 VPN    1 offset 0x0000 PAGEFAULT -> PFN   0 PA 0x00000000 Replaced:0
VA 0x00000018 VPN    3 offset 0x0000 PAGEFAULT -> PFN   1 PA 0x00000008 Replaced:2
VA 0x00000000 VPN    0 offset 0x0000 PAGEFAULT -> PFN   0 PA 0x00000000 Replaced:1
VA 0x00000010 VPN    2 offset 0x0000 PAGEFAULT -> PFN   0 PA 0x00000000 Replaced:0
VA 0x00000008 VPN    1 offset 0x0000 PAGEFAULT -> PFN   0 PA 0x00000000 Replaced:2

FINALSTATS hits 1 faults 8 hitrate 11.11
EOF

#
# Analyze results
#
diff $EOUT $OUT >> $LOG
echo "---------" >> $LOG

diff $EOUT $OUT >/dev/null && echo "PASS $TEST" || echo "FAIL $TEST"