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
AJDUSTED_NUM_COMMITS=`expr ${NUM_COMMITS} - 1`
STARTS_READY="no"
for CUR_COMMIT in `for i in $(seq ${AJDUSTED_NUM_COMMITS} -1 0); do git rev-parse HEAD~${i}; done`; do
    if [[ $STARTS_READY == "no" ]]; then
        echo "Checking out commit ${CUR_COMMIT}"
        git checkout -b ${CUR_COMMIT} ${CUR_COMMIT}
        echo "Please update the pom.xml"
        echo "Add this code to <plugins> section"
        echo "<plugin>
      <groupId>edu.illinois</groupId>
      <artifactId>starts-maven-plugin</artifactId>
      <version>1.3</version>
    </plugin>"
        if promptIfProceed; then
            emacs pom.xml
        fi
        echo "About to run mvn starts:starts to generate starts artifacts"
        if promptIfProceed; then
            mvn starts:starts
        fi
        echo "About to add starts artifacts to .travis.yml for caching"
        echo "These are changes typically needed:"
        echo "======================================"
        echo "cache:"
        echo "  directories:"
        for line in `find .|grep .starts\$|sed "s/\.\///g"`; do echo "    - \$TRAVIS_BUILD_DIR/"$line; done
        for line in `find .|grep jdeps-cache\$|sed "s/\.\///g"`; do echo "    - \$TRAVIS_BUILD_DIR/"$line; done
        echo ""
        echo "script:"
        echo "  - echo \"=========STARTS INTEGRATION BLOCK==========\""
        echo "  - time mvn starts:starts"
        echo "  - echo \"=========STARTS INTEGRATION BLOCK==========\""
        echo "======================================"
        if promptIfProceed; then
            emacs .travis.yml    
        fi
        echo "Please make sure both pom.xml and .travis.yml are updated correctly"
        echo "About to commit the changes and push"
        if promptIfProceed; then
            git add .travis.yml pom.xml
            git commit -m "Updated for STARTS integration"
            STARTS_MOD_COMMIT=`git rev-parse HEAD~0`
            echo "Force pushing commit ${STARTS_MOD_COMMIT}"
            git push -f origin ${STARTS_MOD_COMMIT}:master
        fi
        STARTS_READY="yes"
    else
        echo "About to rebase the commit ${CUR_COMMIT}"
        git rebase ${CUR_COMMIT}
        echo "Please make sure the rebase finished successfully and fix conflicts if needed."
        echo "About to push"
        if promptIfProceed; then
            STARTS_MOD_COMMIT=`git rev-parse HEAD~0`
            echo "Force pushing commit ${STARTS_MOD_COMMIT}"
            git push -f origin ${STARTS_MOD_COMMIT}:master
        fi
    fi

    ## A travis build should just happened. Now, we save the test relevant logs to 
    echo "A travis build should just be triggered." 
    echo "Please make sure the build finishes before proceeding. (Check the Travis Web Interface)"
    if promptIfProceed; then
        #  /tmp/test_log.txt
        mv /tmp/test_log.txt /tmp/test_log.txt.OLD
        if [[ -z $APIKEY ]]; then
            echo "running python $ROOT_DIR/save-travis-build-log-STARTS.py \"ksong/$PRJOECT_NAME\""
            python $ROOT_DIR/save-travis-build-log-STARTS.py "ksong/$PRJOECT_NAME"
        else
            echo "running python $ROOT_DIR/save-travis-build-log-STARTS.py -k $APIKEY \"ksong/$PRJOECT_NAME\""
            python $ROOT_DIR/save-travis-build-log-STARTS.py -k $APIKEY "ksong/$PRJOECT_NAME"
        fi

        TRAVIS_TEST_TIME=`cat /tmp/test_log.txt |egrep "real.*m.*s"|cut -d$'\t' -f2|cut -d's' -f1`
        exitIfHasError;
        TRAVIS_TEST_TIME=`echo $TRAVIS_TEST_TIME | awk -Fm '{ print ($1 * 60) + $2  }'`

        TRAVIS_BUILD_TIME=`cat /tmp/test_log.txt |grep --line-buffered "Last Travis Build Time:"|cut -d" " -f5`
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
    else
        echo ${CUR_COMMIT},SKIPPED,SKIPPED
        if [[ ! -z ${OUTPUT_FILE} ]]; then
            echo "Skipeed ${CUR_COMMIT}. Appending to file: ${OUTPUT_FILE}"  
            cd ${CUR_DIR}
            echo ${CUR_COMMIT},SKIPPED,SKIPPED >> ${OUTPUT_FILE}
            cd ${REPO_DIR}
        fi
    fi
done 





