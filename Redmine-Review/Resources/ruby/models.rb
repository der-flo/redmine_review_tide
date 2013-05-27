# encoding: utf-8
require 'multi_xml'
require 'open-uri'


class Ticket < Struct.new(:id_and_anchor, :title)
  attr_reader :items
  attr_accessor :widget
  def initialize(id, title)
    super
    @items = []
  end
  def << item
    @items << item
  end
  def last_time
    items.collect(&:time).max
  end
  def link
    items.last.link
  end
  def id
    id_and_anchor.to_i
  end

  def self.fetch(hostname, auth_token, uninteresting_projects)
    url = "http://#{hostname}/projects/familie/activity.atom?key=#{auth_token}"
    doc = MultiXml.parse(open(url))

    last_time = last_time_from_file

    tickets = {}

    doc['feed']['entry'].each do |entry|

      time = Time.xmlschema(entry['updated'])
      next if time <= last_time

      author = entry['author']['name']
      next if author == 'Florian Dütsch'

      content = entry['content'] ? entry['content']['__content__'] : nil

      link = entry['link']['href']
      id_and_anchor = link.match(/issues\/(\d+)/)[1]
      title = entry['title']

      unless uninteresting_projects.empty?
        # Only works for our custom redmine installation
        project_name = /\A(.*) - /.match(title)[1]
        next if uninteresting_projects.include?(project_name)
      end

      tickets[id_and_anchor.to_i] ||= Ticket.new(id_and_anchor, title)
      tickets[id_and_anchor.to_i] << Item.new(author, link, content, time)
    end
    tickets.values
  end
  def self.confirm last_time
    File.open(last_time_file, 'w') { |f| f.write(last_time.to_i) }
  end

  def self.last_time_file
    "#{Ti.Filesystem.getUserDirectory.nativePath}/.rrt"
  end

  def self.last_time_from_file
    if File.exist? last_time_file
      Time.at(File.read(last_time_file).to_i)
    else
      0
    end
  end
end

class Item < Struct.new(:author, :link, :content, :time)
  def content?
    content && !content.empty?
  end
end
