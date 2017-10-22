# starts-travis-ingetration

Scripts to automate statistics collection for STARTS and Travis CI integration.

The tool is written in Shell script with TravisPy Python API tool for Travis API.

# Dependencies

* Bash Shell
* shunit2 (included)
* Python/2.7.x
* TravisPy (pip install travispy)

# Instructions

0. Install all the dependencies
1. Make sure a Java Maven project is forked
2. Acquire an Github API key and set the environment vaiable
   $ export GITHUB_APIKEY="COPY_GITHUB_APIKEY"
3. Run the script as: 
   $ ./generate-basic-stats.sh -d $FORKED_REPO_DIR
4. Other options see:
   $ ./generate-basic-stats.sh -h
