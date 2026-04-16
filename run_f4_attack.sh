# F4attack-changes: Added complete script to set party inputs, run all parties, and then print their output using appropriate formatting

# Check for empty arguments
if [ $# -eq 0 ]; then
  echo Usage: ./run_f4_attack.sh [P3 input: int]
  echo e.g., ./run_f4_attack.sh 42
  exit 1
fi

# Set inputs:
echo P0 inputs a = 4
echo 4 > Player-Data/Input-P0-0
echo P1 inputs b = 8
echo 8 > Player-Data/Input-P1-0
echo P3 inputs d = $1
echo $1 > Player-Data/Input-P3-0
echo

# Run all parties, let them print cout and cerr to log files:
echo Starting P0, P1, P2, P3 ...
$(./rep4-ring-party.x 0 attackable_demo_circuit -pn 19517 -h localhost > log_p0.txt 2>&1) &
pid0=$!
$(./rep4-ring-party.x 1 attackable_demo_circuit -pn 19517 -h localhost > log_p1.txt 2>&1) &
pid1=$!
$(./rep4-ring-party.x 2 attackable_demo_circuit -pn 19517 -h localhost > log_p2.txt 2>&1) &
pid2=$!
$(./rep4-ring-party.x 3 attackable_demo_circuit -pn 19517 -h localhost > log_p3.txt 2>&1) &
pid3=$!
# Wait until all parties finish
wait $pid0
wait $pid1
wait $pid2
wait $pid3
echo P1, P2, P3, P4 finished
echo

# Print all outputs
echo '######## P0 output ########'
echo '## (this ends with an error/crash, either due to an hash-mismatch'
echo '## caused by P2 cheating, or by loosing connection to another'
echo '## party that detected a hash-mismatch)'
cat log_p0.txt
echo
echo '######## P1 output ########'
echo '## (this ends with an error/crash, either due to an hash-mismatch'
echo '## caused by P2 cheating, or by loosing connection to another'
echo '## party that detected a hash-mismatch)'
cat log_p1.txt
echo
echo '######## P2 output ########'
echo '## (this ends with an error/crash, either due to an hash-mismatch'
echo '## caused by P2 cheating, or by loosing connection to another'
echo '## party that detected a hash-mismatch)'
cat log_p2.txt
echo
echo '######## P3 output ########'
echo '## (this ends with an error/crash, either due to an hash-mismatch'
echo '## caused by P2 cheating, or by loosing connection to another'
echo '## party that detected a hash-mismatch)'
cat log_p3.txt
echo

echo '######################'
echo '### Attack Summary ###'
echo '######################'
echo '# All parties abort due to failing consistency checks caused by cheating:'
echo '# (In MP-SPDZ, an aborting party simply crashes, either directly due to a'
echo '# hash mismatch or loosing connection to another aborting party)'
echo "P0 error: $(sed -n '$p' log_p0.txt)"
echo "P1 error: $(sed -n '$p' log_p1.txt)"
echo "P2 error: $(sed -n '$p' log_p2.txt)"
echo "P3 error: $(sed -n '$p' log_p3.txt)"
echo
echo '# P3 gave input:'
echo d = $1
echo '# Malicious P2 cheated, made a guess for d and checked if correct:'
sed -n -e 3p -e 4p -e 6p log_p2.txt
echo
echo '# (scroll up for full CLI output of each party)'

# end of F4attack-changes
