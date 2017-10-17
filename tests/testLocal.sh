#! /bin/bash

CUR_DIR="$( cd "$( dirname "$0" )" && pwd )";

testMvnOutputMin() {
    result=`$CUR_DIR/../generate-basic-stats.sh -l $CUR_DIR/test-data/mvn_result_min.tx -d ./`
    if [[ $? != 0 ]]; then
    	fail "There is an error running the testMvnOutputMin test"
    	return 1
    fi
    assertEquals $result "83"
}

testMvnOutputSecond() {
    result=`$CUR_DIR/../generate-basic-stats.sh -l $CUR_DIR/test-data/mvn_result_sec.txt -d ./`
    if [[ $? != 0 ]]; then
    	fail "There is an error running the testMvnOutputSecond test"
    	return 1
    fi
    assertEquals $result "5.23"
}

testRunMvnLocally() {
	result=`$CUR_DIR/../generate-basic-stats.sh -d $CUR_DIR/test-data/java-hello-proj`
    if [[ $? != 0 ]]; then
    	fail "There is an error running the testMvnOutputSecond test"
    	return 1
    fi
    assertTrue "[[ $result =~ ^[-+]?[0-9]+(\.[0-9]+)?$ ]]"
}

# Load shUnit2.

. $CUR_DIR/../thirdparty/shunit2
