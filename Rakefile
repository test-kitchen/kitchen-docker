require "bundler/gem_tasks"

desc "Display LOC stats"
task :stats do
  puts "\n## Production Code Stats"
  sh "countloc -r lib"
end

desc "Run all quality tasks"
task quality: [:stats]

task default: [:quality]

# Create the spec task.
require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:test, :tag) do |t, args|
  t.rspec_opts = [].tap do |a|
    a << "--color"
    a << "--format #{ENV["CI"] ? "documentation" : "Fuubar"}"
    a << "--backtrace" if ENV["VERBOSE"] || ENV["DEBUG"]
    a << "--seed #{ENV["SEED"]}" if ENV["SEED"]
    a << "--tag #{args[:tag]}" if args[:tag]
    a << "--default-path test"
    a << "-I test/spec"
  end.join(" ")
end
