
require "IFMapper/Map"

class FXMap; end

#
# Class that allows importing a GUE map file.
#
class GUEReader

  class ParseError < StandardError; end
  class MapError < StandardError; end

  # This is the GUEmap magic number/ID at the beginning of the file.
  GUE_MAGIC = "\307U\305m\341p"

  DIRS = { 
    0 => 0, # n
    1 => 4, # s
    2 => 2, # e
    3 => 6, # w
    4 => 1, # ne
    5 => 7, # nw
    6 => 3, # se
    7 => 5, # sw

    # GUE Map also supports connections to the sides of centers
    #
    #  -*--*-
    #  |    |
    #  -*--*-
    #
    # We translate these as corner connections.
    #
    8  => [0, 1], #   ----*-
    9  => [0, 7],
    10 => [4, 3], #   ----*-
    11 => [4, 5],

    # DOT directions
    # 12 => 4,
  }


  class Complex
    attr_accessor :roomA, :dirA, :roomB, :dirB
  end


  attr_reader :map

  @@debug = nil

  def debug(x)
    if @@debug.to_i > 0
      $stderr.puts x
    end
  end

  #
  # Read GUEMap header from file stream
  #
  def header
    magic = @f.read(6)
    if magic != GUE_MAGIC
      raise ParseError, "Not a GUEMap"
    end
    @f.read(4)
    version = @f.read(2).unpack('s')[0]
    debug "VERSION: #{version}"
    case version
    when 4
      crap = @f.read(2)
      crap = @f.read(1)[0]
      if crap == 32
	len = @f.read(1)[0]
	@map.name = @f.read(len)
	crap = @f.read(1)[0]
      end
      if crap == 40
	len = @f.read(1)[0]
	if len == 255
	  len = @f.read(2).unpack('s')[0]
	end
	@f.read(len)
	crap = @f.read(1)[0]
      end
      hdr = @f.read(15)
    when 3,2
      crap = @f.read(2)
      crap = @f.read(1)[0]
      if crap == 32
	len = @f.read(1)[0]
	@map.name = @f.read(len)
	crap = @f.read(1)[0]
      end
      if crap == 40
	len = @f.read(1)[0]
	if len == 255
	  len = @f.read(2).unpack('s')[0]
	end
	@f.read(len)
	crap = @f.read(1)[0]
      end
      hdr = @f.read(8)
    else
      raise ParseError, "Unknown GUEMap version #{version}"
    end
  end

  #
  # Read a connection from file stream
  #
  def read_connection
    type = Connection::FREE
    dir  = Connection::BOTH
    dA   = @f.read(1)[0]
    a    = @f.read(1)[0]
    stub = false

    opt = @f.read(1)[0]
    exitAtext = exitBtext = 0

    case opt
    when 26
      #normal connection
    when 34
      # up/down/in/out connection
      exitAtext = @f.read(1)[0]
      if exitAtext & 8 != 0
	exitAtext -= 8
	type = Connection::SPECIAL
      end
      if exitAtext & 16 != 0
	# no exit connection
	stub = true
	exitAtext -= 16
	b  = a
	dB = dA
      end
      if exitAtext & 32 != 0
	# stub connection
	stub = true
	exitAtext -= 32
      end
      if exitAtext & 64 != 0
	exitAtext -= 64
	dir = Connection::AtoB
      end
      exitBtext = @f.read(1)[0]
      data      = @f.read(1)[0]
    else
      raise ParseError, "option: #{opt} unknown"
    end

    unless stub
      dB    = @f.read(1)[0]
      b     = @f.read(1)[0]
      opt   = @f.read(1)[0]
    end

    data    = @f.read(1)[0]
    data    = @f.read(1)[0] unless @f.eof?

    section = @map.sections[@map.section]
    roomA = section.rooms[a]
    roomB = section.rooms[b] if b


    debug "Index  : #{a}->#{b}"
    debug "dA:   #{dA}   dB: #{dB}"
    if roomA.name == '*'
      if roomB.x != roomA.x or roomB.y != roomA.y
	dirA = roomA.exit_to(roomB)
      else
	dirA = 0
      end
    else
      dirA = DIRS[dA]
      if dirA.kind_of?(Array)
	dirA.each { |d|
	  next if roomA[d]
	  dirA = d
	  break
	}
	if dirA.kind_of?(Array)
	  dirA = dirA[0]
	end
      end
      raise "Unknown direction #{dA}" unless dirA
    end

    if b
      if roomB.name == '*'
	dirB = (dirA + 4) % 8
      else
	dirB = DIRS[dB]
	if dirB.kind_of?(Array)
	  dirB.each { |d|
	    next if roomB[d]
	    dirB = d
	    break
	  }
	  if dirB.kind_of?(Array)
	    dirB = dirB[0]
	  end
	end
	raise "Unknown direction #{dB}" unless dirB
      end
    end


    if roomA[dirA]
      dirA = roomA.exits.index(nil)
    end

    if roomB
      if roomB[dirB]
	dirB = roomB.exits.rindex(nil)
      end
    end


    debug "Connect: #{roomA} ->#{roomB} "
    debug "dirA: #{dirA} dirB: #{dirB}"
    debug "exitA: #{exitAtext} exitB: #{exitBtext}"

    begin
      c = map.new_connection( roomA, dirA, roomB, dirB )

      c.exitAtext = exitAtext
      c.exitBtext = exitBtext
      c.dir       = dir
      c.type      = type
      
      debug c
    rescue Section::ConnectionError
    end

  end


  #
  # Read a room from file stream
  #
  def read_room
    x       = @f.read(1)[0]
    data    = @f.read(1)
    y       = @f.read(1)[0]
    data    = @f.read(1)[0]

    type    = @f.read(1)[0]

    case type
    when 41
      r = @map.new_room(x, y)
      r.name = "*"
      data  = @f.read(4)
      if data[0] == 0
	r.name = ''
      end
      return
    when 0
      r = @map.new_room(x, y)
      r.name = ''
      @f.read(2)
      return
    end

    len  = @f.read(1)[0]
    name = ''
    comment = ''

    name = @f.read(len)
    test = @f.read(1)[0]

    case test
    when 41
      @f.read(4)
    when 0
      data = @f.read(2)
    else
      len     = @f.read(1)[0]
      if len == 255
	len = @f.read(2).unpack('s')[0]
      end
      comment = @f.read(len)
      data    = @f.read(3)
    end
    debug "Room:    #{name.inspect}  pos: #{x}, #{y}"
    debug "Comment: #{comment.inspect}"

    # r = @map.new_room(x, y)
    r = @map.new_room(x, y)
    name.gsub!(/[\r\n]+/, ' ')
    comment.gsub!(/\r/, '')

    r.name  = name
    r.tasks = comment
  end

  #
  # Main parsing loop. 
  #
  def parse
    header
    while not @f.eof?
      type = @f.read(1)[0]
      data = @f.read(1)[0]

      debug "type: #{type}"
      debug "data: #{data}"

      case type
      when 2
	read_room
      when 3
	read_connection
      when 4
	break
      else
	raise "Unknown type: #{type}"
      end
    end
  end

  def remove_dots
    @map.sections.each do |sect|
      sect.connections.each do |c|
	a, b = c.room
	next unless b
	next if a.name == '*' or b.name != '*'
	# OK.  We have a ROOM->* connection.  Follow it to find other room.
	# And turn it into a complex connection.
	dirA = a.exits.index(c)
	dirB = b.exits.rindex(c)
	origB   = dirB
	dir     = Connection::BOTH
	dirB    = nil
	cc      = c
	while b.name == '*'
	  found = false
	  b.exits.each { |e|
	    next if not e or e == cc
	    found = true
	    idx  = e.index(b) ^ 1
	    b    = e.room[idx]
	    dirB = b.exits.index(e)
	    dir  = e.dir
	    cc   = e
	    break
	  }
	  if not found
	    debug "not found complement for #{cc}"
	    break
	  end
	end

	next if b.name == '*'

	# remove the other connection
	sect.delete_connection(cc)

	c.roomB[origB] = nil

	# Make connection a complex connection and remove old
	# connection in b room
	c.roomB = b
	c.dir   = dir
	b[dirB] = c
      end
    end


    # Now, remove all DOT rooms and their connections
    @map.sections.each { |sect|
      del = sect.rooms.find_all { |r| r.name == '*' }
      del.each { |r|
	sect.delete_room(r)
      }
    } 
  end

  def reposition
    @map.sections.each do |sect|
      minXY, = sect.min_max_rooms
      sect.rooms.each do |r|
	r.x -= minXY[0]
	r.y -= minXY[1]
	r.x /= 4.0
	r.y /= 4.0
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


  def initialize(file, map = Map.new('GUE Imported Map'))
    @map     = map
    @complex = []

    @f = File.open(file, 'rb')
    parse
    
    reposition
    remove_dots

    @map.fit
    @map.section = 0
    if @map.kind_of?(FXMap)
      @map.filename   = file.sub(/\.gmp$/i, '.map')
      @map.navigation = true
      @map.window.show
    end
  end
end


if $0 == __FILE__
  puts "Opening file '#{ARGV[0]}'"
  require "IFMapper/Map"
  
  GUEReader.new(ARGV[0])
end
