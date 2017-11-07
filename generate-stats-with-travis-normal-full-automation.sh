#!/bin/bash
set -o pipefail

usage() { 
    echo "Usage: $0 [-h] -v -l /path/to/mvn/log -d /path/to/repo/directory -n NUMBER_OF_COMMITS -k APIKEY -o OUTPUT_FILE" 1>&2; exit 1; 
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

while getopts ":hvl:d:k:n:o:" o; do
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
        o)
            OUTPUT_FILE=${OPTARG}
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

if [[ ! -z ${OUTPUT_FILE} ]]; then
    echo "Writing to file: ${OUTPUT_FILE}"  
    echo "commit_hash,test_time,toal_time" > ${OUTPUT_FILE}
fi

CUR_DIR=`pwd`
ROOT_DIR="$( cd "$( dirname "$0" )" && pwd )";

##Setting up to trigger Travis run
# Enable Travis CI using Github API. Need to install TravisPy
PRJOECT_NAME=${REPO_DIR##*/}
if [[ -z $PRJOECT_NAME ]]; then
    echo "Invalid project name: $PRJOECT_NAME"
    echo "Please make sure the directory doesn't end with '/'"
    exit 1;
fi

if [[ -z $APIKEY ]]; then
    if [[ $VERBOSE == 1 ]]; then echo "python $ROOT_DIR/enable-travis-and-run.py \"ksong/$PRJOECT_NAME\""; fi
    RESULT=`python $ROOT_DIR/enable-travis.py "ksong/$PRJOECT_NAME"`
else
    if [[ $VERBOSE == 1 ]]; then echo "python $ROOT_DIR/enable-travis-and-run.py -k $APIKEY \"ksong/$PRJOECT_NAME\""; fi
    RESULT=`python $ROOT_DIR/enable-travis.py -k $APIKEY "ksong/$PRJOECT_NAME"`
fi

#Roll back N commits and replay to the current one
cd ${REPO_DIR}
for i in $(seq ${NUM_COMMITS} -1 1); do    
    CUR_COMMIT=`git log|grep commit|cut -d" " -f2|head -n ${i}|tail -n 1`
    echo "Force pushing commit ${CUR_COMMIT}"
    git push -f origin ${CUR_COMMIT}:master
    ## A travis build should just happened. Now, we save the test relevant logs to 
    echo "A travis build should just be triggered." 
    echo "Please make sure the build finishes before proceeding. (Check the Travis Web Interface)"
    echo "Sleeping 120 seonds to make sure build is triggered in Travis"
    sleep 120
#    if promptIfProceed; then
    while [[ true ]]; do
        rm -rf /tmp/last-build-result.txt
        if [[ -z $APIKEY ]]; then
            if [[ $VERBOSE == 1 ]]; then echo "python $ROOT_DIR/check-last-build-status.py \"ksong/$PRJOECT_NAME\""; fi
            python $ROOT_DIR/check-last-build-status.py "ksong/$PRJOECT_NAME"
        else
            if [[ $VERBOSE == 1 ]]; then echo "python $ROOT_DIR/check-last-build-status.py -k $APIKEY \"ksong/$PRJOECT_NAME\""; fi
            python $ROOT_DIR/check-last-build-status.py -k $APIKEY "ksong/$PRJOECT_NAME"
        fi
        RESULT = `cat /tmp/last-build-result.txt`
        echo "==============="
        echo "Result: $RESULT"
        echo "==============="        
        if [[ $RESULT == "NOT_DONE" ]]; then
            echo ""
            echo "Travis run is not done yet. Sleep for 30 seconds"
            echo ""
            sleep 30
        else
            rm -rf  /tmp/test_log.txt
            if [[ -z $APIKEY ]]; then
                echo "running python $ROOT_DIR/save-travis-build-log.py \"ksong/$PRJOECT_NAME\""
                python $ROOT_DIR/save-travis-build-log.py "ksong/$PRJOECT_NAME"
            else
                echo "running python $ROOT_DIR/save-travis-build-log.py -k $APIKEY \"ksong/$PRJOECT_NAME\""
                python $ROOT_DIR/save-travis-build-log.py -k $APIKEY "ksong/$PRJOECT_NAME"
            fi

            TRAVIS_TEST_TIME=`cat /tmp/test_log.txt |grep "Total time:"|cut -d" " -f4`
            exitIfHasError;
            if [[ $TRAVIS_TEST_TIME == *":"* ]]; then
                TRAVIS_TEST_TIME=`echo $TRAVIS_TEST_TIME | awk -F: '{ print ($1 * 60) + $2  }'`
            fi

            TRAVIS_BUILD_TIME=`cat /tmp/test_log.txt |grep "Last Travis Build Time:"|cut -d" " -f5`
            exitIfHasError;
            if [[ $TRAVIS_BUILD_TIME == *":"* ]]; then
                TRAVIS_BUILD_TIME=`echo $TRAVIS_BUILD_TIME | awk -F: '{ print ($1 * 60) + $2  }'`
            fi
            echo ${CUR_COMMIT},$TRAVIS_TEST_TIME,$TRAVIS_BUILD_TIME
            if [[ ! -z ${OUTPUT_FILE} ]]; then
                echo "Appending to file: ${OUTPUT_FILE}"  
                cd ${CUR_DIR}
                echo ${CUR_COMMIT},$TRAVIS_TEST_TIME,$TRAVIS_BUILD_TIME >> ${OUTPUT_FILE}
                cd ${REPO_DIR}
            fi
            echo ""
            echo "Moving on to the next commit"
            DATE_STR=`date "+%Y-%m-%d-%H:%M:%S"`
            cp /tmp/test_log.txt /tmp/test_log_${DATE_STR}.txt
            break;
        fi
    done
done 





