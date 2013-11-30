
require 'IFMapper/Map'

class FXMap; end

#
# Function used to unquote a string.  Formats such as TADS/Inform use special
# syntax rules in quotes.
#
module MapUnquote
  def unquote(x)
    return x
  end
end

#
# A generic abstract class for reading a map from some file format.
#
# Map readers are expected to parse their file formats and call:
#
# new_room
# new_door
# new_obj
#
# with @tag and @name defined.
#
# These functions create arrays of temporary Map* classes (like MapRoom)
# that represent the room and their connections.  
#
# Later on, the create() function is invoked to actually create those rooms
# as actual FXRooms and similar.  The reason this is done this way is because
# in order to position FXRooms around, we need to previously know the location
# of all rooms and their exits.
#
class MapReader

  class ParseError < StandardError; end
  class MapError < StandardError; end

  # Path separator in environment variables
  if RUBY_PLATFORM =~ /win/
    SEP = ';'
  else
    SEP = ':'
  end

  # Direction list in order of positioning preference.
  DIRLIST = [ 0, 4, 2, 6, 1, 3, 5, 7 ]

  include MapUnquote

  @@debug = nil
  def debug(*x)
    return unless @@debug
    $stdout.puts x
    $stdout.flush
  end

  # Temporary classes used to store inform room information
  class MapObject
    include MapUnquote

    attr_reader   :name, :connector
    attr_accessor :tag, :location, :enterable, :scenery

    def name=(x)
      @name = unquote(x)
    end

    def to_s
      "#@name tag:#@tag"
    end

#     def method_missing(*a)
#     end

    def initialize(location)
      if location
	@location = Array[*location]
      else
	@location = []
      end
      @enterable = []
    end
  end

  class MapDoor
    attr_accessor :name, :location, :locked, :connector, :tag
#     def method_missing(*x)
#     end
    def initialize
      @location = []
    end
    def to_s
      if locked
	door = '<|>'
      else
	door = '<->'
      end
      c = ''
      if connector
	c = ' (connector)'
      end
      "#{location[0]}#{door}#{location[1]}#{c}"
    end
  end

  class MapOneWay
    attr_reader :room
    def initialize(room)
      @room = room
    end
    def to_s
      "ONE WAY: #{room}"
    end
  end

  class MapSpecialExit
    attr_reader :go
    attr_reader :to
    def initialize(go, to)
      @go = go
      @to = to
    end
    def to_s
      "SPECIAL: #{go} #{to}"
    end
  end


  class MapRoom
    include MapUnquote

    attr_reader   :name
    attr_accessor :exits, :tag, :light, :desc
    attr_accessor :oneways
    def inspect
      r = "#{to_s}\n"
      @exits.each_with_index { |e, idx|
	next if not e
	if idx > 7
	  dir = Connection::EXIT_TEXT[idx-7]
	else
	  dir = Room::DIRECTIONS[idx]
	end
	r += "\t#{dir.upcase}: #{e}"
      }
      return r
    end
    def to_s
      "#@name tag:#@tag"
    end
    def num_exits
      return @exits.nitems + @oneways
    end
    def name=(x)
      @name = unquote(x)
    end

#     def method_missing(*x)
#     end
    def initialize
      @tag      = nil
      @desc     = ''
      @oneways  = 0
      @light    = true
      @exits    = Array.new(12, nil)
    end
  end



  def new_door(loc = nil)
    @obj = @tags[@tag] || MapDoor.new
    @obj.tag  = @tag
    @obj.name = @name || @tag
    @obj.location << loc if loc
    @tags[@tag] = @obj
    @doors << @obj
  end



  def new_room(klass = MapRoom)
    # We assume we are a room (albeit we could be an obj)
    @room = klass.new
    @room.tag   = @tag
    @room.name  = @name || @tag
    @room.desc  = ''
    @tags[@tag] = @room
    @rooms << @room
  end

  def make_room(to, x, y, dx = 1, dy = 0)
    if not @map.free?(x, y)
      @map.shift(x, y, dx, dy)
    end
    room = @map.new_room(x, y)
    room.name = to.name
    desc = to.desc.to_s
    desc.gsub!(/[\t\n]/, ' ')
    desc.squeeze!(' ')
    room.desc     = unquote(desc)
    room.darkness = !to.light
    @tags[to.tag] = room
    return room
  end


  def new_obj(loc = nil, klass = MapObject)
    debug "+++ OBJECT #@name"
    @obj = klass.new(loc)
    @obj.tag  = @tag
    @obj.name = @name # || @tag
    @tags[@tag] = @obj
    @objects << @obj
  end


  attr_reader :map, :doors, :rooms, :tags, :functions
  attr_reader :include_dirs

  #
  # Bring up the properties window, to allow user to change
  # settings
  #
  def properties
    decor = DECOR_TITLE|DECOR_BORDER

    dlg = FXDialogBox.new( @map.window.parent, "Include Settings", decor )
    mainFrame = FXVerticalFrame.new(dlg,
				    FRAME_SUNKEN|FRAME_THICK|
				    LAYOUT_FILL_X|LAYOUT_FILL_Y)

    frame = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

    FXLabel.new(frame, "Include Dirs: ", nil, 0, LAYOUT_FILL_X)
    inc = FXTextField.new(frame, 80, nil, 0, LAYOUT_FILL_ROW)
    inc.text = @include_dirs.join(SEP)

    buttons = FXHorizontalFrame.new(mainFrame, 
				    LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|
				    PACK_UNIFORM_WIDTH)
    # Accept
    FXButton.new(buttons, "&Accept", nil, dlg, FXDialogBox::ID_ACCEPT,
		 FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
    
    # Cancel
    FXButton.new(buttons, "&Cancel", nil, dlg, FXDialogBox::ID_CANCEL,
		 FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
    if dlg.execute != 0
      @include_dirs = inc.text.split(SEP)
      return true
    end
    return false
  end

  def set_include_dirs
  end

  def read_file(file)
    debug "Start parsing #{file}"
    File.open(file) { |f|
      parse(f)
    }
    debug "Done parsing #{file}"
  end

  def best_dir(r, dirA)
    start = (dirA + 4) % 8

    dirs = [
      start,
      (start - 1) % 8,
      (start + 1) % 8,
      (start - 2) % 8,
      (start + 2) % 8,
      (start - 3) % 8,
      (start + 3) % 8,
      dirA
    ]

    dirs.each { |d|
      return d if not r.exits[d]
    }

    return nil
  end

  def has_exit_to?(a, b)
    idx = a.exits.rindex(b)
    return idx if idx
    a.exits.each_with_index { |e, idx|
      next unless e
      if e.kind_of?(MapSpecialExit)
	e = e.to
      elsif e.kind_of?(MapObject)
	e.enterable.each { |x|
	  return idx if @tags[x] == b
	}
      end
      case e
      when MapDoor
	tag = e.location.find { |t| t != a.tag }
	e = @tags[tag]
	return idx if e == b
      when MapOneWay
	return idx if e.room == b
      else
	return idx if e == b
      end
    }
    return false
  end

  #
  # Look for one way exits and add them to the proper room exit on the
  # destination side.  This is needed so that we properly count room exits
  # and start mapping from rooms with more exits.
  #
  # Also, resolve up/down/in/out exits into one of the proper 8 directions.
  #
  def resolve_exits

    if @tags[nil]
      raise "error"
    end

    #
    # First, we resolve tags to the corresponding Map* class.
    # If we deal with a MapDoor that is really a connector, we simplify and
    # just attach the destination room directly.
    # If we deal with a MapDoor with no matching other room, we remove. This
    # can happen in TADS games or if user just read a portion of the full map.
    #
    @rooms.each { |r|
      r.exits.each_with_index { |tag, idx|
	next unless tag
	to = @tags[tag]

	if to.kind_of?(MapDoor)
	  if to.location.size == 1
	    to = nil
	  else
	    if to.connector
	      t = to.location.find { |t| t != r.tag }
	      to = @tags[t]
	    end
	  end
	end

	if idx > 7
	  # if Up/Down/In/Out exit and we have a similar exit
	  # going in one direction, remove this exit
	  if r.exits[0,8].index(to)
	    r.exits[idx] = nil
	    next
	  end
	end

	if not to
	  if not @functions.include?(tag)
	    $stderr.puts "Exit to #{tag} not found, ignored."
	  end
	end

	r.exits[idx] = to
      }
    }

    @rooms.each { |r|
      r.exits.each_with_index { |e, dirA|
	next if not e or e.kind_of?(MapOneWay)
	next if e == r

	##
	# Do we have a special exit?
	if dirA > 7
	  # First, get dirB and see if it is not a proper directional
	  # exit
	  dirB = nil
	  if e.kind_of?(MapRoom)
	    dirB = has_exit_to?(e, r)
	  elsif e.kind_of?(MapDoor)
	    t = e.location.find { |t| t != r.tag }
	    to = @tags[t]
	    if to
	      to.exits.each_with_index { |d, idx|
		if d == e or d == r
		  dirB = idx
		  break
		end
	      }
	    end
	  end

	  dirB = 4 if not dirB or dirB > 7

	  go = dirA - 7
	  r.exits[dirA] = nil
	  dirA = best_dir(r, dirB)
	  next if not dirA
	  r.exits[dirA] = MapSpecialExit.new(go, e)
	end


	###############

	# we have a room or door exit

	if e.kind_of?(MapRoom)
	  # check if destination room also has a connection towards us.
	  next if has_exit_to?(e, r)

	  dirB = best_dir(e, dirA)
	  next unless dirB

	  e.exits[dirB] = MapOneWay.new(r)

	elsif e.kind_of?(MapDoor)
	  t = e.location.find { |t| t != r.tag }
	  found = false
	  to = @tags[t]
	  if to
	    to.exits.each_with_index { |d, idx|
	      next if not d
	      if d == e or d == r
		found = true
		break
	      end
	    }
	  end

	  if to and not found
	    dirB = best_dir(to, dirA)
	    next unless dirB
	    to.exits[dirB] = MapOneWay.new(r)
	  end
	elsif e.kind_of?(MapObject)
	else
	  raise "Unknown exit type #{e.class}"
	end
      }
    }



  end

  def shift_link(room, dir)
    idx = dir + 1
    idx = 0 if idx > 7
    while idx != dir
      break if not room[idx]
      idx += 1
      idx = 0 if idx > 7
    end
    if idx != dir
      room[idx] = room[dir]
      room[dir] = nil
      # get position of other room
      ox, oy = Room::DIR_TO_VECTOR[dir]
      c = room[idx]
      if c.roomA == room
	b = c.roomB
      else
	b = c.roomA
      end
      x, y = [b.x, b.y]
      x -= ox
      y -= oy
      dx, dy = Room::DIR_TO_VECTOR[idx]
      @map.shift(x, y, -dx, -dy)
    else
      # raise "Warning.  Cannot shift connection for #{room}."
    end
  end


  def oneway_link?(a, b)
    # First, check if room already has exit moving towards other room
    a.exits.each_with_index { |e, idx|
      next if not e or e.dir != Connection::AtoB
      roomA = e.roomA
      roomB = e.roomB
      if roomA == a and roomB == b
	return e
      end
    }
    return nil
  end


  # Choose a direction to represent up/down/in/out.
  def choose_dir(a, b, go = nil, exitB = nil)
    if go
      rgo = go % 2 == 0? go - 1 : go + 1
      # First, check if room already has exit moving towards other room
      a.exits.each_with_index { |e, idx|
	next if not e
	roomA = e.roomA
	roomB = e.roomB
	if roomA == a and roomB == b
	  e.exitAtext = go
	  return idx
	elsif roomB == a and roomA == b
	  e.exitBtext = go
	  return idx
	end
      }
    end

    # We prefer directions that travel less... so we need to figure
    # out where we start from...
    if b
      x = b.x
      y = b.y
    else
      x = a.x
      y = a.y
    end
    if exitB
      dx, dy = Room::DIR_TO_VECTOR[exitB]
      x += dx
      y += dy
    end

    # No such luck... Pick a direction.
    best = nil
    bestscore = nil

    DIRLIST.each { |dir|
      # We prefer straight directions to diagonal ones
      inc   = dir % 2 == 1 ? 100 : 140
      score = 1000
      # We prefer directions where both that dir and the opposite side
      # are empty.
      if (not a[dir]) or a[dir].stub?
	score += inc
	score += 4 if a[dir] #attaching to stubs is better
      end
#       rdir  = (dir + 4) % 8
#       score += 1   unless a[rdir]

      # Measure distance for that exit, we prefer shorter
      # paths
      dx, dy = Room::DIR_TO_VECTOR[dir]
      dx = (a.x + dx) - x
      dy = (a.y + dy) - y
      d = dx * dx + dy * dy
      score -= d
      next if bestscore and score <= bestscore
      bestscore = score
      best = dir
    }

    if not bestscore
      raise "No free exit for choose_dir"
    end

    return best
  end


  def get_exit(r, from, to, x, y, dx = 1, dy = 0 )
    elem = @tags[to.tag]
    if elem.kind_of?(MapRoom)
      dirB = has_exit_to?(to, r)
      if dirB
	dbx, dby = Room::DIR_TO_VECTOR[dirB]
	if x + dbx != from.x or y + dby != from.y
	  x -= dbx
	  y -= dby
	end
      end

      room = create_room(to, x, y, dx, dy)
      return [room, Connection::FREE]
    elsif elem.kind_of?(MapDoor)
      if elem.connector
	type = Connection::FREE
      elsif elem.locked
	type = Connection::LOCKED_DOOR
      else
	type = Connection::CLOSED_DOOR
      end

      # Okay, connecting room is missing.  Check door's locations property
      elem.location.each { |tag|
	next if @tags[tag] == from
	@rooms.each { |o|
	  next if o.tag != tag
	  res = create_room( o, x, y, dx, dy )
	  return [ res, type ]
	}
      }
      
#       @rooms.each { |o|
# 	next if @tags[o.tag] == from
# 	o.exits.each { |e|
# 	  next unless e
# 	  if @tags[e] == elem
# 	    res = create_room( o, x, y, dx, dy )
# 	    return [ res, type ]
# 	  end
# 	}
#       }

      $stderr.puts "No room for door #{to.name}: #{to}"
      return [nil, nil]
    else
      return [elem, Connection::FREE]
    end
  end

  def create_room(r, x, y, dx = 2, dy = 0)
    return @tags[r.tag] if @tags[r.tag].kind_of?(Room)

    debug "+++ CREATE ROOM #{r.name} (#{x},#{y}) TAG:#{r.tag}"
    from, = make_room(r, x, y, dx, dy)

    r.exits[0,8].each_with_index { |to, exit|
      next unless to

      debug "#{r.name} EXIT:#{exit} points to #{to}"

      go = c = nil

      if to.kind_of?(MapOneWay)
	dx, dy = Room::DIR_TO_VECTOR[exit]
	x = from.x + dx
	y = from.y + dy
	@tabs += 1
	create_room(to.room, x, y, dx, dy)
	@tabs -= 1
	next
      elsif to.kind_of?(MapSpecialExit)
	go = to.go
	to = to.to
      end

      b = to


      dir  = exit
      type = 0

      # If exit leads to an enterable object, find out where does that
      # enterable object lead to.
      if to.kind_of?(MapObject)
	rooms = to.enterable
	rooms.each { |room|
	  next if room == r
	  to = b = @tags[room]
	  break
	}
	# Skip it if we are still an object.  This means we are just
	# a container, like the phone booth in the Fate game demo.
	next if to.kind_of?(MapObject)
      end

      odir = nil
      if b.kind_of?(MapRoom)
	odir = b.exits.rindex(r.tag)
	if not odir
	  b.exits[0,8].each_with_index { |e, idx|
	    next if not e
	    if (e.kind_of?(MapOneWay) and e.room == r) or
		(e.kind_of?(MapSpecialExit) and e.to == r)
	      odir = idx
	      break
	    end
	  }
	end
      elsif b.kind_of?(MapDoor)
	t = b.location.find { |t| t != r.tag }
	other = @rooms.find { |x| x.tag == t }
	# other = @tags[t]
	if other
	  other.exits.each_with_index { |d, idx|
	    next if not d
	    if d == b or d == r.tag or 
		(d.kind_of?(MapOneWay) and d.room == r) or
		(d.kind_of?(MapSpecialExit) and (d.to == b or d == r.tag))
	      odir = idx
	      break
	    end
	  }
	end
      end 
      odir = (dir + 4) % 8 if not odir

      if to.kind_of?(MapRoom) or to.kind_of?(MapDoor)
	dx, dy = Room::DIR_TO_VECTOR[dir]
	x = from.x + dx
	y = from.y + dy
	@tabs += 1
	to, type = get_exit(r, from, to, x, y, dx, dy)
	@tabs -= 1
	next if not to
      end


#       b = @rooms.find { |r2| r2.tag == tag }
#       odir = nil
#       odir = b.exits.rindex(r.tag) if b
#       odir = (dir + 4) % 8 if not odir

      if from[dir]
	c = from[dir]
	if to.exits.rindex(c) and c.roomB == from
	  debug "LINK TRAVELLED BOTH"
	  c.dir = Connection::BOTH
	  c.exitBtext = go if go
	  next
	else
	  debug "#{exit} FROM #{from}->#{to} BLOCKED DIR: #{dir}"
	  shift_link(from, dir)
	end
      end

      # Check we don't have a connection already
      if to[odir]
	c = to[odir]

	# We need to change odir to something else
	rgo = 0
	if go
	  rgo = go % 2 == 0? go - 1 : go + 1
	end

	# First, check if we have a dangling one-way link going to->from
	# If we do, we use it.
	c = oneway_link?(from, to)
	if not c
	  odir = choose_dir(to, from, rgo, dir)
	else
	  debug "FOUND LINK #{c} -- filling it."
	  idx = from.exits.index(c)
	  from[idx] = nil
	  from[dir] = c
	  c.dir = Connection::BOTH
	  c.exitBtext = go if go
	end
      else
	debug "to[odir] empty."
	# First, check if we have a dangling one-way link going to->from
	# If we do, we use it.
	c = oneway_link?(to, from)
	if c
	  debug "FOUND LINK #{c} -- filling it."
	  idx = from.exits.index(c)
	  from[idx] = nil
	  from[dir] = c
	  c.dir = Connection::BOTH
	  c.exitBtext = go if go
	end
      end

      if not c
	debug "NEW LINK #{from} #{dir} to #{to} #{odir}"
	begin
	  c     = @map.new_connection(from, dir, to, odir)
	  c.exitAtext = go if go
	  c.dir = Connection::AtoB
	  c.type = type
	rescue Section::ConnectionError
	end
      end
    }

    return from
  end

  #
  # Try to move rooms around to make map smaller.
  #
  def compact
    # First, verify all one-exit rooms lie next to its opposite room.
    sect  = @map.sections[@map.section]
    rooms = sect.rooms.find_all { |r| r.num_exits == 1 }

    rooms.each { |a|
      c = a.exits.find { |e| e != nil }
      b = c.opposite(a)

      dx = (a.x - b.x).abs
      dy = (a.y - b.y).abs
      next if dx <= 1 and dy <= 1

      x, y = [b.x, b.y]
      dirB = b.exits.index(c)

      dx, dy = Room::DIR_TO_VECTOR[dirB]
      x += dx
      y += dy

      dirA = a.exits.index(c)
      dx, dy = Room::DIR_TO_VECTOR[dirA]
      # Check if exits are complementary.  If not, we need to move room
      # again.
      if x + dx != b.x or y + dy != b.y
	x -= dx
	y -= dy
      end
      next if x == a.x and y == a.y

      # Place room here.  Check if filled.
      if sect.free?(x, y)
	a.x, a.y = x, y
      else
	if dx != 0
	  dy = 0
	end
	sect.shift(x, y, -dx, -dy)
	a.x, a.y = x, y
      end
    }
  end

  #
  # Create all the stuff we found
  #
  def create
    @rooms = @rooms.sort_by { |r| r.num_exits }
    @rooms.reverse!

    @rooms.each { |r| 
      @tabs = 0
      min, max = @map.sections[@map.section].min_max_rooms
      create_room(r, max[0] + 2, 0)
    }
    @rooms = []

    @objects.delete_if { |obj| obj.scenery }

    # Add objects to rooms
    @objects.each { |obj|
      obj.location.each { |loc|
	r = @tags[loc]
	while r and not r.kind_of?(Room)
	  r = @tags[ r.location[0] ]
	end
	next unless r
	r.objects << obj.name + "\n"
      }
    }
  end

  def create_map(file)
    read_file(file)

    puts "Rooms: #{@rooms.size}"
    puts "Doors: #{@doors.size}"
    puts "Objects: #{@objects.size}"

    begin
      resolve_exits
      create
      compact
    rescue => e
      puts e
      puts e.backtrace
      raise
    end
  end

  def initialize(file, map = Map.new('Read Map'))
    @map = map

    @doors   = []
    @functions = []
    @tags    = {}
    @rooms   = []
    @objects = []

    @include_dirs = [File.dirname(file)]
    set_include_dirs

    if @map.kind_of?(FXMap)
      return unless properties
    end

    create_map(file)

    debug "Done creating #{file}"
    
    @tags      = nil   # save some memory by clearing the tag list
    @objects   = nil
    @functions = nil
    @doors     = nil
    @rooms     = nil 

    if @map.kind_of?(FXMap)
      @map.filename   = file.sub(/\.t$/i, '.map')
      @map.options['Location Description'] = true
      @map.window.show
    end
  end
end
