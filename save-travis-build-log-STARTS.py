import os
import argparse
import time, datetime
from travispy import TravisPy
import sys;

reload(sys);
sys.setdefaultencoding("utf8")

ts = time.time()

parser = argparse.ArgumentParser(description='Enable Travis CI for the give project')
parser.add_argument('project', help='github project name')
parser.add_argument('-k', '--apikey', help='github project name')
args = parser.parse_args()
project=args.project;

if args.apikey:
	GITHUB_APIKEY=args.apikey
else:
	GITHUB_APIKEY=os.environ['GITHUB_APIKEY']

print "GITHUB_APIKEY: "
print GITHUB_APIKEY
header="\n\n------------------------------------------\n"
header+="NEW Travis Run. Log Time: "
header+=datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')
header+="\n------------------------------------------\n"
try:
	travis = TravisPy.github_auth(GITHUB_APIKEY)
	repo = travis.repo(project)
	build = travis.build(repo.last_build_id)
	job = travis.job(build.job_ids[0])
	log = travis.log(job.log_id)
	log_parsed=log.get_archived_log().split('$ echo "=========STARTS INTEGRATION BLOCK=========="')
	if len(log_parsed) != 3:
		test_content = "Last Travis Build Time: SKIPPED\n" + "[INFO] Total time: SKIPPED\n"
	else:
		test_content = log_parsed[1]
		test_content = "Last Travis Build Time: " + str(repo.last_build_duration) + "\n" + test_content
	test_log_file = open("/tmp/test_log.txt", "w")
	test_log_file.write(header+test_content)
	test_log_file.close()
except:
	test_content = "Last Travis Build Time: ERROR\n" + "real	ERROR\n"
	test_log_file = open("/tmp/test_log.txt", "w")
	test_log_file.write(header+test_content)
	test_log_file.close()
