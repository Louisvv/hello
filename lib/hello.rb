require 'greeter'

#Deafault is "World"
#Author:Yanwei (648555416@qq.com)
name = ARGV.first || ""World"

greeter = Greeter.new(name)
puts greeter.greet
