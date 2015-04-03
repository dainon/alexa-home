require 'sinatra'
require 'yaml'

require './helpers'

modules = YAML.load_file('config.yml')['modules']
#require './modules/lights' if modules.include? 'hue'
require './modules/philips_hue_lights' if modules.include? 'hue'
require './modules/temperature' if modules.include? 'nest'
require './modules/iRiver_player' if modules.include? 'iriver'
require './modules/uber' if modules.include? 'uber'

require 'numbers_in_words'
require 'numbers_in_words/duck_punch'

ALEXAPHILIPSHUE = AlexaPhilipsHue.new;
#ALEXAPHILIPSHUE.DestroyGroup("All")

def process_query(command)
  puts "*** Process Query ***"
  puts command
  puts "*********************"

  # HUE LIGHTS #
  if command.scan(/light|lights/).length > 0
    ALEXAPHILIPSHUE.ProcessLights(command)
  elsif command.scan(/brightness|saturation/).length > 0
    ALEXAPHILIPSHUE.ProcessLights(command)
  # NEST #
  elsif command.scan(/temperature|nest/).length > 0
    process_temperature(command)
  elsif command.scan(/river/).length > 0
    process_player(command, player: "iriver")
  elsif command.scan(/cab to/).length > 0
    process_uber(command)
  end
end

get '/command' do
  process_query(params[:q])
end

get '/status' do
  status 200
end
