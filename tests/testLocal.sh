#!/bin/bash

CUR_DIR="$( cd "$( dirname "$0" )" && pwd )";
TEMP_DIR="$TMPDIR"
TEST_REPO_DIR="$TEMP_DIR/java-hello-proj"

setUp(){
	mkdir -p $TEST_REPO_DIR
}

tearDown(){
	rm -rf $TEST_REPO_DIR
}

testMvnOutputMin() {
    result=`$CUR_DIR/../generate-basic-stats.sh -l $CUR_DIR/test-data/mvn_result_min.txt -d $TEST_REPO_DIR`
    if [[ $? != 0 ]]; then
    	fail "There is an error running the testMvnOutputMin test"
    	return 1
    fi
    assertTrue "[[ $result =~  83 ]]"
}

testMvnOutputSecond() {
    result=`$CUR_DIR/../generate-basic-stats.sh -l $CUR_DIR/test-data/mvn_result_sec.txt -d $TEST_REPO_DIR`
    if [[ $? != 0 ]]; then
    	fail "There is an error running the testMvnOutputSecond test"
    	return 1
    fi
    assertTrue "[[ $result =~  5\.23 ]]"
}

testRunMvnTestFail() {
	result=`$CUR_DIR/../generate-basic-stats.sh -d $CUR_DIR/test-data/`
	assertEquals 1 $?
    assertEquals  "$result" "'mvn test' build failed."
}

testMvnRunFail() {
    result=`$CUR_DIR/../generate-basic-stats.sh -l $CUR_DIR/test-data/DO_NOT_EXIST -d ./`
    assertEquals 1 $?
}



# Load shUnit2.

. $CUR_DIR/../thirdparty/shunit2
