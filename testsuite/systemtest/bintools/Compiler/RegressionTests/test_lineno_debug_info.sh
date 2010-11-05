tcecc=../../../../../tce/src/bintools/Compiler/tcecc
tcedisasm=../../../../../tce/src/bintools/Disassembler/tcedisasm
tpef=/tmp/test_lineno_debug_info.1234werqu802.tpef
adf=../../../../../tce/scheduler/testbench/ADF/huge.adf
$tcecc -g -O0 -a $adf -o $tpef data/lineno.c 2>/dev/null
$tcedisasm -s $adf $tpef | grep "test_function" | grep "# file:"\
 | awk -F# '{ print $2 $3}' | cut -c1-32

rm -f $tpef
