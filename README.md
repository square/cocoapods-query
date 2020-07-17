# Introduction

This plugin for CocoaPods helps locate pods in a project. It can show all pods or filter them based on some search term, such as author name, source file, dependency, and more. It is intended for projects with a large number of dependencies.

The plugin's output can be saved to YAML format for easy parsing by other tools (e.g. a CocoaPods GUI).

# Installation

Add this line to your application's Gemfile:

    gem 'cocoapods-query'

And then run:

    $ bundle

Or, install it system-wide with:

    $ gem build cocoapods-query.gemspec
	$ gem install cocoapods-query-1.0.0.gem

Or, in a single command:

    $ bundle exec rake install

# Usage

The plugin adds a `query` command to CocoaPods. You can get help on its parameters with:

    $ pod query --help

By default, the command lists all pods in the sandbox. This list can be filtered by one of several search terms. Here are some examples:

What pods contain the string "testing" in their name?

    $ pod query --name=testing --substring --case-insensitive

What pods have a direct dependency on Foo?

    $ pod query --dependency=Foo

What pods were created by hacker@example.com?

    $ pod query --author-email=hacker@example.com

What pods contain a source file named `HelloWorld.swift`?

    $ pod query --source-file=HelloWorld.swift --substring

# Caching

Finding pods in the CocoaPods project can take a long time when there are many dependencies. To speed things up, the `query` command accepts a `--cache` parameter, which is used to specify a YAML file containing previous output from the `--to-yaml` parameter. When the plugin sees the `--cache` parameter, it will use the data in this file instead of rebuiding the data from the current CocoaPods instance.

# Related Work

This plugin provides features that are similar to, and in some cases overlapping with, existing CocoaPods plugins.

* [list](https://guides.cocoapods.org/terminal/commands.html#pod_list), [search](https://github.com/CocoaPods/cocoapods-search), and [spec cat/which](https://guides.cocoapods.org/terminal/commands.html#pod_spec_cat): These commands look at all available pods, not just those in the sandbox, and they ignore local pods. The `search` command applies to all fields and cannot match a particular field.
* [cache list](https://guides.cocoapods.org/terminal/commands.html#pod_cache_list): Similar to `query --to-yaml` but does not provide filtering and outputs a limited set of data.
* [info](https://github.com/cocoapods/cocoapods-podfile_info): Similar to `query --to-yaml` but is old, unmaintained, and limited in options.
* [search sort](https://github.com/DenTelezhkin/cocoapods-sorted-search): Similar to `list` or `search` but allows sorting by stars, forks, or activity.

# Development

For local development of this plugin, the simplest approach is to install it into an existing app via absolute path. For example, if the code is in a directory called `projects/cocoapods-query` off the home directory, add the following line to the app's Gemfile:

    gem 'cocoapods-query', path: "#{ENV['HOME']}/projects/cocoapods-query"

You can then make changes to the code and they will be executed when using the `query` command from the app's directory.

# Copyright

Copyright 2020 Square, Inc.
