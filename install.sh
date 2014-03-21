#!/bin/sh

ruby_version=`ruby -e "print(RUBY_VERSION < '2.0.0' ? '1' : '0' )"`

if [ $ruby_version -eq 1 ]; then
  yes | gem install rails --version "~> 2.3.0"
  yes | gem install rails --version "~> 3.0.0"
  yes | gem install rails --version "~> 3.1.0"
  rm -f `which rails`
  yes | gem install rails --version "~> 3.2.0"
else
  yes | gem install rails --version "~> 3.2.0"
  yes | gem install rails --version "~> 4.0.0"
fi