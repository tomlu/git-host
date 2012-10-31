git-host
========

What is it?
-----------

git-host provides a command line interface to repository management. This can be convenient to avoid having to log into a web service to quickly create new repositories. git-host can also serve as a handy abstraction for other tools to create repositories without you having to teach them the intricacies of each API.

Supported hosts
---------------

* Github
* Bitbucket

Documentation
-------------

To use git-host you tie all the host information together in an *account*, which is then passed to all other git-host commands. For convenience you can set the default account either globally or per-repository.

All account information is simply stored in the .gitconfig at the appropriate level.

Requirements
------------

* Ruby 1.9 or higher
* Only tested on OS X, I have no idea if it will work on anything else

Installation
------------

Clone the repository and `sudo ./install [--symlink]`

Example
-------

	# Create new host account
	git host add --account bigco --hostname bitbucket --username admin@bigco.com --password 12345

	# Set this account as the default account for this repository
	git host set-default --account bigco

	# Create a new repo using the default account
	git host create-repo bigproj --private --description "Our new awesome project"

	# Output the url for an repository (useful for tools)
	git host url-for bigproj