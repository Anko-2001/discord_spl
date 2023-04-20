require 'discordrb'
require 'date'
require 'json'
require 'open-uri'

TOKEN = ENV['discord-TOKEN']
ENV["TZ"] = "Asia/Tokyo"

REPORT_CHANNEL_ID = '1095004266319593472'
bot = Discordrb::Commands::CommandBot.new(token: TOKEN, prefix: '/')

def area_hash_fetch
  headers = {
  "accept" => "application/json",
  "user-agent" => "akno(twitter@ankonanoyone)"
  }
  json_url = "https://spla3.yuu26.com/api/x/schedule"
  x_json = OpenURI.open_uri(json_url, headers).read
  JSON.parse(x_json)
end

def area_time_arr(x_hash)
  start_time = []
  x_hash["results"].each do |match|
    if match["rule"]["name"] == 'ガチエリア'
      time_str = match["start_time"]
      datetime = DateTime.parse(time_str)
      start_time.push(datetime.hour)
    end
  end
  start_time
end

def before_area_alarm(*start_times, bot)
  now = Time.now.localtime
  if start_times.length == 1
    start_times = area_time_arr(area_hash_fetch)
  end
  start_times.each do |start_time|
    if (start_time.to_i - 1) == now.hour && 50 == now.min
      channel = bot.channel(REPORT_CHANNEL_ID)
      channel.send_message("#{start_time}時からエリア始まるよ")
    end
  end  
end

def area_str(x_hash)  
  res = ""
  x_hash["results"].each do |match|
    if match["rule"]["name"] == 'ガチエリア'
      time_str = match["start_time"]
      datetime = DateTime.parse(time_str)
      end_time = datetime + Rational(2, 24)
      formatted_str = "#{datetime.day}日#{datetime.hour}時～#{end_time.hour}時"
      res.concat("#{formatted_str}\n #{match["stages"][0]["name"]} #{match["stages"][1]["name"]}\n")
    end
  end
  res
end

bot.command :area do |event|
  event.respond area_str(area_hash_fetch)
end

bot.run(:async)

while true
  now = Time.now.localtime
  if now.hour == 10 && now.min == 30
    channel = bot.channel(REPORT_CHANNEL_ID)
    area_hash = area_hash_fetch
    channel.send_message("#{area_str(area_hash)}")  
    time_arr = area_time_arr(area_hash)
  end
  before_area_alarm(time_arr, bot)
  sleep 60
end
