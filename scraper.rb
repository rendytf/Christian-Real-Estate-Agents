#!/usr/bin/ruby

require 'mechanize'
require 'csv'

class Scraper
  def self.result
    agent = Mechanize.new
    agent.user_agent = 'Mac Safari'
    agent.idle_timeout = 0.5
    agent.ignore_bad_chunking = true
    agent.keep_alive = false

    url = "https://christianrealestateagents.us/category/state/ca/page/"

    CSV.open("result.csv", "wb") do |csv|
      1.upto(27).each do |n|
        new_url = url + n.to_s

        puts new_url

        begin
          page = agent.get new_url
        rescue Mechanize::ChunkedTerminationError => e
          page = e.force_parse
        end

        sleep 2

        my_links = page.body.scan(/<a.*?href="(.*?)".*?rel="bookmark".?>/).flatten.uniq

        puts "#{my_links}:"
        l = my_links

        l.each_with_index do |line, index|
          puts line
          page = agent.get line
          page.save! "log/#{index}.html"
          #exit

          data = []

          full_name = page.search("//span[contains(@style, 'font-weight: bold; font-size: 2em;')]").text
          city = page.search("//span[contains(@style, 'font-size: 1.2em; font-weight: bold;')]/following-sibling::text()[1]").text.strip
          website_link = page.search("//a[contains(@style, 'font-weight: normal;')]").text.strip
          email = page.search("//span[contains(text(), 'Email')]/following-sibling::text()[1]").text
          office = page.search("//span[contains(text(), 'Office')]/following-sibling::text()[3]").text
          mobile = page.search("//span[contains(text(), 'Mobile')]/following-sibling::text()[1]").text
          license = page.search("//span[contains(text(), 'Real Estate License No.')]/following-sibling::text()[1]").text
          content = page.search("//div[contains(@style, 'margin: 0 60px; width: auto;')]").text
          img = page.search("//img[contains(@alt, 'agent portrait')][1]").attr("src").value

          email.sub!(/:/, '').strip if email
          office.sub!(/:/, '')
          
          if office 
            office.strip
          end
          
          if mobile
            mobile.sub!(/:/, '')
            mobile.strip
          end 

          if license
            license.sub!(/:/,'')
            license.strip
          end

          csv << [line, full_name, email, office, mobile, license, city, website_link, img, content]
          # break if index == 2
        end
      end
    end
  end
end

Scraper.result