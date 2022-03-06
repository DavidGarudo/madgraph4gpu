#!/bin/sh

table=
if [ "$1" == "-hrdcod" ]; then
  table="hrdcod"; shift
elif [ "$1" == "-juwels" ]; then
  table="juwels"; shift
elif [ "$1" == "-alpaka" ]; then
  table="alpaka"; shift
fi
if [ "$1" != "" ]; then echo "Usage: $0 [-hrdcod|-juwels|-alpaka]"; exit 1; fi

cd $(dirname $0)/..

# Output file
if [ "$table" == "" ]; then
  out=tput/summaryTable.txt
else
  out=tput/summaryTable_${table}.txt
fi
\rm -f $out
touch $out

# Select revisions of cudacpp and alpaka logs
crevs=""
arevs=""
if [ "$table" == "" ]; then
  crevs="$crevs 09e482e" # cuda116/gcc102  (03 Mar 2022) BASELINE eemumu/ggtt/ggttgg x f/d x hrd0/hrd1 x inl0/inl1 + ggttg/ggttggg x f/d x hrd0/hrd1 x inl0
  crevs="$crevs 88dc717" # cuda116/icx2022 (03 Mar 2022) ICX TEST eemumu/ggtt/ggttgg x f/d x hrd0/hrd1 x inl0/inl1 + ggttg/ggttggg x f/d x hrd0/hrd1 x inl0
elif [ "$table" == "hrdcod" ]; then
  crevs="$crevs 09e482e" # cuda116/gcc102  (03 Mar 2022) BASELINE eemumu/ggtt/ggttgg x f/d x hrd0/hrd1 x inl0/inl1 + ggttg/ggttggg x f/d x hrd0/hrd1 x inl0
  crevs="$crevs 88dc717" # cuda116/icx2022 (03 Mar 2022) ICX TEST eemumu/ggtt/ggttgg x f/d x hrd0/hrd1 x inl0/inl1 + ggttg/ggttggg x f/d x hrd0/hrd1 x inl0
elif [ "$table" == "juwels" ]; then
  crevs="$crevs 09e482e" # cuda116/gcc102  (03 Mar 2022) BASELINE eemumu/ggtt/ggttgg x f/d x hrd0/hrd1 x inl0/inl1 + ggttg/ggttggg x f/d x hrd0/hrd1 x inl0
  crevs="$crevs 65730b2" # cuda115/gcc112  (18 Feb 2022) JUWELSCL eemumu/ggtt/ggttgg x f/d x inl0/inl1 + ggttg/ggttggg x f/d
  crevs="$crevs df441ad" # cuda115/gcc112  (18 Feb 2022) JUWELSBO eemumu/ggtt/ggttgg x f/d x inl0/inl1 + ggttg/ggttggg x f/d
elif [ "$table" == "alpaka" ]; then
  crevs="$crevs 09e482e" # cuda116/gcc102  (03 Mar 2022) BASELINE eemumu/ggtt/ggttgg x f/d x hrd0/hrd1 x inl0/inl1 + ggttg/ggttggg x f/d x hrd0/hrd1 x inl0
  arevs="$arevs f5a44ba" # cuda116/gcc102  (06 Mar 2022) GOLDEPX4 eemumu/ggtt/ggttg/ggttgg/ggttggg x d x inl0
fi

# Select processes
procs="eemumu ggtt ggttg ggttgg ggttggg"

# Select fptype, helinl, hrdcod
if [ "$table" == "" ]; then
  fpts="d f"
  inls="inl0 inl1"
  hrds="hrd0"
elif [ "$table" == "hrdcod" ]; then
  fpts="d"
  inls="inl0"
  hrds="hrd0 hrd1"
elif [ "$table" == "juwels" ]; then
  fpts="d f"
  inls="inl0 inl1"
  hrds="hrd0"
elif [ "$table" == "alpaka" ]; then
  fpts="d"
  inls="inl0"
  hrds="hrd0"
fi

# Select revisions, logfiles, tags
if [ "$table" == "alpaka" ]; then
  revs="$arevs $crevs"
  bckend=alpaka
  suff=auto
  taglist="CUD/none ALP/none CPP/none CPP/sse4 CPP/avx2 CPP/512y CPP/512z"
else
  revs="$arevs $crevs"
  bckend=cudacpp
  suff=manu
  taglist="CUD/none CPP/none CPP/sse4 CPP/avx2 CPP/512y CPP/512z"
fi

# Iterate through log files
for fpt in $fpts; do
  echo -e "*** FPTYPE=$fpt ******************************************************************\n" >> $out
  for rev in $revs; do
    echo -e "+++ REVISION $rev +++" >> $out
    nodelast=
    for inl in $inls; do
      for hrd in $hrds; do
        files=""
        for proc in $procs; do
          file=../${bckend}/tput/logs_${proc}_${suff}/log_${proc}_${suff}_${fpt}_${inl}_${hrd}.txt
          if [ -f $file ]; then files="$files $file"; fi
        done
        ###echo "*** FILES $files ***" >> $out
        if [ "$files" == "" ]; then continue; fi
        git checkout $rev $files >& /dev/null
        node=$(cat $files | grep ^On | sort -u)
        if [ "$nodelast" != "$node" ]; then echo -e "$node\n" >> $out; nodelast=$node; fi
        ###cat $files | awk '/^runExe.*check.*/{print $0};/^Process/{print $0};/Workflow/{print $0};/MECalcOnly/{print $0}'; continue
        cat $files | awk -vtaglist="$taglist" -vrev=$rev -vcomplast=none -vinllast=none -vhrdlast=none -vfptlast=none '\
           /^runExe .*check.*/{split($0,a,"check.exe"); last=substr(a[1],length(a[1])); if (last=="g"){tag="CUD"} else if(last=="p"){tag="ALP"} else{tag="CPP"}; split($0,a,"build."); split(a[2],b,"_"); tag=tag"/"b[1]};\
           /^runExe .*check.*/{split($0,a," -p "); split(a[2],b); grid=b[1]"/"b[2]"/"b[3]};\
           /^runExe .*check.*/{gsub("/SubProcesses.*",""); gsub(".*/",""); gsub(".auto",""); proc=$0; grid_proc_tag[proc,tag]=grid};\
           ###/^Process/{split($3,a,"_"); proc=a[3]"_"a[4]; grid_proc_tag[proc,tag]=grid};\
	   /^Process(.)/{split($0,a,"["); comp="["a[2]; if ( complast == "none" ){print comp; complast=comp}};\
           /^Process/{split($0,a,"]"); split(a[2],b,"="); inl=b[2]; if (inl!=inllast){printf "HELINL="inl; inllast=inl}}\
           /^Process/{split($0,a,"]"); split(a[3],b,"="); hrd=b[2]; if (hrd!=hrdlast){if(hrd==""){hrd=0}; print " HRDCOD="hrd; hrdlast=hrd}}\
           /^FP precision/{fpt=$4; /*if ( fpt != fptlast ){print "FPTYPE="fpt; fptlast=fpt}*/}\
           ###/Workflow/{split($4,a,":"); tag=a[1]; split($4,a,"+"); split(a[4],b,"/"); tag=tag"/"b[2]};\
	   /.*check.exe: Aborted/{tput_proc_tag[proc,tag]="(FAILED)"};\
           /MECalcOnly/{tput=sprintf("%.2e", $5); tput_proc_tag[proc,tag]=tput};\
           END{ntag=split(taglist,tags);\
               ###nproc=split("EPEM_MUPMUM GG_TTX GG_TTXG GG_TTXGG GG_TTXGGG",procs);\
               ###procs_txt["EPEM_MUPMUM"]="eemumu";\
               ###procs_txt["GG_TTX"]="ggtt";\
               ###procs_txt["GG_TTXG"]="ggttg";\
               ###procs_txt["GG_TTXGG"]="ggttgg";\
               ###procs_txt["GG_TTXGGG"]="ggttggg";\
               nproc=split("ee_mumu gg_tt gg_ttg gg_ttgg gg_ttggg",procs);\
               procs_txt["ee_mumu"]="eemumu";\
               procs_txt["gg_tt"]="ggtt";\
               procs_txt["gg_ttg"]="ggttg";\
               procs_txt["gg_ttgg"]="ggttgg";\
               procs_txt["gg_ttggg"]="ggttggg";\
               printf "%8s", ""; for(iproc=1;iproc<=nproc;iproc++){proc=procs[iproc]; printf "%14s", procs_txt[proc]}; printf "\n";\
	       gridslast="";\
               for(itag=1;itag<=ntag;itag++)\
               {tag=tags[itag];\
	        gridsok=0; grids=""; for(iproc=1;iproc<=nproc;iproc++){proc=procs[iproc]; grid=grid_proc_tag[proc,tag]; if(grid==""){grid="------"} else {gridsok=1}; grids=grids""sprintf("%14s","["grid"]")}; grids=grids"\n";\
                if(grids!=gridslast && gridsok==1){printf "%-8s%s", "", grids}; gridslast=grids;\
                printf "%-8s", tag; for(iproc=1;iproc<=nproc;iproc++){proc=procs[iproc]; tput=tput_proc_tag[proc,tag]; if(tput==""){tput="--------"}; printf "%14s", tput}; printf "\n";\
               }}' >> $out
        echo "" >> $out
      done
    done
  done
done
git checkout HEAD tput/logs* >& /dev/null
cat $out
