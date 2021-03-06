#!/bin/bash

CUR_DIR="$( cd "$( dirname "$0" )" && pwd )";
TEMP_DIR="$TMPDIR"
TEST_REPO_DIR="$TEMP_DIR/java-hello-proj"

setUp() {
    if [ ! -d "$TEST_REPO_DIR" ]; then
	cd $TEMP_DIR
    #For Travis build, we have to use HTTPS instead of SSH
	#git clone https://github.com/ksong/java-hello-proj.git
    git clone git@github.com:ksong/java-hello-proj.git
    fi
}

tearDown(){
    rm -rf $TEST_REPO_DIR;
}

testRunMvnLocally() {
    echo "================"
    echo "Note, please set your github APIKEY using GITHUB_APIKEY"
    echo "================"
	result=`$CUR_DIR/../generate-basic-stats.sh -d $TEST_REPO_DIR`
    echo "Running: $CUR_DIR/../generate-basic-stats.sh -d $TEST_REPO_DIR"
    if [[ $? != 0 ]]; then
    	fail "There is an error running the testMvnOutputSecond test"
    	return 1
    fi
    assertTrue "[[ $result =~ ^[0-9]+(\.[0-9]+)?,[0-9]+(\.[0-9]+)?$ ]]"
}




# Load shUnit2.

. $CUR_DIR/../thirdparty/shunit2
