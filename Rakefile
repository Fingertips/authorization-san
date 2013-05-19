require 'rake/testtask'
require 'rake/rdoctask'

task :default => :test

namespace :test do
  test_files = Dir.glob("test/**/*_test.rb")
  
  Rake::TestTask.new(:rails2) do |t|
    t.libs += %w(test test/test_helper/rails2)
    t.test_files = test_files
    t.verbose = true
  end
  
  desc 'Test the plugin with Rails 3.'
  Rake::TestTask.new(:rails3) do |t|
    t.libs += %w(test test/test_helper/rails3)
    t.test_files = test_files
    t.verbose = true
  end
  
  desc 'Test the plugin with Rails 3.1.'
  Rake::TestTask.new(:rails31) do |t|
    t.libs += %w(test test/test_helper/rails3.1)
    t.test_files = test_files
    t.verbose = true
  end

  desc 'Test the plugin with Rails 3.2.'
  Rake::TestTask.new(:rails32) do |t|
    t.libs += %w(test test/test_helper/rails3.2)
    t.test_files = test_files
    t.verbose = true
  end
end

desc 'Run all tests'
if RUBY_VERSION < '2.0.0'
  task :test => ['test:rails2', 'test:rails3', 'test:rails31', 'test:rails32']
else
  task :test => ['test:rails32']
end

namespace :docs do
  Rake::RDocTask.new('generate') do |rdoc|
    rdoc.title = 'Authorization-San'
    rdoc.main = "README.rdoc"
    rdoc.rdoc_files.include('README.rdoc', 'lib/authorization')
    rdoc.options << "--all" << "--charset" << "utf-8"
  end
end

namespace :travis do
  # Install all Gem dependencies
  task :install do
    sh "./install.sh"
  end

  # Install dependencies and run all tests
  task :run => %w(travis:install test)
end
