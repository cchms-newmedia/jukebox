require 'sinatra'
require 'twitter'
require 'redis'

module Jockey
  class App < Sinatra::Base
    set :listeners, []
    set :html_listeners, []
    #Twitter.configure do |config|
    #   config.consumer_key = 'm0tB58uESKy8CYO146DeA'
    #   config.consumer_secret = 'E0LSzdywosN5QqIJBTQs1qneuUch7ZecNtbjAj4vQ'
    #   config.oauth_token = '19389841-7H13GQhpkohRRcUYW1wSU74zl8iJuVCjloXFLMfEc'
    #   config.oauth_token_secret = 'CIkyHenJmvkhp4yg6PpRYJMjhrav7LBlriBMHV8azIQ'
   #end
    client = Twitter::Client.new(
            :consumer_key => "u900Ra1m9Kjig06kdLJQ",
            :consumer_secret => "eNhEPwcAVOmInOUJ4lD4aCMexXQZfsXkw9ER8R74",
            :oauth_token => "1274091577-131OVrDGMHDX1xfZVt70orsZDM9hia0wKm8NiZe",
            :oauth_token_secret => "GkbGwz9rVvCMIXv5zXDfUdiBf3DLiuAx10hE5K2k"
    )

    th = nil
    get '/api/realtime', provides: 'text/event-stream' do
      th ||= Thread.new do
        puts "Realtime Start"

        out = ->(str) do
          settings.listeners.each do |o|
            o << str
          end
        end
        html = ->(str) do
          settings.html_listeners.each do |o|
            o << str
          end
        end
 

        last_playing = nil
        last_upcoming = nil
        last_history = nil
        r = Redis.new

        begin
          loop do
            if last_playing != (playing = Player.playing)
              out.call "event: playing\n"
              #cache = r.get('playing')
              puts "song changed omgggg!!!!11"
              r.hdel('votes:' + playing.id, 'count')
              r.srem('sorted',  playing.id)
              client.update(playing.name + " - " + playing.artist + " #jukebox #nowplaying")
              out.call "data: #{playing.to_hash.to_json}\n\n"
              html.call "event: playing\n"
              html.call "data: #{{html: haml(:song, layout: false, locals: {song: playing})}.to_json}\n\n"

              last_playing = playing
            end

            if last_upcoming != (upcoming = Queue.upcoming)
              out.call "event: upcoming\n"
              out.call "data: #{upcoming.map(&:to_hash).to_json}\n\n"
              html.call "event: upcoming\n"
              html.call "data: #{{html: haml(:songs, layout: false, locals: {songs: upcoming})}.to_json}\n\n"


              last_upcoming = upcoming
            end

            if last_history != (history = Queue.history)
              out.call "event: history\n"
              out.call "data: #{history.map(&:to_hash).to_json}\n\n"
              html.call "event: history\n"
              html.call "data: #{{html: haml(:songs, layout: false, locals: {songs: history})}.to_json}\n\n"


              last_history = history
            end

            out.call "event: ping\ndata: {\"type\": \"ping\"}\n\n"
            html.call "event: ping\ndata: {\"type\": \"ping\"}\n\n"

            sleep 1
          end
        rescue Exception => e
          p e
          p e.backtrace
          retry
        end
      end

      stream(:keep_open) do |out|
        out << "event: connected\ndata: {\"type\": \"hello\"}\n\n"

        to = params[:html] ? settings.html_listeners : settings.listeners
        to << out
        out.callback { puts "!!!"; to.delete(out) }
      end
    end
  end
end
