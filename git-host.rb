#!/usr/local/bin/ruby
require 'optparse'

def getconfig(conf)
    output=`git config --get #{conf}`.strip
    output if $?.success?
end

options = {}
options[:account] = getconfig("host.account")

hosts = {
    "bitbucket" => {
        "create-repo" => lambda do
            abort "host.<account>.username or --username must be in your git config" unless options[:username]
            abort "host.<account>.password --password must be in your git config" unless options[:password]

            system("curl --silent --request POST --user #{options[:username]}:#{options[:password]} https://api.bitbucket.org/1.0/repositories/ --data name=#{options[:reponame]} --data scm=git --data description #{options[:description]} --data is_private=#{options[:private]}")
            abort "Command failed" unless $?.success?
        end,

        "delete-repo" => lambda do
            abort "host.<account>.username or --username must be in your git config" unless options[:username]
            abort "host.<account>.password --password must be in your git config" unless options[:password]

            system("curl --silent --request DELETE --user #{options[:username]}:#{options[:password]} https://api.bitbucket.org/1.0/repositories/#{options[:username]}/#{options[:reponame].downcase}")
            abort "Command failed" unless $?.success?
        end,

        "url-for" => lambda do
            abort "host.<account>.username or --username must be in your git config" unless options[:username]

            puts "git@bitbucket.org:#{options[:username]}/#{options[:reponame].downcase}.git"
        end,
    }
}

option_parser = OptionParser.new do |opts|
  opts.banner = 
"
Usage: git-host [options] command repo-name
command: create-repo|delete-repo|url-for

create-repo: Creates a remote repository
url-repo: Prints the url of the remote repository to stdout
"

    opts.on("--account [ACCOUNT]", "The host account. If omitted, the default account is read.") do |val|
        options[:account] = val
    end

    opts.on("--description [DESCRIPTION]", "(create-repo only): Adds a description to the repository.") do |val|
        options[:description] = val
    end

    opts.on("--[no-]private", "(create-repo only): Create a private repository.") do |val|
        options[:private] = val
    end

    opts.on_tail("-h", "--help", "Show this message.") do
        puts opts
        exit
    end
end
option_parser.parse!

if ARGV.length != 2 then
    puts option_parser
else
    commandname = ARGV[0]
    options[:reponame] = ARGV[1]

    abort "host.account or --account must be specified" unless options[:account]

    options[:hostname] = getconfig("host.#{options[:account]}.hostname")
    options[:username] = getconfig("host.#{options[:account]}.username")
    options[:password] = getconfig("host.#{options[:account]}.password")
    options[:private] = getconfig("host.#{options[:account]}.private") || false if options[:private] == nil

    abort "host.<account>.hostname must be in your git config" unless options[:hostname]

    host = hosts[options[:hostname]]
    abort "Unknown hostname '#{options[:hostname]}'" unless host

    command = host[commandname]
    abort "Unknown command '#{commandname}'" unless command

    command.call()
end
