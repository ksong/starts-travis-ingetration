#!/bin/sh

usage() { 
    echo "Usage: $0 [-h] [-t testfile] -d /path/to/repo/directory" 1>&2; exit 1; 
}

while getopts ":ht:d:" o; do
    case "${o}" in
        h)
            echo "Collect statistics for basic statistics with STARTS."
            usage
            ;;
        t)
            echo "--- Running Testing mode ---"
	    TEST=1;
	    TEST_FILE=${OPTARG}
            ;;
        d)
            REPO_DIR=${OPTARG}
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

if [[ $TEST == 1 && -z "${TEST_FILE}" ]]; then
    usage
fi


if [[ ! -d $REPO_DIR ]]; then
    echo "Please specify a valid directory for the repo";
    usage;
fi

CUR_DIR="$( cd "$( dirname "$0" )" && pwd )";

cd $REPO_DIR

if [[ $TEST == 1 ]]; then
    TIME=`cat $CUR_DIR/tests/test-data/$TEST_FILE|grep "Total time:"|cut -d" " -f4`
else
    TIME=`mvn test|grep "Total time:"|cut -d" " -f4`
fi

if [[ $TIME == *":"* ]]; then
    TIME=`echo $TIME | awk -F: '{ print ($1 * 60) + $2  }'`
fi


echo $TIME