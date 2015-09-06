# PureSender

PureSender is web application for send regular reports.

## Installation

Clone from github and bundle:

    git clone https://github.com/yurakawa/PureSender.git

    cd PureSender/
    bundle install --path .bundle --without development test

## Usage

Setup:

    vi config/configuration.yml # => edit settings
    bundle exec rake setup # => create database and root user

exec:

    bundle exec rackup 
    
Clean deleted files:

    bundle exec rake clean


