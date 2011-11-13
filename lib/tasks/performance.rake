require 'benchmark'

namespace :performance do
  task :seed_photos do
    require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment"))
    Benchmark.bm do |x|
      x.report do
        1000.times do |j|
          puts "."
          1000.times do |i|
            Photo.connection.execute("INSERT INTO photos (gender) VALUES ('#{i.odd? ? "m" : "f"}');")
          end
        end
      end
    end
  end
end
