#!/bin/bash
#Date created: 25.11.2020
#Created By: Mahesan G
#Find hdfs files older than n days in the mentioned path.
#where arg1 is directory path and arg2 is no of days older than.
#Example: /.hdfsoldfiles.sh /apps/hive/warehouse/ 30

Red="\033[0;31m"
Green="\033[0;32m"
Yellow="\033[0;33m"
White="\033[0;37m"
now=$(date +%s)
filenamedate=$(date "+%d.%m.%Y-%H.%M.%S")
filename="hdfs_deleted_files_log_$(date "+%d.%m.%Y-%H.%M.%S").csv"
dirpath=$1
numofdays=$2
totalinmb=0
totalfiles=0
function ask_yes_or_no() {
    read -p "$1 ([y]es or [N]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|yes) echo "yes" ;;
        *)     echo "no" ;;
    esac
}
if [[ "no" == $(ask_yes_or_no "Do you want to Delete files older than ${numofdays}days in Directory $dirpath?") || \
      "no" == $(ask_yes_or_no "Are You Really Sure?") ]]
then
    echo "Skipped."
    exit 0
fi
dir_size_before_del="$(hdfs dfs -du -s -h $dirpath)"
dir_files_count="$(hdfs dfs -ls $dirpath | grep -E '^-' | wc -l)"
while read f
do
file_date=$(echo {$f} | awk '{print $6}')
difference=$(( ( $now - $(date -d "$file_date" +%s) ) / (24*60*60) ))
filePath=$(echo ${f} | awk '{print $8}')
filesize=$(echo ${f} | awk '{print $5}')
if [[ "$difference" -gt $numofdays ]]; then
  (( totalfiles++ ))
  sizeinmb="$(($filesize / 2**20))"
  totalinmb="$(($totalinmb + $sizeinmb))"
  echo "$file_date,$filePath,$filesize,$sizeinmb,$filenamedate,deleted" | tee -a $filename
  hdfs dfs -rmr $filePath
fi
done < <(hdfs dfs -ls $dirpath | grep -E '^-')
totalingb="$(( $totalinmb / 1024 ))"
echo -e "${Yellow}************Directory Size Before Deletetion*************${White}" | tee -a $filename
echo -e "${Green}$dir_size_before_del${White}" | tee -a $filename
echo -e "${Green}Total number of files ${Yellow}$dir_files_count${White}" | tee -a $filename
echo -e "${Yellow}************Files Deletetion Details*************${White}" | tee -a $filename
echo -e "${Green}Total Number of Files Older than ${numofdays}days Found in the Directory ${Yellow}$dirpath ${Green}is ${Red}$totalfiles${White}" | tee -a $filename
echo -e "${Green}Total Files Deleted is MB ${Yellow}$totalinmb ${Red}${White}" | tee -a $filename
echo -e "${Green}Total Files Deteted in GB ${Yellow}$totalingb ${Red}${White}" | tee -a $filename
echo -e "${Yellow}************Directory Size After Deletetion*************${White}" | tee -a $filename
echo -e "${Green}$(hdfs dfs -du -s -h $dirpath)${White}" | tee -a $filename
exit 0