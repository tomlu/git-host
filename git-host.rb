#!/usr/bin/env ruby
require 'optparse'
require 'json'

def getconfig(conf)
    output=`git config --get host.#{conf}`.strip
    output if $?.success?
end

def setconfig(conf, val, global)
    globalstr = global && "--global " || ""
    system("git config #{globalstr} --replace-all host.#{conf} #{val}")
end

options = {}
options[:account] = nil
options[:description] = ""

read_account = lambda do

    options[:account] = options[:account] || getconfig("default")

    abort "No account specified" unless options[:account]
    options[:hostname] = getconfig("#{options[:account]}.hostname")
    options[:username] = getconfig("#{options[:account]}.username")
    options[:password] = options[:password] || getconfig("#{options[:account]}.password")
    options[:private] = getconfig("#{options[:account]}.private") || false if options[:private] == nil

    abort "No such account: '#{options[:account]}'" unless options[:hostname]
end

commands = {
    "add" => lambda do
        abort "No account specified" unless options[:account]
        abort "No hostname specified" unless options[:hostname]
        abort "No username specified" unless options[:username]

        setconfig("#{options[:account]}.hostname", options[:hostname], options[:global])
        setconfig("#{options[:account]}.username", options[:username], options[:global])
        if options[:password] != nil then
            setconfig("#{options[:account]}.password", options[:password], options[:global])
        end
        if options[:private] != nil then
            setconfig("#{options[:account]}.private", options[:private], options[:global])
        end
        if options[:default] then
            setconfig("default", options[:account], options[:global])
        end
    end,

    "set-default" => lambda do
        abort "No account specified" unless options[:account]
        setconfig("default", options[:account], options[:global])
    end,
}

hosts = {
    "bitbucket" => {
        "create-repo" => lambda do
            abort "No username specified" unless options[:username]
            abort "No password specified" unless options[:password]

            system("curl --silent --request POST --user #{options[:username]}:#{options[:password]} https://api.bitbucket.org/1.0/repositories/ --data name=#{options[:reponame]} --data scm=git --data description=\"#{options[:description]}\" --data is_private=#{options[:private]}")
            abort "Command failed" unless $?.success?
        end,

        "delete-repo" => lambda do
            abort "No username specified" unless options[:username]
            abort "No password specified" unless options[:password]

            system("curl --silent --request DELETE --user #{options[:username]}:#{options[:password]} https://api.bitbucket.org/1.0/repositories/#{options[:username]}/#{options[:reponame].downcase}")
            abort "Command failed" unless $?.success?
        end,

        "url-for" => lambda do
            abort "No username specified" unless options[:username]

            puts "git@bitbucket.org:#{options[:username]}/#{options[:reponame].downcase}.git"
        end,
    },

    "github" => {
        "create-repo" => lambda do
            abort "No username specified" unless options[:username]
            abort "No password specified" unless options[:password]

            json = JSON.generate(
                    :name => options[:reponame],
                    :description => options[:description],
                    :private => options[:private],
                )
            system("curl --silent -X POST -u #{options[:username]}:#{options[:password]} --data '#{json}' https://api.github.com/user/repos")
            abort "Command failed" unless $?.success?
        end,

        "delete-repo" => lambda do
            abort "No username specified" unless options[:username]
            abort "No password specified" unless options[:password]

            system("curl --silent -X DELETE -u #{options[:username]}:#{options[:password]} https://api.github.com/repos/#{options[:username]}/#{options[:reponame]}")
            abort "Command failed" unless $?.success?
        end,

        "url-for" => lambda do
            abort "No username specified" unless options[:username]

            puts "git@github.com:#{options[:username]}/#{options[:reponame]}.git"
        end,
    }
}

get_host_command = lambda do |commandname|
    abort "No hostname specified" unless options[:hostname]

    host = hosts[options[:hostname]]
    abort "Unknown hostname '#{options[:hostname]}'" unless host
    command = host[commandname]

    return command
end

option_parser = OptionParser.new do |opts|
  opts.banner = 
"
Usage: git-host [options] command

Commands: 
  add --hostname [hostname] --account [account name] --username [username] [--password [password]] 
              [--[no]global] [--default] 
  set-default --account [account name] [--[no]global]
  create-repo [repo-name] [--account [account name]] [--password [password]]
              [--[no]private]
  delete-repo [repo-name] [--account [account name]] [--password [password]]
  url-for [repo-name] [--account [account name]]

Command description:
  add           Adds a new account by writing to git config
  set-default   Sets the account to be used if one isn't supplied
  create-repo   Creates a new repository
  delete-repo   Deletes a repository
  url-for       Prints the git url for the given repository to stdout

"

    opts.on("--account [ACCOUNT]", "The host account. If omitted, the default account is read.") do |val|
        options[:account] = val
    end

    opts.on("--description [DESCRIPTION]", "Adds a description to the repository.") do |val|
        options[:description] = val
    end

    opts.on("--[no-]private", "Create a private repository.") do |val|
        options[:private] = val
    end

    opts.on("--password [PASSWORD]", "The account password") do |val|
        options[:password] = val
    end

    opts.on("--username [USERNAME]", "The account username") do |val|
        options[:username] = val
    end

    opts.on("--hostname [HOSTNAME]", "The host name (eg. github)") do |val|
        options[:hostname] = val
    end

    opts.on("--[no-]global)", "Whether a global or repository-local account is created") do |val|
        options[:global] = val
    end

    opts.on("--default", "Whether the account is the default account") do |val|
        options[:default] = val
    end

    opts.on_tail("-h", "--help", "Show this message.") do
        puts opts
        exit
    end
end
option_parser.parse!

if ARGV.length < 1 then
    puts option_parser
else
    commandname = ARGV[0]

    command = commands[commandname]
    if not command then
        options[:reponame] = ARGV[1]
        read_account.call()
        abort "No repository name specified" unless options[:reponame]
        command = get_host_command.call(commandname)
    end
    abort "Unknown command '#{commandname}'" unless command

    command.call()
end
