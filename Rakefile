require 'rake/testtask'
require 'rake/rdoctask'

task :default => :test

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

namespace :docs do
  Rake::RDocTask.new('generate') do |rdoc|
    rdoc.title = 'Authorization-San'
    rdoc.main = "README.rdoc"
    rdoc.rdoc_files.include('README.rdoc', 'lib/authorization')
    rdoc.options << "--all" << "--charset" << "utf-8"
  end
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "authorization-san"
    s.description = "A plugin for authorization in a ReSTful application."
    s.summary = "A plugin for authorization in a ReSTful application."
    s.email = "manfred@fngtps.com"
    s.homepage = "http://fingertips.github.com"
    
    s.authors = ["Manfred Stienstra"]
    s.files = %w(lib/authorization.rb lib/authorization/allow_access.rb lib/authorization/block_access.rb rails/init.rb README.rdoc LICENSE)
  end
rescue LoadError
end

begin
  require 'jewelry_portfolio/tasks'
  JewelryPortfolio::Tasks.new do |p|
    p.account = 'Fingertips'
  end
rescue LoadError
end