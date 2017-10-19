#!/bin/bash
set -o pipefail

usage() { 
    echo "Usage: $0 [-h] -v -l /path/to/mvn/log -d /path/to/repo/directory -k APIKEY" 1>&2; exit 1; 
}

exitIfHasError() {
    if [[ $? != 0 ]]; then
	exit 1
    fi
}

while getopts ":hvl:d:k:" o; do
    case "${o}" in
        h)
            echo "Collect statistics for basic statistics with STARTS."
            usage
            ;;
        v)
            echo "Enabling Verbose Mode"
            VERBOSE=1
            ;;
        d)
            REPO_DIR=${OPTARG}
            ;;
        d)
            APIKEY=${OPTARG}
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

if [[ -z $APIKEY ]]; then
    APIKEY=$GITHUB_APIKEY
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
    echo "'mvn test' build failed." 2>&1;
    exit 1;
fi
exitIfHasError;

LOCAL_TIME=`cat $LOG_LOCAL_RUN|grep --line-buffered "Total time:"|cut -d" " -f4`
exitIfHasError;

if [[ $LOCAL_TIME == *":"* ]]; then
    LOCAL_TIME=`echo $LOCAL_TIME | awk -F: '{ print ($1 * 60) + $2  }'`
fi

##Setting to trigger Travis run
# Enable Travis CI using Github API. Need to install TravisPy
PRJOECT_NAME=${REPO_DIR##*/}
if [[ -z $APIKEY ]]; then
    python $CUR_DIR/enable-travis.py "ksong/$PRJOECT_NAME"
else
    python $CUR_DIR/enable-travis.py -k $APIKEY "ksong/$PRJOECT_NAME" 
fi

if [[ ! -z "$(ls -A ${REPO_DIR})" && ! -f ${REPO_DIR}/.travis.yml ]]; then
    if [[ $VERBOSE == 1 ]]; then echo "creating .travis.yml file"; fi
    echo "language: java" > ${REPO_DIR}/.travis.yml
    cd ${REPO_DIR}

    git add .travis.yml
    git config user.name "Kai Song"
    git config user.email "kaisong2@illinois.edu"
    git commit -m "added .travis.yml"
    git push origin master
#else
    #Travis is already enabled
    #Use travispy to force a previous build
fi



echo $LOCAL_TIME
