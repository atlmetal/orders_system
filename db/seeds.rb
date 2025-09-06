puts 'Creating test users...'

# regular user
User.find_or_create_by(email: 'user@test.com') do |user|
  user.password = 'password123'
  user.role = 'user'
end

# admin user
User.find_or_create_by(email: 'admin@test.com') do |user|
  user.password = 'admin123'
  user.role = 'admin'
end

# user without permissions
User.find_or_create_by(email: 'guest@test.com') do |user|
  user.password = 'guest123'
  user.role = 'guest'
end

puts 'Test users created:'
User.all.each do |user|
  puts "- #{user.email} (#{user.role})"
end
