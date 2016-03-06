#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_api'

$root_url = 'http://genome3d.eu/'
$owner_org = 'genome-3d'
$lessons = {}
$debug = Config.debug?


def parse_data(page)
  # As usual, use a local page for testing to avoid hammering the remote server.
  if $debug
    puts 'Opening local file.'
    begin
      f = File.open("genome3d.html")
      doc = Nokogiri::HTML(f)
      f.close
    rescue
      puts 'Failed to open genome3d.html file.'
    end
  else
    puts "Opening: #{$root_url + page}"
    doc = Nokogiri::HTML(open($root_url + page))
  end

  # Now to obtain the exciting course information!
  #links = doc.css('#wiki-content-container').search('li')
  #links.each do |li|
  #  puts "LI: #{li}"
  #end

  links = doc.css('#wiki-content-container').search('ul').search('li')
  links.each do |link|
     if !(a = link.search('a')).empty?
        href = a[0]['href'].chomp
        name = a.text
        puts "Name = #{a.text}" if $debug
        puts "URL = #{a[0]['href'].chomp}" if $debug
        description = nil
        if !(li = link.search('li')).empty?
             description = li.text
             puts "Description = #{li.text}" if $debug
        end
        $lessons[href] = {}
        $lessons[href]['name'] = name
        $lessons[href]['description'] = description
     end
  end
end

# parse the data
parse_data('tutorials/page/Public/Page/Tutorial/Index')

cp = ContentProvider.new("Genome 3D", "http://genome3d.eu/",
 "https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcQwd3d_tBGpERIc1QYAWERLLdesDHr-k41oASnaoNHzLVXVBPtYaQ", 
 "Genome3D provides consensus structural annotations and 3D models for sequences from model organisms, including human.
  These data are generated by several UK based resources in the Genome3D consortium:
   SCOP, CATH, SUPERFAMILY, Gene3D, FUGUE, THREADER, PHYRE.")
cp = Uploader.create_or_update_content_provider(cp)

# Create the new record
$lessons.each_key do |key|
  material = Material.new(title = $lessons[key]['name'],
                          url = $root_url + key,
                          short_description = $lessons[key]['description'], #"#{$lessons[key]['name']} from #{$root_url + key}, added automatically.",
                          doi = nil,
                          remote_updated_date = Time.now,
                          remote_created_date = $lessons[key]['last_modified'],
                          content_provider_id = cp['id'],
                          scientific_topic = [],
                          keywords = [])

  check = Uploader.check_material(material)
  puts check.inspect

  if check.empty?
    puts 'No record by this name found. Creating it...'
    result = Uploader.create_material(material)
    puts result.inspect
  else
    puts 'A record by this name already exists. Updating!'
    material.id = check['id']
    result = Uploader.update_material(material)
    puts result.inspect
  end
end


