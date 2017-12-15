# starts-travis-ingetration

Scripts to automate statistics collection for STARTS and Travis CI integration.

The tool is written in Shell script with TravisPy Python API tool for Travis API.

## Dependencies

* Bash Shell
* shunit2 (included)
* Python/2.7.x
* TravisPy (pip install travispy)

## Instructions

0. Install all the dependencies
1. Make sure a Java Maven project is forked
2. Acquire an Github API key and set the environment vaiable

   $ export GITHUB_APIKEY="COPY_GITHUB_APIKEY"

3. Run the script as: 

   $ #Supervised automated run for all tests (Prompt for user to proceed)

   $ ./generate-stats-with-travis-normal.sh -d PROJECT_DIR -b BRANCH -n NUM_COMMITS -k APIKEY -o OUTPUT.csv

   $ #Fully automated run for all tests 

   $ ./generate-stats-with-travis-normal-full-automation.sh -d PROJECT_DIR -b BRANCH -n NUM_COMMITS -k APIKEY -o OUTPUT.csv

   $ #Supervised automated run for STARTS (script wait user to proceed)

   $ #Prompted for editing pom.xml and .travis.yml

   $ ./generate-stats-with-travis-STARTS.sh -d PROJECT_DIR -b BRANCH -n NUM_COMMITS -k APIKEY -o OUTPUT.csv

4. See all options:

   $ ./generate-basic-stats.sh -h
