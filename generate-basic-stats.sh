#!/bin/bash
set -o pipefail

usage() { 
    echo "Usage: $0 [-h] -l /path/to/mvn/log -d /path/to/repo/directory" 1>&2; exit 1; 
}

while getopts ":hl:d:" o; do
    case "${o}" in
        h)
            echo "Collect statistics for basic statistics with STARTS."
            usage
            ;;
        d)
            REPO_DIR=${OPTARG}
            ;;
        l)
            LOG_FILE=${OPTARG}
            USE_LOG_FILE=1
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${REPO_DIR}" ]; then
    usage
fi

if [[ $USE_LOG_FILE == 1 && -z "${LOG_FILE}" ]]; then
    usage
fi


if [[ ! -d $REPO_DIR ]]; then
    echo "Please specify a valid directory for the repo";
    usage;
fi

CUR_DIR="$( cd "$( dirname "$0" )" && pwd )";


if [ -z $LOG_FILE ]; then
    cd $REPO_DIR
    LOG_LOCAL_RUN="/tmp/local.log"
    mvn test > $LOG_LOCAL_RUN
else
    LOG_LOCAL_RUN="${LOG_FILE}"
fi



TIME=`cat $LOG_LOCAL_RUN|grep --line-buffered "Total time:"|cut -d" " -f4`
if [[ $? != 0 ]]; then
    exit 1
fi


if [[ $TIME == *":"* ]]; then
    TIME=`echo $TIME | awk -F: '{ print ($1 * 60) + $2  }'`
fi


echo $TIME
