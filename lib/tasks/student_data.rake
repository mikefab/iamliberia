require 'rubygems'
require 'mechanize'
require 'json'


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






