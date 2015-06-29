MATH_UNIQUE_EXERCISES =  Exercise.where(subject: 'math').map(&:level).uniq

puts "#{MATH_UNIQUE_EXERCISES.count}"
LEVELS = {}
MATH_UNIQUE_EXERCISES.each{
  |level| LEVELS[level] = Exercise.all.where(
    level: level
  ).map(&:topic).group_by{
    |topic| topic
  }
}
puts "Levels keys count: #{LEVELS.count}"