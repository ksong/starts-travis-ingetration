#! /bin/bash

CUR_DIR="$( cd "$( dirname "$0" )" && pwd )";

testMvnOutputMin() {
    result=`$CUR_DIR/../generate-basic-stats.sh -t mvn_result_min.txt -d ./|grep -v "\-\-\-"`
    assertEquals $result "83"
}

testMvnOutputSecond() {
    result=`$CUR_DIR/../generate-basic-stats.sh -t mvn_result_sec.txt -d ./|grep -v "\-\-\-"`
    assertEquals $result "5.23"
}

# Load shUnit2.

. $CUR_DIR/../thirdparty/shunit2
