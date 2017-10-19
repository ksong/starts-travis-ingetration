#!/bin/bash
set -o pipefail

usage() { 
    echo "Usage: $0 [-h] -l /path/to/mvn/log -d /path/to/repo/directory" 1>&2; exit 1; 
}

exitIfHasError() {
    if [[ $? != 0 ]]; then
	exit 1
    fi
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
    echo "Error: repository directory undefined." 1>&2;
    usage
fi

if [[ $USE_LOG_FILE == 1 && -z "${LOG_FILE}" ]]; then
    echo "Error: mvn test log file localtion undefined." 1>&2;
    usage
fi


if [[ ! -d $REPO_DIR ]]; then
    echo "$REPO_DIR is not a valid directory for the repo." 1>&2;
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

if [[ -z `cat $LOG_LOCAL_RUN|grep --line-buffered SUCCESS` ]]; then
    echo "'mvn test' build failed.";
    exit 1;
fi
exitIfHasError;

LOCAL_TIME=`cat $LOG_LOCAL_RUN|grep --line-buffered "Total time:"|cut -d" " -f4`
exitIfHasError;

if [[ $LOCAL_TIME == *":"* ]]; then
    LOCAL_TIME=`echo $LOCAL_TIME | awk -F: '{ print ($1 * 60) + $2  }'`
fi


echo $LOCAL_TIME
