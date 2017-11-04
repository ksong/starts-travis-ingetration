import os
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

travis = TravisPy.github_auth(GITHUB_APIKEY)
repo = travis.repo(project)
repo.enable() # Switch is now on

