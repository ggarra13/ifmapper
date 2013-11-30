#
# Trizbort map reader
#

class FXMap; end

require 'rexml/document'
require 'IFMapper/FXConnection'

#
# Class that allows importing a Trizbort map file.
#
class TrizbortReader

  class ParseError < StandardError; end
  class MapError < StandardError; end
  
  W = 128
  H = 64


  DIRS = { 
    'n' => 0, # n
    's' => 4, # s
    'e' => 2, # e
    'w' => 6, # w
    'ne' => 1, # ne
    'nw' => 7, # nw
    'se' => 3, # se
    'sw' => 5, # sw

    # Trizbort also support connections to the sides of centers
    #
    #  --*--*--
    #  *      *
    #  *      *
    #  --*--*--
    #
    # We translate these as corner connections.
    #
    'ene' => [2, 1], #   ----*-
    'ese' => [2, 3], #   ----*-
    'nne' => [0, 1],
    'wnw' => [6, 7],
    'wsw' => [6, 5],
    'nnw' => [0, 7],
    'ssw' => [4, 5],
  }
  

  attr :doc

  @@debug = nil

  def debug(x)
    if @@debug.to_i > 0
      $stderr.puts x
    end
  end

  #
  # Read Trimap rexml from file stream
  #
  def parse
    
    rooms = {}


    @doc.elements.each('trizbort/info/title') { |e|
      @map.name = e.text
    }

    @doc.elements.each('trizbort/info/author') { |e|
      @map.creator = e.text
    }

    @doc.elements.each('trizbort/map/room') { |e|
      id = e.attributes['id'].to_i
      name = e.attributes['name'].to_s
      x = e.attributes['x'].to_i
      y = e.attributes['y'].to_i
      w = e.attributes['w'].to_i
      h = e.attributes['h'].to_i
      r = @map.new_room(x, y)
      r.name = name
      darkness = e.attributes['isDark']
      if darkness == 'yes'
        r.darkness = true
      end
      desc = e.attributes['description']
      r.desc = desc.to_s
      r.desc.gsub!("\r\n", "\n")
      rooms[id] = r
      e.elements.each('objects') { |o|
        r.objects = o.text.to_s.gsub('|',"\n")
      }
    }

    @doc.elements.each('trizbort/map/line') { |e|
      style = e.attributes['style'].to_s

      if style == 'dashed'
        style = Connection::SPECIAL
      else
        style = Connection::FREE
      end

      id = e.attributes['id'].to_i
      flow = e.attributes['flow']

      if flow == 'oneWay'
        flow = Connection::AtoB
      else
        flow = Connection::BOTH
      end

      startText = e.attributes['startText'].to_s
      endText = e.attributes['endText'].to_s

      line = {}

      e.elements.each { |x|
        name = x.local_name
        if name == 'dock'
          port = x.attributes['port']
          room = x.attributes['id'].to_i
          index = x.attributes['index'].to_i
          line[index] = [port, rooms[room]]
        elsif name == 'point'
          index = x.attributes['index'].to_i
          line[index] = [nil, nil]
        end
      }

      if line.size > 0
        roomA = line[0][1]
        dirA  = DIRS[line[0][0]]

        if dirA.kind_of?(Array)
          dirA.each { |d|
            next if roomA[d]
            dirA = d
            break
          }
          if dirA.kind_of? Array
            dirA = dirA[0]
          end
        end

        if line.size > 1
          roomB = line[1][1]
          dirB  = DIRS[line[1][0]]

          if dirB.kind_of? Array
            dirB.each { |d|
              next if roomB[d]
              dirB = d
              break
            }
            if dirB.kind_of?(Array)
              dirB = dirB[0]
            end
          end
        end

        debug "Connect: #{roomA} ->#{roomB} "
        debug "dirA: #{dirA} dirB: #{dirB}"

        if startText =~ /^up?/i
          startText = 1
        elsif startText =~ /^d(?:own)?/i
          startText = 2
        elsif startText =~ /^in?/i
          startText = 3
        elsif startText =~ /^o(?:ut)?/i
          startText = 4
        else
          startText = 0
        end

        if endText =~ /^up?/i
          endText = 1
        elsif endText =~ /^d(?:own)?/i
          endText = 2
        elsif endText =~ /^in?/i
          endText = 3
        elsif endText =~ /^o(?:ut)?/i
          endText = 4
        else
          endText = 0
        end

        debug "exitA: #{startText} exitB: #{endText}"

        begin
          c = @map.new_connection( roomA, dirA, roomB, dirB )
          c.exitAtext = startText
          if roomB
            c.exitBtext = endText
          end
          c.type = style
          c.dir = flow
          debug c
        rescue Section::ConnectionError
        end
      end
      
    }

  end



  def reposition
    @map.sections.each do |sect|
      minXY, = sect.min_max_rooms
      sect.rooms.each do |r|
        r.x -= minXY[0]
	r.y -= minXY[1]
	r.x /= (W+32)
	r.y /= (H+32)
      end
    end

    @map.sections.each do |sect|
      sect.rooms.each_with_index do |r, idx|
        x = r.x
        y = r.y
        xf = x.floor
        yf = y.floor
        if x != xf or y != yf
          sect.rooms.each do |r2|
            next if r == r2
            if xf == r2.x.floor and yf == r2.y.floor
              dx = (x - xf).ceil
              dy = (y - yf).ceil
              sect.shift(x, y, dx, dy)
              break
            end
          end
        end
        r.x = r.x.floor.to_i
        r.y = r.y.floor.to_i
      end
    end
  end

  def initialize(file, map = Map.new('Trizbort Imported Map'))
    @map = map
    
    f = File.open( file )
    @doc = REXML::Document.new f

    parse

    reposition

    @map.fit
    @map.section = 0

    if @map.kind_of?(FXMap)
      @map.filename   = file.sub(/\.trizbort$/i, '.map')
      @map.navigation = false
      @map.window.show
    end
  end

end
