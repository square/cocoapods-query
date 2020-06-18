# frozen_string_literal: true

require 'cocoapods'
require 'json'
require 'yaml'

module Pod
  class Command
    class Query < Command
      self.summary = 'Shows pods in the project filtered by name or other attribute'
      self.description = <<-DESC
        This command starts by finding all pods in the project, then filters out those that do not match
        the specified criteria, and finally returns the results. In other words, the output is all pods
        that satisfy the intersection of all search terms. (It returns all pods in the project if no
        parameters are given.)

        The starting list of pods comes either from the current instance or from a previously created cache
        in YAML format (if --from-yaml is given). The output is either a list of pod names or a file containing
        pod data in YAML format (if --to-yaml is given).

        You can modify how the search terms are handled by specifying the optional --case-insensitive or
        --substring flags. They apply to all search terms.
      DESC

      def self.options
        [
          ['--name=NAME', 'Include pods whose name matches the given string'],
          ['--version=VERSION', 'Include pods whose version matches the given string'],
          ['--author-email=EMAIL', 'Include pods having at least one author with the given email'],
          ['--author-name=NAME', 'Include pods having at least one author of the given name'],
          ['--summary=SUMMARY', 'Include pods whose summary matches the given string'],
          ['--description=DESCRIPTION', 'Include pods whose description matches the given string'],
          ['--source-file=FILE', 'Include pods whose source list includes the given file name'],
          ['--swift', 'Only include pods that use Swift (--no-swift for only pods that do not)'],
          ['--local', 'Only include locally sourced pods (--no-local for only remote pods)'],
          ['--case-insensitive', 'Don\'t consider case when matching strings'],
          ['--substring', 'Allow substring matching for string parameters'],
          ['--to-yaml=FILE', 'Output the results in YAML format with additional Podspec data (authors, source files, dependencies, etc.) to the given file'],
          ['--to-json=FILE', 'Output the results in JSON format with additional Podspec data (authors, source files, dependencies, etc.) to the given file'],
          ['--cache=FILE', 'Load the sandbox data from the given YAML file (created previously with the --to-yaml parameter) instead of from the current sandbox instance']
        ].concat(super)
      end

      def initialize(argv)
        super
        @name = argv.option('name')
        @version = argv.option('version')
        @author_email = argv.option('author-email')
        @author_name = argv.option('author-name')
        @summary = argv.option('summary')
        @description = argv.option('description')
        @source_file = argv.option('source-file')
        @swift = argv.flag?('swift')
        @local = argv.flag?('local')
        @case_insensitive = argv.flag?('case-insensitive', false)
        @substring = argv.flag?('substring', false)
        @to_yaml = argv.option('to-yaml')
        @to_json = argv.option('to-json')
        @cache = argv.option('cache')
      end

      def run
        UI.puts 'Loading targets...'

        matching_targets = all_targets(@cache).select do |target|
          (@name.nil? || str_match(@name, target[:name])) &&
            (@version.nil? || str_match(@version, target[:version])) &&
            (@author_name.nil? || target[:authors].any? { |author| !author[:name].nil? && str_match(@author_name, author[:name]) }) &&
            (@author_email.nil? || target[:authors].any? { |author| !author[:email].nil? && str_match(@author_email, author[:email]) }) &&
            (@summary.nil? || str_match(@summary, target[:summary])) &&
            (@description.nil? || str_match(@description, target[:description])) &&
            (@source_file.nil? || target[:source_files].nil? || target[:source_files].any? { |s| str_match(@source_file, s) }) &&
            (@swift.nil? || @swift == target[:uses_swift]) &&
            (@local.nil? || @local == target[:local])
        end

        File.open(@to_yaml, 'w') { |file| file.write(matching_targets.to_yaml) } if @to_yaml
        File.open(@to_json, 'w') { |file| file.write(matching_targets.to_json) } if @to_json

        matching_targets.each { |target| UI.puts target[:name] }
      end

      private

      # Returns an array of all pods in the sandbox. Each element in the array is a hash with
      # metadata about the pod such as version, authors, source files, dependencies, and more.
      #
      # @note For projects with a large dependency graph, this function can take a long time to
      #       run if a cache is not given.
      #
      # @param [String] target_cache
      #        If non-nil, the targets are loaded from this file instead of from the current
      #        sandbox instance. The file should contain the YAML-encoded results of a previous
      #        call to this function.
      #
      # @return [Array<Hash>] an array of hashes containing pod metadata
      def all_targets(target_cache)
        return YAML.safe_load(File.read(target_cache), permitted_classes: [Symbol]) unless target_cache.nil?

        targets = Pod::Config.instance.with_changes(silent: true) do
          Pod::Installer.targets_from_sandbox(
            Pod::Config.instance.sandbox,
            Pod::Config.instance.podfile,
            Pod::Config.instance.lockfile
          ).flat_map(&:pod_targets).uniq
        end

        targets.map do |target|
          file = target.sandbox.local_podspec(target.pod_name)
          swift_versions = target.root_spec.swift_versions
          file_accessor = target.file_accessors.find { |accessor| accessor.spec.root == target.root_spec }
          dependencies = target.root_spec.dependencies.map(&:name)

          {
            name: target.name,
            version: target.version,
            authors: target.root_spec.authors.map { |name, email| { name: name, email: email }.compact },
            is_local: target.sandbox.local?(target.name),
            root_directory: file_accessor.root.to_s,
            podspec_file: file ? file.relative_path_from(file_accessor.root).to_s : nil,
            license: target.root_spec.license,
            summary: target.root_spec.summary,
            description: target.root_spec.description,
            homepage: target.root_spec.homepage,
            uses_swift: target.uses_swift?,
            swift_versions: swift_versions.empty? ? nil : swift_versions.map(&:to_s),
            readme_file: file_accessor.readme.to_s.empty? ? nil : file_accessor.readme.relative_path_from(file_accessor.root).to_s,
            platforms: target.root_spec.available_platforms.map { |platform| { name: platform.symbolic_name, version: platform.deployment_target.to_s } },
            dependencies: dependencies.empty? ? nil : dependencies,
            source_files: file_accessor.source_files.map { |pathname| pathname.relative_path_from(file_accessor.root).to_s }
          }.compact
        end
      end

      def str_match(str1, str2)
        if @case_insensitive
          str1 = str1.downcase
          str2 = str2.downcase
        end

        @substring ? str2.include?(str1) : str1 == str2
      end
    end
  end
end
