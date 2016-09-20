# Take Back Chatter
An OSX Chatter client that includes Bayesian Filtering for managing spam.

## Not under active development

# Building

there are submodules to pull in dependencies, and one of those also has sub modules, so once you cloned the repo, you need

	git submodule init
	git submodule update
	cd BayesianKit
	git submodule init
	git submodule update

# Requires
OSX 10.6 and a Salesforce account with API access, builds with Xcode 4.
