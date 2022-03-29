#!/bin/bash

set +x # not verbose
set -e # fail on error

scrdir=$(cd $(dirname $0); pwd)
bckend=$(basename $(cd $scrdir; cd ..; pwd)) # cudacpp or alpaka
topdir=$(cd $scrdir; cd ../../..; pwd)

function usage()
{
  echo "Usage: $0 <processes [-eemumu][-ggtt][-ggttg][-ggttgg][-ggttggg]> [-clean]"
  exit 1
}

##########################################################################
# PART 0 - decode command line arguments
##########################################################################

eemumu=0
ggtt=0
ggttg=0
ggttgg=0
ggttggg=0

clean=0

while [ "$1" != "" ]; do
  if [ "$1" == "-eemumu" ]; then
    eemumu=1
    shift
  elif [ "$1" == "-ggtt" ]; then
    ggtt=1
    shift
  elif [ "$1" == "-ggttg" ]; then
    ggttg=1
    shift
  elif [ "$1" == "-ggttgg" ]; then
    ggttgg=1
    shift
  elif [ "$1" == "-ggttggg" ]; then
    ggttggg=1
    shift
  elif [ "$1" == "-clean" ]; then
    clean=1
    shift
  else
    usage
  fi
done
###exit 1

# Check that at least one process has been selected
if [ "${eemumu}" == "0" ] && [ "${ggtt}" == "0" ] && [ "${ggttg}" == "0" ] && [ "${ggttgg}" == "0" ] && [ "${ggttggg}" == "0" ]; then usage; fi

suffs=".madonly/"

##########################################################################
# PART 1 - build and run madevent
##########################################################################

for suff in $suffs; do

  if [ "${eemumu}" == "1" ]; then 
    dir=$topdir/epochX/${bckend}/ee_mumu${suff}SubProcesses/P1_epem_mupmum
  elif [ "${ggtt}" == "1" ]; then 
    dir=$topdir/epochX/${bckend}/gg_tt${suff}SubProcesses/P1_gg_ttx
  elif [ "${ggttg}" == "1" ]; then 
    dir=$topdir/epochX/${bckend}/gg_ttg${suff}SubProcesses/P1_gg_ttxg
  elif [ "${ggttgg}" == "1" ]; then 
    dir=$topdir/epochX/${bckend}/gg_ttgg${suff}SubProcesses/P1_gg_ttxgg
  elif [ "${ggttggg}" == "1" ]; then 
    dir=$topdir/epochX/${bckend}/gg_ttggg${suff}SubProcesses/P1_gg_ttxggg
  fi

  ##########################################################################
  # PART 1a - build
  ##########################################################################

  cd $dir/../../Source
  if [ "${clean}" == "1" ]; then make clean; echo; fi
  make
  cd $dir
  make

  ##########################################################################
  # PART 1b - run madevent
  ##########################################################################

  # Disable OpenMP multithreading in Fortran
  export OMP_NUM_THREADS=1

  # Pattern to filter
  ###pattern='$' # no filter
  pattern='(Number of events|Actual xsec)' # filter pattern
  
  # First execution: this will create results.dat
  cd $dir
  if [ "${clean}" == "1" ]; then \rm -f results.dat; fi
  if [ ! -f results.dat ]; then
    echo -e "\n*** EXECUTE MADEVENT (create results.dat) ***"
    time ./madevent < ${scrdir}/input_app_100k.txt | grep -E "${pattern}"
  fi
  # Second execution: this will read results.dat and create events.lhe
  echo -e "\n*** EXECUTE MADEVENT (create events.lhe) ***"
  time ./madevent < ${scrdir}/input_app_100k.txt | grep -E "${pattern}"
  
done

