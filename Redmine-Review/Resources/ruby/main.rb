require 'rubygems'
gem_path = File.join(
  File.expand_path(File.dirname(Ti.App.getPath)),
  '../Resources/ruby/gems/ruby/1.8'
)
Gem.use_paths(gem_path)

################################################################################

require 'ruby/models.rb'
require 'ruby/application.rb'
require 'haml'

# TODO: Designoptimierungen
# TODO: Tickets einklappen + ausklappbar
# TODO: -> GitHub

load '~/.rrt_config'

################################################################################
Application.new(window, HOSTNAME, AUTH_TOKEN, UNINTERESTING_PROJECTS)
