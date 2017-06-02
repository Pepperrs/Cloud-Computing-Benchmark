RUNTIME=300
echo "Runtime is" $RUNTIME "seconds for linpack and memsweep each!"
sh linpack.sh & > linpack_results.txt
#TASK_PID=$!
#sleep $RUNTIME
#kill $TASK_PID
sh memsweep.sh > memsweep_results.txt
