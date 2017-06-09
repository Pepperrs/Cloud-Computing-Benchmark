#!/bin/bash
set -e # exit on error

host=$1

run_remote() {
  local cmd=$1
  echo $cmd
  ssh -o ForwardAgent=yes ubuntu@$host "${cmd}"
}

run_remote "if [ -e Cloud-Computing-Benchmark ]; then rm -rf Cloud-Computing-Benchmark; fi"
run_remote "ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts"
run_remote "git clone git@github.com:Pepperrs/Cloud-Computing-Benchmark.git"
run_remote "cd Cloud-Computing-Benchmark && git fetch && git checkout remote_benchmarking"

# run benchmarks and collect results
run_remote "cd Cloud-Computing-Benchmark && sudo ./benchmark.sh"

# collect results
git_email=$(git config user.email)
git_user=$(git config user.user)
git_opts="-c user.email=${git_email} -c user.user=${git_user}"
run_remote "cd Cloud-Computing-Benchmark && git ${git_opts} commit -a -m'adding results'"
run_remote "cd Cloud-Computing-Benchmark && git push origin master"
