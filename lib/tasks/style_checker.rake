# frozen_string_literal: true

RUBY = /\.(rb)|(rake)$/
RUBY_PASS = %w(true no\ offenses files\ found).freeze

EXISTING_FILES = /^[^D].*/
FILE = /^[A-Z].*\t(.*)$/

DIFF_CMD = 'git diff master --name-status'

desc 'Style checks files that differ from master'
task :check_style do
  puts diff_output
  puts "\nRunning rubocop..."
  puts check_ruby
  exit evaluate
end

def diff_output
  "Files found in the diff:\n#{diff.join("\n")}\n"
end

def check(type:, regex:, checker:)
  files = files_that_match regex
  return "No #{type} files found!" if files.empty?
  "#{send(checker, files)}\n#{system send(checker, files)}\n"
end

def check_ruby
  @ruby_results ||= check(type: 'ruby', regex: RUBY, checker: :rubocop)
end

def evaluate
  return 0 if passed?
  1
end

def passed?
  RUBY_PASS.any? { |m| check_ruby.include? m }
end

def rubocop(files)
  "rubocop -D --force-exclusion #{files}"
end

def diff
  @diff ||= process_diff
end

def diff_cmd
  @cmd ||= ARGV[1] || DIFF_CMD
end

def process_diff
  raw = `#{diff_cmd}`
  existing_files = raw.split("\n").grep(EXISTING_FILES)
  existing_files.map! { |f| FILE.match(f) }.compact!
  existing_files.map { |f| f[1] }
end

def files_that_match(regex)
  diff.grep(regex).join(' ')
end
