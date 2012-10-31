git-host
========

What is it?
-----------

git-host provides a command line interface to repository management. This can be convenient to avoid having to log into a web service to quickly create new repositories. git-host can also serve as a building block for other tools to create repositories without having to learn each git host's API. 

Supported hosts
---------------

At the moment only Bitbucket is supported.

Documentation
-------------

To use git-host you tie all the host information together in an *account*, which is then passed to all other git-host commands. For convenience can set a default account to use either globally or per-repository.

Installation
------------

Clone the repository and `sudo ./install [--symlink]`

Example
-------

	# Create new account
	git host add --account bigco --hostname bitbucket --username admin@bigco.com --password 12345

	# Set this account as the default account for this repository
	git host set-default bigco

	# Create a new repo
	git host create-repo bigproj --private --description "Our new awesome project"