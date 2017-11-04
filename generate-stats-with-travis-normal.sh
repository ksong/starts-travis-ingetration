#!/bin/bash
set -o pipefail

usage() { 
    echo "Usage: $0 [-h] -v -l /path/to/mvn/log -d /path/to/repo/directory -n NUMBER_OF_COMMITS -k APIKEY" 1>&2; exit 1; 
}

exitIfHasError() {
    if [[ $? != 0 ]]; then
	exit 1
    fi
}

function promptIfProceed ()
{
    echo "Do you want to proceed?(Yes/no)"
    read ANSWER;
    case "$ANSWER" in
        Y|y|Yes|yes)  return 0 ;;
    *)            return 1 ;;
    esac
}

while getopts ":hvl:d:k:n:" o; do
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
        k)
            APIKEY=${OPTARG}
            ;;
        n)
            NUM_COMMITS=${OPTARG}
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

if [ -z "${NUM_COMMITS}" ]; then
    echo "Error: Missing number commits to replay." 1>&2;
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


##Setting up to trigger Travis run
# Enable Travis CI using Github API. Need to install TravisPy
PRJOECT_NAME=${REPO_DIR##*/}
if [[ -z $PRJOECT_NAME ]]; then
    echo "Invalid project name: $PRJOECT_NAME"
    echo "Please make sure the directory doesn't end with '/'"
    exit 1;
fi

if [[ -z $APIKEY ]]; then
    if [[ $VERBOSE == 1 ]]; then echo "python $CUR_DIR/enable-travis-and-run.py \"ksong/$PRJOECT_NAME\""; fi
    RESULT=`python $CUR_DIR/enable-travis-and-run.py "ksong/$PRJOECT_NAME"`
else
    if [[ $VERBOSE == 1 ]]; then echo "python $CUR_DIR/enable-travis-and-run.py -k $APIKEY \"ksong/$PRJOECT_NAME\""; fi
    RESULT=`python $CUR_DIR/enable-travis-and-run.py -k $APIKEY "ksong/$PRJOECT_NAME"`
fi


cd ${REPO_DIR}
#Roll back N commits and replay to the current one
for ((i=${NUM_COMMITS};i>=1;i--)); do
    CUR_COMMIT=`git log|grep commit|cut -d" " -f2|head -n ${i}|tail -n 1`
    echo "Force pushing commit ${CUR_COMMIT}"
    git push -f origin ${CUR_COMMIT}:master
    ## A travis build should just happened. Now, we save the test relevant logs to 
    echo "A travis build should just be triggered." 
    echo "Please make sure the build finishes before proceeding. (Check the Travis Web Interface)"
    if promptIfProceed; then
        #  /tmp/test_log.txt
        mv /tmp/test_log.txt /tmp/test_log.txt.OLD
        if [[ -z $APIKEY ]]; then
            echo "running python $CUR_DIR/save-travis-build-log.py \"ksong/$PRJOECT_NAME\""
            python $CUR_DIR/save-travis-build-log.py "ksong/$PRJOECT_NAME"
        else
            echo "running python $CUR_DIR/save-travis-build-log.py -k $APIKEY \"ksong/$PRJOECT_NAME\""
            python $CUR_DIR/save-travis-build-log.py -k $APIKEY "ksong/$PRJOECT_NAME"
        fi

        TRAVIS_TEST_TIME=`cat /tmp/test_log.txt |grep --line-buffered "Total time:"|cut -d" " -f4`
        exitIfHasError;
        if [[ $TRAVIS_TEST_TIME == *":"* ]]; then
            TRAVIS_TEST_TIME=`echo $TRAVIS_TEST_TIME | awk -F: '{ print ($1 * 60) + $2  }'`
        fi

        TRAVIS_BUILD_TIME=`cat /tmp/test_log.txt |grep --line-buffered "Last Travis Build Time:"|cut -d" " -f5`
        exitIfHasError;
        if [[ $TRAVIS_BUILD_TIME == *":"* ]]; then
            TRAVIS_BUILD_TIME=`echo $TRAVIS_BUILD_TIME | awk -F: '{ print ($1 * 60) + $2  }'`
        fi

        echo ${NUM_COMMITS},$TRAVIS_TEST_TIME,$TRAVIS_BUILD_TIME
    fi
done


exit 0;




