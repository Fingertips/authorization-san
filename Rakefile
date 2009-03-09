require 'rake/testtask'
require 'rake/rdoctask'

task :default => :test

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

namespace :docs do
  Rake::RDocTask.new('generate') do |rdoc|
    rdoc.main = "README.rdoc"
    rdoc.rdoc_files.include('README.rdoc', 'lib/authorization', 'lib/authorization/allow_access.rb', 'lib/authorization/block_access.rb')
    rdoc.options << "--all" << "--charset" << "utf-8"
  end
end