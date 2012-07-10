require './link'

task :migrate do
  ActiveRecord::Migrator.migrate('db', ENV['VERSION'] ? ENV['VERSION'].to_i : nil)
end
