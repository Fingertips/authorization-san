# encoding: utf-8

Gem::Specification.new do |s|
  s.name = "authorization-san"
  s.version = "2.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Manfred Stienstra"]
  s.date = "2012-06-22"
  s.description = "A plugin for authorization in a ReSTful application."
  s.email = "manfred@fngtps.com"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    "LICENSE",
    "README.rdoc",
    "lib/authorization.rb",
    "lib/authorization/allow_access.rb",
    "lib/authorization/block_access.rb",
    "lib/authorization/deprecated.rb",
    "rails/init.rb"
  ]
  s.homepage = "http://fingertips.github.com"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.18"
  s.summary = "A plugin for authorization in a ReSTful application."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

