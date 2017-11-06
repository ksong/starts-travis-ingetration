import os, sys
import argparse
from travispy import TravisPy



parser = argparse.ArgumentParser(description='Enable Travis CI for the give project')
parser.add_argument('project', help='github project name')
parser.add_argument('-k', '--apikey', help='github project name')
args = parser.parse_args()
project=args.project;

if args.apikey:
	GITHUB_APIKEY=args.apikey
else:
	GITHUB_APIKEY=os.environ['GITHUB_APIKEY']


try:
   	travis = TravisPy.github_auth(GITHUB_APIKEY)
	repo = travis.repo(project)

	build = travis.build(repo.last_build_id)
	job = travis.job(build.job_ids[0])
	log = travis.log(job.log_id)
	#print "build finished at:" + str(build.finished_at)
	#print "job finished at:" + str(job.finished_at)

	if job.finished_at is None and build.finished_at is None:
		print "NOT_DONE"
	else:
		print "DONE"
	sys.exit(0)
except:
   	print "NOT_DONE"

	



