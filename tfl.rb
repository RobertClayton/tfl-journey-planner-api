require 'net/http'
require 'json'
require 'pry'
require 'time'

class Tfl
  attr_reader :beckenham_junction, :victoria, :national_rail_status

  def initialize
    @beckenham_junction = '1001018'
    @victoria = '1000248'
    @national_rail_status = get_parse(URI('https://api.tfl.gov.uk/line/mode/national-rail/status'))
  end

  def get_parse(url)
    JSON.parse(Net::HTTP.get(url))
  end

  def journey_times(from, to)
    line = get_parse(URI("https://api.tfl.gov.uk/journey/journeyresults/#{from}/to/#{to}"))

    line['journeys'].map do |journey|
      {
        depart: Time.parse(journey['startDateTime']).strftime('%I:%M'),
        arrive: Time.parse(journey['arrivalDateTime']).strftime('%I:%M'),
        duration: journey['duration'],
        is_disrupted: journey['legs'].first['isDisrupted'],
        disruptions: journey['legs'].first['disruptions'],
        planned_works: journey['legs'].first['plannedWorks']
      }
    end
  end

  def rail_status(line)
    national_rail_status.select {|a| a['id'] == line}.first['lineStatuses'].first['statusSeverityDescription']
  end

  def puts_journey(journey)
    journey.each do |j|
      text = "Departs: #{j[:depart]}, Arrives: #{j[:arrive]}, Duration: #{j[:duration]}"
      text += ", Disrupted?: #{j[:is_disrupted]}, Disruptions: #{j[:disruptions]}" if j[:is_disrupted]
      text += ", Disruptions: #{j[:disruptions]}" if j[:is_disrupted]

      puts text
    end
  end

  def print_statuses
    victoria_journey = journey_times(beckenham_junction, victoria)
    southeastern_status = "SouthEastern: #{rail_status('southeastern')}"
    thameslink_status = "Thameslink: #{rail_status('thameslink')}"

    puts 'Beckenham -> Victoria'
    puts_journey(victoria_journey)
    puts southeastern_status
    puts thameslink_status
  end
end

Tfl.new.print_statuses
