#! /usr/bin/env ruby

require "mechanize"
require "json"
require 'rotp'
require 'watir'
require 'watir-webdriver'
require 'io/console'
require 'headless'
require 'yaml'

BASE_URL = "https://mvideox.stanford.edu/Graduate"

# get_2f_code
# checks settings for the 2 factor "secret" and generates code if the "secret" doesn't exist asks user for code.
def get_2f_code
  if @settings["access_code"]
    security = ROTP::TOTP.new(@settings["access_code"])
    code =  security.now
    return code
  else
    print "Enter two factor auth token: "
    code = $stdin.readline.strip
    return code
  end
end

# puts_disclaimer
# outputs the Stanford Copyright disclaimer to the console.
def puts_disclaimer
      puts "Copyright\n" +
            "The materials provided to you by the Stanford Center for Professional Development are copyrighted\n" +
            "to Stanford University. Stanford grants you a limited license to use the materials solely in connection\n" +
            "with the course for your own personal educational purposes. Any use of the materials outside of the\n" +
            "course may be in violation of copyright law. You agree that you will not post, share or copy the materials.\n" +
            "You agree that you will only save the materials for the duration of the course.\n\n"

      puts "Penalties for Misuse\n"

      puts "Penalties for copyright infringement can be harsh. Fines of up to $150,000 in civil statutory damages may apply\n" +
           "for each separate willful infringement, regardless of the actual damages involved. Stanford may also take\n" +
           "administrative action against copyright infringement, including loss of networking privileges and SUNet ID,\n" +
           "or disciplinary action up to and including termination for faculty and staff, and expulsion for students.\n"
end


# parse_args
# read in basic arguments from the command line.
def parse_args
  if ARGV.length > 1
    department       = ARGV[0]
    c_name           = ARGV[1]
    start_lec_num    = ARGV[2] if ARGV.length > 2
    end_lec_num      = ARGV[3] if ARGV.length > 3

    return {:department => department, :course => c_name, :start_lec_num => start_lec_num, :end_lec_num => end_lec_num}
  else
    if ARGV.length == 1 && ARGV[0] == "-h"
      puts "SCPD Downloader. This script is used to download scpd videos from the Stanford scpd website for offline viewing."
      puts "These videos are to be used for educational purposes only in occordance to the policy from\n" +
           "The SCPD website below and should only be used while enrolled in the course:"

      puts_disclaimer

      puts "\n\n"
      puts "Usage:"
      puts "Optionally, use a config/config.yml file for username and password. see config_example.yml for an example\n"

      puts "download.rb '[department]' '[full course name]'"
      puts "\t Downloads all available videos from the specified course in the specified department. Note, the department\n" +
           "\t And course name need to be exactly as specified on the SCPD page. Script will exit on invalid input."
      puts "\n"
      puts "download.rb '[department]' '[full course name]' n"
      puts "\t Downloads the nth available video from the specified course in the specified department. Note, the department\n" +
           "\t and course name need to be exactly as specified on the SCPD page."
      puts "\n"
      puts "download.rb '[department]' '[full course name]' i j"
      puts "\t Downloads the the range of videos i up to j that are  available video from the specified course in the specified \n" +
           "\t department. Note, the department and course name need to be exactly as specified on the SCPD page."
    else
      puts "Invalid Arguments: Usage: download.rb '[department]' '[full course name]'"
      exit
    end
  end
end

# main
# starts the watir browser, finds links, then starts the download of these links.
def main
  @args = parse_args

  browser = Watir::Browser.new #:chrome
  browser.driver.manage.timeouts.implicit_wait=5

  auth(browser)

  lecture_urls = find_lecture_urls(browser)
  browser.close

  download(lecture_urls)
end

# quit
# in the case of an error, closes the browser, outputs the error, and exits the script
def quit(browser, error)
  browser.close
  puts error
  exit
end

# check_agreement
# checks to see if the browser has navigated to the user agreement page.
# if so, ensures that either a) the user has specified to always agree to the disclaimer in the settings file
# b) or the asks the user to agree to Stanford's terms of use.

def check_agreement(browser)
  if browser.title =~ /User Agreement/
    if @settings[:always_agree] != "true"
      puts_disclaimer

      print "\nType AGREE (all caps) to agree to these terms: "
      agree = $stdin.readline.strip
      if agree != "AGREE"
        quit(browser, "You must agree to Stanford's terms of use.")
      end
    end
    browser.button(:text => /(?:agree|AGREE)/).click
  end
end

# find_lecture_urls
# navigates the watir browser to the correct page in order to find the urls for the lectures.
def find_lecture_urls(browser)
  begin
    browser.ul(:class => "scpd-video-courses-categories").li(:text => /#{@args[:department]}/).link.fire_event('onclick')
  rescue => e
    puts e
    quit(browser,"The department '#{@args[:department]}' couldn't be found") unless browser.div(:class => "heading-left").text == @args[:department]
  end

  begin
    browser.div(:class => "scpd-video-courses-listing").ul.li(:text => /#{@args[:course]}/mi).link.fire_event('onclick')
  rescue => e
    puts e
    quit(browser, "The course '#{@args[:course]}' could not be found.")
  end

  quit(browser, "You do not have access to this class") if browser.html =~ /access is restricted to enrolled students/

  # check the User Agreement
  check_agreement(browser)

  browser.link(:href => "#course-sessions").click
  sleep(2)
  btns = browser.links(:class => "btn", :text => /watch/i)
  num_lectures = btns.length

  lecture_urls = {}

  btns.each_with_index do |btn, i|
    res = JSON.parse(btn.attribute_value("data-resolution"))["url"]
    lecture_urls[num_lectures - i] = [res[0]["mp4-url"], res[1]["mp4-url"]]
  end
  return lecture_urls
end

# get_user
# grabs username from either the console or from the settings.yml file
# saves (momentarily) for use in downloading.
def get_user
  if !@settings["username"]
    print "Username: "
    @settings["username"] = $stdin.readline.strip
  end
  return @settings["username"]
end

# get_pw
# grabs password from either the console or from the settings.yml file.
# saves (momentarily) for use in downloading.
def get_pw
  if !@settings["password"]
    print "password: "
    @settings["password"] = STDIN.noecho(&:gets).strip
    puts "\nsubmitting form"
  end
  return @settings["password"]
end

# auth
# authenticates the WATIR web browser with username/password and two factor auth code.
def auth(browser)
  # load settings
  @settings =  File.exists?("config/config.yml") ? YAML.load_file("config/config.yml") : {}
  browser.goto BASE_URL

  browser.text_field(:name => 'username').set get_user
  browser.text_field(:name => "password").set get_pw
  browser.button(:name => 'Submit').click


  #this is rude crude and unattractive, but I'm lazy.
  quit(browser, "Username or password incorrect") if browser.html =~ /I use this machine regularly/

  if browser.html =~ /Send SMS/
    browser.button(:name => "send").click
  end

  browser.text_field(:id => "otp").set get_2f_code
  browser.button(:name => 'send').click
  sleep(2)
  quit(browser, "Invalid two factor auth code") if browser.title == "Stanford WebLogin"
end

# auth_downloader
# as we'reusing mechanize to do downloads, authenticate with user/password/auth_token
# for this one too.
def auth_downloader(page, agent)
  while page.content =~ /I use this machine regularly/
    form = page.form("login")
    form.username = @settings["username"]
    form.password = @settings["password"]
    page = agent.submit(form, form.buttons.first)
  end

  while page.content =~ /Two-step authentication/
    form = page.form("login")
    form.otp = get_2f_code
    page = agent.submit(form, form.buttons.first)
  end
  return page, agent
end

def download(lectures)
  agent = Mechanize.new
  agent.pluggable_parser.default = Mechanize::Download
  page = agent.get(BASE_URL)

  auth_downloader(page, agent)

  count = 0
  lectures.each do |id, types|
    if (@args[:start_lec_num] && @args[:end_lec_num] && id >= @args[:start_lec_num].to_i && id <= @args[:end_lec_num].to_i) ||
       (@args[:start_lec_num] && @args[:end_lec_num] == nil && id == @args[:start_lec_num].to_i)
       quality = 0
       quality = 1 if @settings["quality"] == 720
       file_name = types[quality].split('/')[-1]
       if !File.exist?(file_name)
        puts "downloading lecture - #{id}:  #{file_name}"
        agent.get(types[0]).save(file_name)
        count += 1
      else
        puts "File '#{file_name}' already exists, skipping download."
      end
    end
  end
  puts "#{count} lecture#{"s" if (count > 1 || count == 0)} downloaded."
end

# run that stuff.

if __FILE__ == $0
  main
end
