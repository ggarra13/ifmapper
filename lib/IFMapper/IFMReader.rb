
require "IFMapper/Map"

class FXMap; end

#
# Class that allows importing an IFM map file.
#
class IFMReader

  class ParseError < StandardError; end
  class MapError < StandardError; end


  DIRECTIONS = { 
    'north' => 0,
    'n' => 0,
    'northeast' => 1,
    'ne' => 1,
    'east' => 2,
    'e' => 2,
    'southeast' => 3,
    'se' => 3,
    'south' => 4,
    's' => 4,
    'southwest' => 5,
    'sw' => 5,
    'west' => 6,
    'w' => 6,
    'northwest' => 7,
    'nw' => 7,
  }

  GO = {
    'd'    => 2,
    'down' => 2,
    'up'   => 1,
    'u'    => 1,
    'i'    => 3,
    'in'   => 3,
    'o'    => 4,
    'out'  => 4,
  }

  attr_reader :map

  #
  # Main parsing loop.  We basically parse the file twice to
  # solve dependencies.  Yes, this is inefficient, but the alternative
  # was to build a full parser that understands forward dependencies.
  #
  def parse(file)
    # We start map at 1, 1
    @x, @y = [0, 0]
    @room  = @item = @task  = nil

    if @map.kind_of?(FXMap)
      @map.options['Edit on Creation'] = false
      @map.window.hide
    end
    @map.section = 0

    @last_section = 0
    @ignore_first_section = true
    @room_idx = 0
    line_number = 0

    while not file.eof?
      @line = ''
      while not file.eof? and @line !~ /;\s*(#.*)?$/
	@line << file.readline()
	@line.sub!( /^\s*#.*/, '')
	line_number += 1
      end
      @line.sub!( /;\s*#.*$/, '')
      @line.sub!( /^\s+/, '' )
      @line.gsub!( /;\s*$/, '' )
      @line.gsub!( /\n/, ' ' )
      next if @line == ''
      full_line = @line.dup
      # puts "#{line_number}:'#{@line}'"
      begin
	parse_line
      rescue ParseError => e
	$stderr.puts
	$stderr.puts "#{e} for pass #{@resolve_tags}, at line #{line_number}:"
	$stderr.puts ">>>> #{full_line};"
	$stderr.puts
      rescue => e
	$stderr.puts
	$stderr.puts "#{e} for pass #{@resolve_tags}, at line #{line_number}:"
	$stderr.puts ">>>> #{full_line};"
	$stderr.puts e.backtrace if not e.kind_of?(MapError)
      end
    end
  end

  #
  # see if line is a variable line.  if so, return true
  #
  def parse_variable
    @line =~ /^\s*[\w\.]+\s*=.*$/
  end

  #
  # Get a quoted string from line
  #
  def get_string
    str = nil
    if @line =~ /^"(([^"\\]|\\")*)"/
      str = $1
      @line = @line[str.size+2..-1]
      # Change any quoted " to normal "
      str.gsub!( /\\"/, '"' )
    end
    return str
  end

  #
  # Get a new token from line
  #
  def get_token
    return nil if not @line
    token, @line = @line.split(' ', 2)
    return token
  end

  #
  # Look-ahead a token, without modifying line
  #
  def next_token
    return nil if not @line
    token,  = @line.split(' ', 2)
    return token
  end

  #
  # Return whether next token is a tag or a language keyword
  #
  def is_tag?
    token = next_token
    case token
    when nil, 
	'to', 'cmd', 'from', 'need', 'lose', 'lost', 'tag', 'all', 'except',
	'before', 'after', 'start', 'style', 'endstyle', 'follow', 'link', 
	'until', 'dir', 'get', 'drop', 'goto', 'give', 'given', 
	'exit', 'in', 'keep', 'any', 'safe', 'score', 'go', 
	'hidden', 'oneway', 'finish', 'length', 'nopath', 'note', 'leave', 
	'join', /^#/
      return false
    else
      return true
    end
  end

  #
  # Get a tag
  #
  def get_tag
    tag = get_token
    if tag == 'it'
      return [tag, (@item or @task or @room)]
    elsif tag == 'last' or tag == 'all' or tag == 'any'
      return [tag, nil]
    else
      if not @tags[tag]
	if @resolve_tags
	  raise ParseError, "Tag <#{tag}> not known"
	end
      end
      return [tag, @tags[tag]]
    end
  end

  #
  # Get a room
  #
  def get_room
    tag, room = get_tag
    return @room if tag == 'last'
    if room and not room.kind_of?(Room)
      raise ParseError, "Not a room tag <#{tag}:#{room}>" 
    end
    return room
  end

  #
  # Get an item
  #
  def get_item
    tag, item = get_tag
    return @item if tag == 'last'
    if item and item.kind_of?(Room)
      raise ParseError, "Not an item tag <#{tag}:#{item}>"
    end
    return item
  end

  #
  # Get a task
  #
  def get_task
    tag, task = get_tag
    return @task if tag == 'last'
    if task and task.kind_of?(Room)
      raise ParseError, "Not a task tag <#{tag}:#{item}>"
    end
    return task
  end

  #
  # Parse a line of file
  #
  def parse_line
    return if parse_variable

    roomname = tagname = nil
    @task = @item = roomA = roomB =  
      from = one_way = nolink = go = nil
    styles = []
    links = []
    dir = []


    roomA = @room  # add item to this room

    while @line and token = get_token
      case token
      when 'map'
	section = get_string
	# Once we start a new section, we rest room and
	# current position.
	@room = nil
	@x = @y = 1
	# dont' add a section for first 'map' keyword
	if @ignore_first_section
	  @ignore_first_section = false
	  @map.sections[0].name = section
	  next
	end
	if @resolve_tags
	  @map.section  = @last_section + 1
	  @last_section = @map.section
	else
	  @map.new_section
	  @map.sections[-1].name = section
	end
      when 'title'
	@map.name = get_string
      when 'room'
	roomname = get_string
	@ignore_first_section = false
      when 'tag'
	tagname = get_token
      when 'dir'
	# if not roomname
	#  raise ParseError, 'dir directive found but not for a room'
	# end
	token = next_token
	while DIRECTIONS[token]
	  get_token
	  dir.push(DIRECTIONS[token])
	  token = next_token

	  if token =~ /^\d+$/
	    get_token
	    (token.to_i - 1).times { dir.push(dir[-1]) }
	    token = next_token
	  end
	end
      when 'nolink'
	if dir.empty?
	  raise ParseError, 'nolink directive, but no dir directive before.'
	end
	nolink  = true
      when 'oneway'
	one_way = true
      when 'nopath'
      when 'safe'
      when 'exit'
	if not roomname
	  raise ParseError, 'exit directive found but not for a room'
	end
	token = next_token
	while DIRECTIONS[token]
	  get_token
	  token = next_token
	end
      when 'from'
	if dir.empty?
	  raise ParseError, "'from' token found but no dir specified before"
	end
	from = get_room
      when 'join'
	# Joins are links that are not drawn.  
	# Mainly to give the engine knowledge that two locations 
	# are interconnected
	get_room while is_tag?
	to = next_token
	if to == 'to'
	  get_token
	  get_room
	end
      when 'all'
      when 'lost'
      when 'except'
	get_item while is_tag?
      when 'until'
	get_task while is_tag?
      when 'link'
	if roomname
	  while is_tag?
	    links.push( get_room )
	  end
	else
	  roomA = get_room
	  to = next_token
	  if to == 'to'
	    get_token
	    roomB = get_room
	  end
	end
      when 'goto'
	get_room
      when 'go'
	token = get_token
	go = GO[token]
	if not token
	  raise ParseError, "Token <#{token}> is an unknown go direction."
	end
      when 'item'
	@item = get_string
	item_tag = get_token if not @item
      when 'in'
	roomA = get_room  # oh, well... this room
      when 'note'
	note = get_string
      when 'keep'
	token = next_token
	if token == 'with'
	  get_token
	  item_keep = get_item
	end
      when 'given'
      when 'give'
	give_items = [ get_item ]
	give_items.push(get_item) while is_tag?
      when 'start'
      when 'finish'
      when 'follow'
	task = get_task
      when 'need'
	need_items = [ get_item ]
	need_items.push(get_item) while is_tag?
      when 'after'
	after_tasks = [ get_item ]
	after_tasks.push(get_item) while is_tag?
      when 'lose'
	loose_items = [ get_item ]
	loose_items.push(get_item) while is_tag?
      when 'get'
	get_items = [ get_item ]
	get_items.push(get_item) while is_tag?
      when 'drop'
	drop_items = [ get_item ]
	drop_items.push(get_item) while is_tag?
      when 'hidden'
      when 'leave'
	leave_items = [ get_item ]
	leave_items.push(get_item) while is_tag?
      when 'before'
	task = get_task
      when 'cmd'
	token = next_token
	if token == 'to'
	  get_token
	  cmd = get_string
	elsif token == 'from'
	  get_token
	  cmd = get_string
	elsif token == 'none'
	  get_token
	else
	  cmd = get_string
	  num = next_token
	  get_token if num =~ /\d+/
	end
      when 'score'
	score = get_token.to_i
      when 'length'
	length = get_token.to_i
      when 'task'
	@task = get_string
	task_tag = get_token if not @task
      when 'style'
	styles.push(get_token) while is_tag?
      when 'endstyle'
	get_token while is_tag?
      when '', /^#/
	get_token while @line
      else
	raise ParseError, "Token <#{token.inspect}> not understood"
      end
    end

    # If a direction, move that way.
    if dir.size > 0
      # If from keyword present, move from that room on.
      if from
	roomA = from
	# 'from' can also connect stuff not in current section... 
	# so we check we are in the right section.
	@map.sections.each_with_index { |p, idx|
	  if p.rooms.include?(roomA)
	    @map.fit
	    @map.section = idx
	    break
	  end
	}
      end
      # Okay, we start from roomA... and follow each dir
      if roomA
	@x = roomA.x
	@y = roomA.y
      end
      dir.each { |d|
	x, y = Room::DIR_TO_VECTOR[d]
	@x += x
	@y += y
      }
    end

    # Create new room
    if roomname
      if @resolve_tags
	# Room is already created.  Find it.
	roomB = @rooms[@room_idx]
	@room_idx += 1
      else
	# Verify there's no room in that location yet
	section = @map.sections[@map.section]
	section.rooms.each { |r|
	  if r.x == @x and r.y == @y
	    err  = "Section #{@map.section+1} already has location #{r} at #{@x}, #{@y}.\n"
	    err << "Cannot create '#{roomname}'"
	    raise MapError, err
	  end
	}

	# Remember original room for connection
	roomB          = @map.new_room( @x, @y )
	roomB.selected = false
	roomB.name     = roomname
	@rooms.push( roomB )
      end

      # Make roomB the current room
      @room = roomB
    end

    if @item and roomA and @resolve_tags
      roomA.objects << @item + "\n"
    end

    if @task and @room and @resolve_tags
      @room.tasks << @task + "\n"
    end

    # Add a link between rooms
    if roomA and roomB and not nolink and @resolve_tags
      # Establish new simple connection
      dirB = (dir[-1] + 4) % 8 if dir.size > 1

      if dir.size > 1
	dirB = [ @x - roomB.x, @y - roomB.y ]
	if dirB[0] == 0 and dirB[1] == 0
	  dirB = (dir[-1] + 4) % 8
	else
	  dirB = roomB.vector_to_dir( dirB[0], dirB[1] )
	end
      end

      # 'from' and 'link' keywords can also connect stuff not in
      # current section... so we check for that here
      @map.sections.each_with_index { |p, idx|
	if p.rooms.include?(roomA)
	  @map.fit
	  @map.section = idx
	  break
	end
      }
      if not @map.sections[@map.section].rooms.include?(roomB)
	raise MapError, "Linking #{roomA} and #{roomB} which are in different sections"
      end

      begin
	c = map.new_connection( roomA, dir[0], roomB, dirB )
	c.dir = Connection::AtoB if one_way
	c.type = Connection::SPECIAL if styles.include?('special')
      
	if go
	  c.exitAtext = go
	  if go % 2 == 0
	    c.exitBtext = go - 1
	  else
	    c.exitBtext = go + 1
	  end
	end
      rescue => e
	puts e
      end
    end

    if links.size > 0 and @resolve_tags
      # Additional diagonal connection for room
      links.each { |x| 
	next if not x
	begin
	  c = map.new_connection( @room, nil, x, nil )
	rescue => e
	  puts e
	end
      }
    end

    if tagname # and not @resolve_tags
      if roomname
	@tags[tagname] = @room
      elsif @item
	@tags[tagname] = @item
      elsif @task
	@tags[tagname] = @task
      else
	# join/link tag
	@tags[tagname] = ''
      end
    end
  end

  #
  # Okay, check all min/max locations in all sections
  # and then do the following:
  #   a) Adjust map's width/height
  #   b) Shift all rooms so that no rooms are in negative locations
  #
  def initialize(file, map = Map.new('IFM Imported Map'))
    @tags   = {}
    @map    = map
    @rooms  = []
    @resolve_tags = false

    # --------------- first pass
    File.open(file) { |f| 
      parse(f)
    }

    # --------------- second pass
    @map.fit
    @resolve_tags = true
    File.open(file) { |f|
      parse(f)
    }

    @map.section = 0
    if @map.kind_of?(FXMap)
      @map.filename   = file.sub(/\.ifm$/i, '.map')
      @map.navigation = true
      @map.window.show
    end
    @tags = {}   # save some memory by clearing the tag list
    @rooms = nil # and room list
  end
end


if $0 == __FILE__
  p "Opening file '#{ARGV[0]}'"
  $LOAD_PATH << '..'
  require "IFMapper/Map"
  
  IFMReader.new(ARGV[0])
end
