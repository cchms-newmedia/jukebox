require 'appscript'
require 'rubygems'
require 'redis'
require_relative './player'
require 'json'
require_relative './song'

module Jockey
  class Queue
    PLAYLIST = 'iTunes DJ'
    class << self 
      def playlist
        Player.playlist(PLAYLIST)
      end

      def lock
        @lock = Mutex.new
      end

      def offset
        if Player.playing? && Jockey::Player.app.current_playlist.name.get == PLAYLIST
          @offset = Player.app.current_track.index.get
        elsif !@offset
          p @offset
          Player.play(playlist)
          @offset = Player.app.current_track.index.get
        end

        @offset
      end

      # "enque", it's named enque but it doesn't add to the last!
      def enque(*songs)
        r = Redis.new
        # do like this: http://hints.macworld.com/article.php?story=20040830035448525
        # enque(d):
        #
        # 1. [a, b, c]
        # 2. [a, b, c, d]
        # 3. [a, b, c, d, a*, b*, c*]
        # 4. [d, a*, b*, c*]
        songs.flatten!
        #songs.map!(&:record)
        #puts YAML::dump(songs)
        lock.synchronize do # because it's not simple steps
          app = Appscript.app('iTunes')

          size = playlist.tracks.get.size
          exists = playlist.tracks[Appscript.its.index.gt(offset).and(Appscript.its.index.le(size))]
          #puts YAML::dump(exists)
          songlist = Hash.new
          songs.each do |song|
            if r.sismember('sorted', song.id)
              puts "yoloswag"
              votes = Integer(r.hmget('votes:' + song.id , 'count')[0])
              puts YAML::dump(votes)
              votes = votes + 1
              puts "votes: " + votes.to_s
              #count = votes[song.id]
              #count += 1
              #votes[song.id] = count
              r.hmset('votes:' + song.id, 'count', votes)
              puts "song plus plus"
            else
              r.sadd('sorted', song.id)
              r.hmset('votes:' + song.id, 'count', 1)
              puts "new song"
            end
           #songlist[song.id] = song
           puts "Queued: " + song.id	
           
           #puts YAML::dump(song)
           #song.record.duplicate to: playlist
          end
          #r.set('votes', votes.to_json)
          #votes.sort_by {|k,v| v}.reverse
          votes = r.sort('sorted', {:by => 'votes:*->count', :order => 'DESC'})
          votes.each do |songid|
             puts "song id: " + songid
             vote = Song.find(songid)
             puts "song name: " + vote.name            
             puts "vote count: " + r.hmget('votes:' + songid , 'count').first 
             vote.record.duplicate to: playlist
          end
         #exists.duplicate to: playlist
        
          playlist.delete exists
          #votes.each do |songid|
          #  song = Song.find(songid)
          #  playlist.delete playlist.tracks[Appscript.its.persistent_ID.eq(song.record.persistent_ID.get).and(Appscript.its.index.gt(offset+songs.size))]
          #end
        end
      end

      def history
        playlist.tracks[Appscript.its.index.lt(offset)].get.map{|x| Song.find(x) }.reverse
      end

      def upcoming
        playlist.tracks[Appscript.its.index.gt(offset)].get.map{|x| Song.find(x) }
      end

      def current
        Song.find playlist.tracks[offset].get
      end
    end
  end
end
