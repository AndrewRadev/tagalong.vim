task :default do
  if ENV['TRAVIS_CI']
    sh 'xvfb-run rspec spec'
  else
    sh 'rspec spec'
  end
end

desc "Prepare archive for deployment"
task :archive do
  puts "TODO"
  # sh 'zip -r ~/tagalong.zip doc/tagalong.txt'
end
