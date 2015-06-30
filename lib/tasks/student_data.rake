require 'rubygems'
require 'mechanize'
require 'json'
require 'net/http'
require 'nokogiri'
require 'open-uri'

task :fetch_codecademy => [:environment] do
  User.all.each do |u|
    url = "http://www.codecademy.com/users/#{u.email}/achievements"

    begin
      doc = Nokogiri::HTML(open( url ))

      @badges = []
      doc.css('.achievement-card').each do |l|
        name = l.css('h5').text
        @badges << name
      end

      unless @badges.empty?
        unless @badges[0].to_i == 0
          Badge.create!(
            badges: @badges[0].to_i,
            username: u.username,
            user_id: u.id,
            max_streak: @badges.last
          ) 
        end

      end
    rescue
      "Nope for #{u.username}"
    end

  end
end


task :update_khan_exercises => [:environment] do
  agent = Mechanize.new { |a|
  a.user_agent = 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:24.0) Gecko/20100101 Firefox/24.0'
  a.follow_meta_refresh = true
  }


  Exercise.where(subject: nil).each do |e|
    url      = e.content['ka_url']
    page     = agent.get(url)

    tutorial = page.search('*').select{|e| e[:class] =~ /tutorial-title/}.first.text
    topic    = page.search('*').select{|e| e[:class] =~ /no-underline topic-title/}.first.text 
    topic.gsub!(/^(\n\s+)/,'')
    topic.gsub!(/(\n\s+)$/,'')

    parts    = page.uri.to_s.split('/')
    subject  = parts[3]
    level    = parts[4]
    title    = parts.last
    e.update_attributes(subject: subject, level: level, topic: topic, tutorial: tutorial, title: title)
    puts "#{subject} #{level} #{topic} #{tutorial} - #{title}"
  end

end


task :get_khan_exercises => [:environment] do
  uri = URI('http://www.khanacademy.org/api/v1/exercises')
  s = Net::HTTP.get(uri)
  puts s
end


task :import_khan_lessons => [:environment] do
  f = File.new(Rails.root + 'lib/tasks/khan_math_lessons.txt')

  while (line = f.gets)
    line = line.split(/\t/)
    index, level, exercise, tutorial, topic = line
    Exercise.find_or_initialize_by(
      subject:  'math'  ,
      index:    index   ,
      level:    level   ,
      exercise: exercise,
      tutorial: tutorial,
      topic:    topic
    ).save!
  end

end

task :fetch_khan_data => [:environment] do
  a = Mechanize.new { |agent|
    agent.user_agent_alias = 'Linux Firefox'
  }

  EMAIL = 'mikefabrikant@gmail.com'
  PASSWD = 'TangoZouk!'

  agent = Mechanize.new{ |a| a.log = Logger.new("mech.log")}
  agent.user_agent_alias = 'Linux Mozilla'
  agent.open_timeout = 3
  agent.read_timeout = 4
  agent.keep_alive   = true
  agent.redirect_ok  = true
  LOGIN_URL = "https://www.google.com/accounts/Login?hl=en"

  login_page = agent.get(LOGIN_URL)
  login_form = login_page.forms.first
  login_form.Email = EMAIL
  login_form.Passwd = PASSWD
  login_response_page = agent.submit(login_form)
  
  khan = agent.get('https://www.khanacademy.org/login')
  
  # File.open('test.html', 'w') { |file| file.write(khan.body) }
  # khan.methods.each{|m| puts m}

  puts khan.body.inspect

  #redirect = login_response_page.meta[0].uri.to_s

  # puts redirect.split('&')[0..-2].join('&') + "&continue=https://www.google.com/"
  # followed_page = agent.get(redirect.split('&')[0..-2].join('&') + "&continue=https://www.google.com/adplanner")
  # pp followed_page


end


# Loop through user names and fetch duolingo history.
# Remove unneeded data to keep the record size small.
task :fetch_duolingo => [:environment] do
  a = Mechanize.new { |agent|
    agent.user_agent_alias = 'Linux Firefox'
  }
  User.all.each do |u|
    a.get("http://www.duolingo.com/users/#{u.username}") do |page|
      record = JSON.parse(page.body)
      lngs = record['languages'].map{|l| l['language']}
      calendar = []

      # Reduce text
      record['calendar'].each{|d| calendar << {
        i: d['improvement'], 
        d: d['datetime']}
      }

      record['calendar'] = calendar

      lngs.each do |l|
        if !!record['language_data'][l]
          record['language_data'][l]['skills'].each do |skill|
            skill['explanation'] = ''
            skill['known_lexemes'] = []
          end
          record['language_data'][l]['bonus_skills'].each do |skill|
            skill['explanation'] = ''
          end
        end
      end
      lesson            = Lesson.new
      lesson.source     = 'duolingo'
      lesson.created_at = DateTime.now()
      lesson.content    = record
      lesson.username   = u.username
      lesson.user_id    = u.id
      lesson.save!
      puts u.username
      sleep 1
    end
  end
end






