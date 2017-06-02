RUNTIME=300
echo "Runtime is" $RUNTIME "seconds for linpack and memsweep each!"
sh linpack.sh &
TASK_PID=$!
sleep $RUNTIME
kill $TASK_PID
