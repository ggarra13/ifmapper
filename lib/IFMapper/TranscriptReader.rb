

#
# Class used to parse an Infocom-style transcript and automatically
# generate a map.  This can be used to automatically map a game as 
# you play it.
#
# This code is based on Perl code by Dave Chapeskie, used in IFM,
# albeit it has been enhanced to handle multi-line commands, room stub
# exits and oneway exits, objects parsing and the ability to parse 
# transcripts as they are being spit out.
#
class TranscriptReader

  TRANSCRIPT = /^(?:Start of a transcript of|Here begins a transcript of interaction with (.*)|Here begins a transcript of interaction with)/

  #  PROMPT   = /^>\s*/
  LOOK     = /^l(ook)?/i
  UNDO     = /^undo$/i
  RESTART  = /^restart$/i
  RESTORE  = /^restore$/i
  IGNORE   = /transcript/i
  OTHERS   = /^(read|inventory$|i$)/i
  UNSCRIPT = /^unscript$/i
  BLANK    = /^\s*$/
  TAKE     = /^(take|get)\s+(a\s+|the\s+)?(.*)/i
  DROP     = /^(drop|leave)\s+()/i
  STARTUP  = /(^[A-Z]+$|Copyright|\([cC]\)\s*\d|Trademark|Release|Version|[Ss]erial [Nn]umber|Written by)/
  DARKNESS = /^dark(ness)?$|^in the dark$|^a dark place$|^It is pitch black|^It is too dark to see anything|^You stumble around in the dark/i
  DEAD     = /(You die|You have died|You are dead)/i
  YES      = /^y(es)/i

  THEN     = /\bthen\b/i

  # Compass direction command -> direction mapping.
  DIRMAP = {
    "n" => 0, "north" => 0, "ne" => 1, "northeast" => 1,
    "e" => 2, "east" => 2, "southeast" => 3, "se" => 3,
    "south" => 4, "s" => 4, "southwest" => 5, "sw" => 5,
    "west" => 6, "w" => 6, "northwest" => 7, "nw" => 7
  }

  ODIRMAP = {"up" => 1, "u" => 1, "down" => 2, "d" => 2,
    "in" => 3, "out" => 4, 'enter' => 3, 'exit' => 4 }

  DIR_REX = '(' + DIRMAP.keys.join('|') + '|' + ODIRMAP.keys.join('|') + ')'
  GO      = /^((walk|run|go|drive|jump)\s+)?#{DIR_REX}[.,\s]*\b/i

  # Direction list in order of positioning preference.
  DIRLIST = [ 0, 4, 2, 6, 1, 3, 5, 7 ]

  # No exit replies
  NO_EXIT = [
             /\byou\scan't\sgo\sthat\sway\b/i,
             /\byou\scan't\sgo\sin\sthat\sdirection\b/i,
             /\bdoorways\slead\s/i,
             /\bthat's\sa\swall\b/i,
             /\bno\sexit\b/i,
             /\bthere's\s+nowhere\s+to\s+go\s+in\sthat\s+direction\b/i,
             /\bthere's\s+nothing\s+in\s+that\s+direction\b/i,
             /\bblocks?\sthe\sway/i,
             /\byou\scan\sonly\sgo\s/i,
             /\byou\scan\sgo\sonly\s/i,
             /\bimpenetrable\b/i,
             /\bbars\syour\sway/i,
             /\bthere's\s.*in\s(?:your|the)\sway/i
            ]
  
  # Closed exit replies
  CLOSED_EXIT = [
    /door\s+is\s+closed/i,
  ]

  # remove things like (on the bed) from short room name
  PREPOSITION   = "(?:in|on|under|behind|inside|along|\w+ing)"
  NAME_REMOVE   = /(\s+\(#{PREPOSITION}\s+.+\)|,\s+#{PREPOSITION}\s+[^\,\.]+)/

  # not a room name if it has any of this.
  NAME_INVALID  = /--|[:;\*\[\]\|\+\=!\.\?\000<>]/

  # Salutations and other words with periods that can appear as name of room
  SALUT         = '(Mr|Mr?s|Miss|Jr|Sr|St|Dr|Ave|Inc)'
  SALUTATIONS   = /\b#{SALUT}\./

  # Maximum length of room name.  Otherwise, a sentence we ignore.
  NAME_MAXWORDS = 20

  # word list that may be uncapitalized in room name
  NAME_UNCAP = /^(?:of|on|to|with|by|a|in|the|at|under|through|near)$/i

  # Default room description recognition parameters.
  DESC_MINWORDS = 20

  # Ignore these words when matching words in description
  # To avoid cases, like:  An open gate  vs.  A closed gate
  DESC_IGNORE   = /(?:an|a|open(ed)?|closed?)/i


  RESTORE_OK  = /\b(Okay|Ok|completed?|Restored)\b/

  ## 
  THE = '(?:the|an|a|your|some of the|some)\s+'

  ## Regex to eliminate articles from get/take replies.
  ARTICLE = /^#{THE}/i

  ## Possible nessages indicating get/take succeeded
  TAKE_OBJ = '([\w\'\s]+)'
  TAKE_FROM = '(\s+(?:up|from|out)\s+.*)$'
  TAKE_ALIAS = '(?:grab|pick\s+up|pick|pilfer|take(?:\s+up)?)'
  TAKE_OK = [ 
    /\btaken\b/i,
    /you\s+have\s+now\s+(?:got\s+)?(?:#{THE})?#{TAKE_OBJ}#{TAKE_FROM}/i,
    /you\s+have\s+now\s+(?:got\s+)?(?:#{THE})?#{TAKE_OBJ}/i,
    /you\s+#{TAKE_ALIAS}\s+(?:#{THE})?#{TAKE_OBJ}#{TAKE_FROM}/i,
    /you\s+#{TAKE_ALIAS}\s+(?:#{THE})?#{TAKE_OBJ}/i,
    /you\s+now\s+have\s+(?:got\s+)?(?:#{THE})?#{TAKE_OBJ}/i,
    /you\s+pick\s+up\s+(?:#{THE})?#{TAKE_OBJ}/i,
    /you\s+are\s+now\s+holding\s+(?:#{THE})?#{TAKE_OBJ}/i,
  ]

  IT = /^(it|them)$/i

  @@win = nil

  ## Change this to non-nil to print out debugging info
  @@debug = nil

  def debug(*msg)
    if @@debug
      $stdout.puts msg
    end
  end

  IDENTIFY_BY_DESCRIPTION = 0
  IDENTIFY_BY_SHORTNAME   = 1

  SHORTNAME_CLASSIC  = 0
  SHORTNAME_CAPITALIZED = 1
  SHORTNAME_MOONMIST = 2
  SHORTNAME_WITNESS  = 3
  SHORTNAME_ADRIFT   = 4
  SHORTNAME_ALL_CAPS = 5

  attr_reader   :shortName
  attr_accessor :identify, :map

  def shortName=(x)
    @shortName = x
    if x == SHORTNAME_ADRIFT
      @prompt = /^[a-z]/
    else
      @prompt = /^>\s*/
    end
  end


  #
  # Handle a take action
  #
  def take(move, objs)
    return unless @here
    if @here.objects != '' and @here.objects[-1,1] != "\n"
      @here.objects << "\n"
    end

    objs.each { |cmd, dummy, obj|
      next if not obj or not move[:reply]

      objlist = obj.split(',')
      o = objlist[0]
      if objlist.size == 1 and o != 'all'
	# ignore 'get up'
	next if cmd == 'get' and (o == 'up' or o == 'off')
	o = @last_obj if o =~ IT
	next if not o
	if move[:reply][0] =~ /^\((.*)\)$/
	  nobj = $1
	  words = nobj.split(/\s+/)
	  if words.size < 7
	    # Acclaration, like:
	    # > get mask
	    # (the brown mask)
	    # Taken.
	    o = nobj
	  else
	    # too big of an aclaration... probably something like
	    # (putting the xxx in your bag to make room)
	  end
	end
	o.sub!(ARTICLE, '')
	status = move[:reply].to_s
	TAKE_OK.each { |re|
	  if status =~ re then
	    obj = $1 || o
	    obj = o if obj =~ /\b(it|them)\b/
	    @last_obj = obj
	    # Take succeeded, change object o
	    if not @objects.has_key?(obj) and
		not @here.objects =~ /\b#{obj}\b/
	      @here.objects << obj << "\n"
	      @objects[obj] = 1
	    end
	    break
	  end
	}
      else
	# Handle multiple objects
	move[:reply].each { |reply|
	  o, status = reply.split(':')
	  next if not status
	  next if o.split(' ').size > 6 # ignore if too many words
	  o.sub!(ARTICLE, '')
	  TAKE_OK.each { |re|
	    if status =~ re then
	      if o and not @objects.has_key?(o) and
		  not @here.objects =~ /\b#{o}\b/
		@here.objects << o << "\n"
		@objects[o] = 1
	      end
	      @last_obj = o
	      break
	    end
	  }
	}
      end
    }
    @here.objects.squeeze("\n")
  end

  #
  # Add a new room to the automapper
  #
  def add(room)
    @rooms << room
  end

  #
  # Remove some rooms from the automap knowledge (user removed these manually)
  #
  def remove(rooms)
    rooms.each { |r| @rooms.delete(r) }
  end


  #
  # Given a room description, parse it to try to find out all exits 
  # from room.
  #

  DIRS  = {
    # SWD added variants used in e.g. YAGWAD
    'north-east' => 1, 'south-east' => 3, 'south-west' => 5, 'north-west' => 7,
    # Usual directions
    'north' => 0, 'northeast' => 1, 'east' => 2, 'southeast' => 3, 
    'south' => 4, 'southwest' => 5, 'west' => 6, 'northwest' => 7,
  }

  # SWD: hack: the variants with dashes must come first
  # (so that regexes matches 'north-east' in preference to 'north'),
  # so we manually prepend their names.  The duplication is harmless,
  # it just makes the regexes slightly slower in the non-match case.
  DIR = '(' + DIRS.keys.join('\b|') + ')'
  OR = '(?:and|or)'

  EXITS_REGEX = 
    [
    # paths lead west and north
    /(run|bears|lead|wander|winds|go|continues)\s+#{DIR}\s+#{OR}\s+#{DIR}\b/i, 
    # to the east or west
    /to\s+the#{DIR}\s+#{OR}\s+(to\s+the\s+)?#{DIR}\b/i,
    # You can go south
    /you\s+can\s+go#{DIR}\b/i,
    # to the east
    /to\s+the\s+#{DIR}\b/i,
    # east-west corridor
    /[\.\s+]#{DIR}[\/-]#{DIR}\s+(passage|corridor)/i, 
    # East is the postoffice
    /\b#{DIR}\s+is/i,
    # Directly north
    /\bDirectly\s+#{DIR}/i,
    # continues|lies|etc... east
    /(runs|bears|leads|heads|opens|winds|continues\s+on|continues|branches|lies|wanders|bends|curves)\s+#{DIR}\b/i,
    /(running|leading|heading|opening|branching|lying|wandering|looking|bending)\s+#{DIR}\b/i,
  ]

  # passage westwards
  # gap in the northeast corner


  EXITS_SPECIAL = { 
    /four\s+directions/i => [0, 2, 4, 6],
    /four\s+compass\s+points/i => [0, 2, 4, 6],
    /all\s+directions/i  => [0, 1, 2, 3, 4, 5, 6, 7],
  }

  def parse_exits(r, desc)
    return if not desc
    exits = []

    # Now, start searching for stuff

    # First try the special directions...
    EXITS_SPECIAL.each { |re, dirs|
      if desc =~ re
	exits += dirs
	break
      end
    }

    # If that failed, start searching for exits
    if exits.empty?
      EXITS_REGEX.each { |re|
	matches = desc.scan(re)
	next if matches.empty?
	matches.each { |arr|
	  arr.each { |m|
	    next unless DIRS[m]
	    exits << DIRS[m]
	  }
	}
      }
    end

    exits.uniq!

    # Add a 'stub' for the new connection
    exits.each { |exit|
      next if r[exit]
      begin
	c = @map.new_connection( r, exit, nil )
	c.dir = Connection::AtoB
	debug "\tADDED STUB #{c}"
      rescue ConnectionError
      end
    }
  end


  def parse_line(line)
    return unless line
    @map.mutex.synchronize do
      _parse_line(line)
    end

    if @map.kind_of?(FXMap)
      @map.clear_selection
      @here.selected = true if @here
      @map.create_pathmap
      @map.zoom = @map.zoom
      @map.center_view_on_room(@here) if @here
      @map.draw
    end
  end

  def _parse_line(line)
    @moves.clear

    #
    # Read all commands
    #
    loop do
      line.sub!(@prompt, '') if @prompt.to_s =~ />/
      line.chop!
      line.sub!(/\s+$/, '')
      cmd = line

      # Read reply
      reply = []
      while line = @f.gets
	break if line =~ @prompt
	line.chop!
	line.sub!(/\s+$/,'')
	reply << line
      end

      if cmd =~ UNDO
	if @moves.size < 2
	  @here = nil  # out of moves, no clue where we are
	else
	  @moves.pop
	end
      else
	move = { }

	# Replace all 'THEN' in command for periods
	cmd.sub!(THEN, '.')
	# and all ANDs for commas
	cmd.sub!(/\band\b/i,',')
	# and multiple periods for just one
	cmd.sub!(/\s*\.+\s*/, '.') 

	move[:cmd]   = cmd
	move[:reply] = reply
	@moves << move
      end

      break if not line

    end


    # Step 2
    @restart = false
    tele = nil
    @moves.each { |move|
      cmd = move[:cmd]
      next if cmd =~ IGNORE or cmd =~ OTHERS
      if cmd =~ UNSCRIPT
	tele = 1
	@here = nil
	next
      end

      if @restart and cmd =~ YES
	@here = nil
      else
	@restart = false
	tele = nil
      end

      if cmd =~ RESTART
	@restart = true
	tele = 1
      end

      if cmd =~ RESTORE
	if move[:reply].join() =~ RESTORE_OK
	  @here = nil
	  tele = 1
	else
	  next
	end
      end

      name = nil
      desc = ''
      roomflag = false
      desc_gap = false
      startup = false
      rooms = []
      move[:reply].each { |r|
	tele = 1 if r =~ DEAD

	if r =~ STARTUP
	  # Dealing with a startup message, such as:
	  # MY GAME
	  # Copyright (C) 1984 ComputerQuest
	  # We skip the whole thing until the next blank line
	  debug "#{r} skipped due to startup"
	  startup = true
	  desc = ''
	  name = nil
	  roomflag = false
	  desc_gap = false
	  @here = nil
	  tele = 1
	  next
	end
	next if startup and r !~ BLANK
	startup = false

	if not roomflag and r !~ BLANK and n = room_name(r)
	  debug "Found room #{n}"
	  roomflag = true
	  desc_gap = false
	  name = n
	  desc = ''
	  next
	end

	if not desc_gap and roomflag and r =~ BLANK and desc == ''
	  desc_gap = true
	  next
	end


	if roomflag and r !~ BLANK
	  desc << r << "\n"
	  next
	end

	if r =~ BLANK and roomflag
	  if desc.count("\n") == 1 and desc =~ /\?$/
	    # A "What next?" type of prompt, not a room description
	    desc = ''
	  end
	  if desc == ''
	    desc = nil
	  else
	    desc.gsub!(/\n/, ' ')
	    desc.strip!
	  end

	  rooms << {
	    :name => name,
	    :desc => desc,
	    :tele => tele
	  }
	  roomflag = false
	  desc_gap = false
	  name = nil
	  desc = ''
	  tele = nil
	end
      }
      
      # Oops, there was no newline between room description and prompt and
      # we missed the last room.
      # This happens for example with Magnetic Scrolls transcripts.
      if name
	rooms << {
	  :name => name,
	  :desc => desc,
	  :tele => tele
	}
      end

      if not rooms.empty?
	move[:rooms] = rooms
	move[:look]  = true if cmd =~ LOOK
	move[:reply] = nil
      end
    }


    @moves.each { |move|
      cmd  = move[:cmd]
      if objs = cmd.scan(TAKE)
	take(move, objs)
      end
	
      if not move[:rooms]
	# Check if a moving command failed
	if cmd =~ GO
	  dir = $3
	  # See if a stub direction exits in that direction
	  if @here and DIRMAP[dir] then
	    dir = DIRMAP[dir]
	    next unless @here[dir]

	    if @here[dir].stub?
	      # Check if reply was that there's no exit there.
	      NO_EXIT.each { |re|
		if move[:reply][0] =~ re
		  # If so, remove it... automapper got it wrong.  Not an exit.
		  @map.delete_connection(@here[dir])
		  break
		end
	      }
	    end

	    # Check if there is a closed door
	    if @here[dir] and @here[dir].type == Connection::FREE
	      CLOSED_EXIT.each { |re|
		if move[:reply][0] =~ re
		  # If so, flag it
		  @here[dir].type = Connection::CLOSED_DOOR
		  break
		end
	      }
	    end
	  end
	end
	next
      end

      move[:rooms].each { |room|
	name = room[:name]
	debug "SECTION: #{@map.section}"
	debug "HERE IS: #{@here}"
	debug "CMD:     #{cmd}"
	debug "ENDS AT: #{name}"

	desc = room[:desc].to_s
	desc.gsub!(/(\w)\s*\n/, '\1 ')

	line = move[:line]
	
	# If we teleported, try to find room 
	if room[:tele]
	  debug "\t ****TELEPORT TO #{name}****"
	  @here = find_room(name, desc)
	  debug "\t TO: #{@here}"
	end

	# Make sure the user has not deleted the current room from map
	# and that we are in the proper section.
	if @here
	  found = false
	  @map.sections.each_with_index { |sect, idx|
	    if sect.rooms.include?(@here)
	      found = true
	      if idx != @map.section
		@map.fit
		@map.section = idx
	      end
	      break
	    end
	  }
	  @here = nil if not found
	end

	# If it is a look command or we don't know where we are yet,
	# set current room.
	if move[:look] or not @here
	  if move[:look] and name =~ DARKNESS
	    @here = find_room(name, desc) if @here and not @here.darkness
	  else
	    @here = find_room(name, desc)
	  end
	  @here = new_room(move, name, desc) unless @here
	  @here.selected = true
	  next
	end

	cmd.sub!(GO, '')
	dir = $3

	# Swallow everything until next command (separated by .)
	cmd.sub!(/.*\./, '')

	debug "MOVED IN DIRECTION: #{dir}  CMD LEFT:#{cmd}"
	if not cmd
	  debug "Oops... run out of commands."
	  break
	end

	sect  = @map.section

	# Otherwise, assume we moved in some way.  Try to find the new room.
	if name =~ DARKNESS
	  idx = DIRMAP[dir] || ODIRMAP[dir]
	  # Moving to a dark room is special.  We verify the exit to see
	  # if it was already moving to a dark room (in which case it
	  # becomes "there") or if it was moving to some other room (in
	  # which case we flag it as dark and make it there)
	  if idx and @here[idx]
	    c = @here[idx]

	    if c.roomA == @here
	      b = c.roomB
	    else
	      b = c.roomA
	    end

	    if not b
	      there = nil
	    else
	      if b.name !~ DARKNESS
		b.darkness = true
	      end
	      there = b
	    end
	  else
	    # No connection yet, create dark room
	    there = nil
	  end
	else
	  there = find_room(name, desc)
	end

	next if there == @here


	go  = nil
	if DIRMAP[dir]
	  dir = DIRMAP[dir]
	elsif ODIRMAP[dir]
	  go  = ODIRMAP[dir]
	  debug "#{dir} move #{go}"
	  dir = choose_dir(@here, there, go)
	else
	  # special move --- teleport/death/etc.
	  go  = 0
	  dir = choose_dir(@here, there, go)
	end
	debug "MOVED IN DIR INDEX: #{dir}"

	@here.selected = false
	if not there
	  # Unvisited -- new room
	  @here = new_room(move, name, desc, dir, @here, go)
	else
	  # Visited before -- new link
	  if sect == @map.section # don't conn
	    new_link(move, @here, there, dir, go)
	  end
	  @here = there
	end
      }
    }

    @moves.clear
    @map.fit
    if @map.kind_of?(FXMap)
    end
  end

  def find_room(name, desc)
    case @identify
    when IDENTIFY_BY_DESCRIPTION
      return find_room_by_desc(name, desc)
    when IDENTIFY_BY_SHORTNAME
      return find_room_by_name(name, desc)
    end
  end

  def find_room_by_name(name, desc)
    bestscore = 0
    best = nil

    @map.sections.each_with_index { |sect, idx|
      sect.rooms.each { |room|
	score = 0
	score += 1 if room.name == name

	if score == 1 and desc and room.desc
	  # We have a description...
	  # Try exact description match first
	  score += 100 if room.desc == desc
	  
	  # Try substring match
	  score += 50 if room.desc.index(desc)
	  
	  # If we have a room where both name and desc match,
	  # we get a better score than just description only.
	  # This is to help, for example, Trinity, where two rooms have
	  # the exact description but different name.
	  score += 1 if room.name == name and score > 0

	  # If still no luck, try first N words
	  if score == 1
	    dwords = room.desc.split(' ')
	    words  = desc.split(' ')
	    match  = true
	    count  = 0
	    0.upto(desc.size) { |i|
	      # Ignore some words (like open/close, which may just mean
	      # some doors changed state)
	      next if words[i] =~ DESC_IGNORE

	      if words[i] != dwords[i]
		if count < DESC_MINWORDS
		  match = false
		  break
		else
		  next
		end
	      end
	      count += 1
	    }
	    
	    score += count if match
	  end
	end
	next if score <= bestscore
	bestscore = score
	best = [room, idx]
      }
    }

    return nil if not best
      
    # Make sure we are in the right section
    if best[1] != @map.section
      @map.fit
      @map.section = best[1]
    end
    if desc and (not best[0].desc or best[0].desc == '')
      best[0].desc = desc
    end
    return best[0]
  end

  def find_room_by_desc(name, desc)
    bestscore = 0
    best = nil

    @map.sections.each_with_index { |sect, idx|
      sect.rooms.each { |room|
	score = 0

	if desc and room.desc
	  # We have a description...
	  # Try exact description match first
	  score += 100 if room.desc == desc
	  
	  # Try substring match
	  score += 50 if room.desc.index(desc)
	  
	  # If we have a room where both name and desc match,
	  # we get a better score than just description only.
	  # This is to help, for example, Trinity, where two rooms have
	  # the exact description but different name.
	  score += 1 if room.name == name and score > 0

	  # If still no luck, try first N words
	  if score == 0
	    dwords = room.desc.split(' ')
	    words  = desc.split(' ')
	    match  = true
	    count  = 0
	    0.upto(desc.size) { |i|
	      # Ignore some words (like open/close, which may just mean
	      # some doors changed state)
	      next if words[i] =~ DESC_IGNORE

	      if words[i] != dwords[i]
		if count < DESC_MINWORDS
		  match = false
		  break
		else
		  next
		end
	      end
	      count += 1
	    }
	    
	    score += count if match and room.name == name
	  end
	else
	  # Just the name, not so good
	  score += 1 if room.name == name
	end
	next if score <= bestscore
	bestscore = score
	best = [room, idx]
      }
    }

    return nil if not best
      
    # Make sure we are in the right section
    if best[1] != @map.section
      @map.fit
      @map.section = best[1]
    end
    if desc and (not best[0].desc or best[0].desc == '')
      best[0].desc = desc
    end
    return best[0]
  end

  def room_name(line)
    case @shortName
    when SHORTNAME_ALL_CAPS
      return room_name_all_caps(line)
    when SHORTNAME_CAPITALIZED
      return room_name_classic(line, false)
    when SHORTNAME_MOONMIST
      return room_name_moonmist(line)
    when SHORTNAME_WITNESS
      return room_name_witness(line)
    else
      return room_name_classic(line, true)
    end
  end

  def capitalize_room(line)
    words = line.split(' ')
    words.each_with_index { |w, idx|
      if idx > 0 and w =~ NAME_UNCAP
	w.downcase!
      else
	w.capitalize!
      end
    }
    return words.join(' ')
  end

  def room_name_alan(line)
    return false if line !~ /^[^.]+\.$/
    line.sub!(/\.$/, '')
    return room_name_classic(line, true)
  end

  def room_name_witness(line)
    if line =~ /^You\sare\s(?:now\s)?(?:[io]n\s)?(?:#{THE})?([\w'\d\s\-_]+)\.$/
      return false if $1 =~ /own feet/
      return $1
    elsif line =~ /^\(([\w\s]+)\)$/
      return $1
    else
      return false
    end
  end

  def room_name_moonmist(line)
    return false if line =~ /^\(You are not holding it.\)$/
    if line =~ /^\(You\sare\s(?:now\s)?(?:[io]n\s)?(?:#{THE})?([\w'\d\s\-_]+)\.\)$/
      return capitalize_room( $1 )
    else
      return false
    end
  end
    
  #
  # Determine if line corresponds to a room name
  #
  def room_name_classic(line, all_capitals = true)
    # Check if user/game has created a room with that name already
    return line if find_room(line, nil)

    # We have a room if we match darkness
    return line if line =~ DARKNESS

    # Remove unwanted stuff line (on the bed)
    line.sub!(NAME_REMOVE, '')

    # Check if user/game has created a room with that name already
    return line if find_room(line, nil)

    # Remove periods from salutations
    line.sub!(SALUTATIONS, '\1')

    # quick check for invalid format
    return false if line =~ NAME_INVALID

    # Qucik check for word characters
    return false unless line =~ /\w/

    # Check if we start line with uncapitalized words or symbols
    return false if line =~ /^[ a-z\/\\\-\(\)']/

    # Check if line holds only capitalized words or several spaces together
    # or a quote or a 1) line.  If so, not a room.
    return false if line =~ /^[A-Z\d,\.\/\-"'\s]+$/ or line =~ /\s\s/ or 
      line =~ /^".*"$/ or line =~ /^"[^"]+$/ or line =~ /^\d+\)/

    # Check word count (if too many, not a room)
    words = line.split(' ')
    return false if words.size > NAME_MAXWORDS

    return false if not all_capitals and words.size > 6

    # If not, check all words of 4 chars or more are capitalized
    # and that there are no 3 or more short letter words together 
    # (which means a diagram)
    num = 0
    words.each { |w|
      return false if all_capitals and w =~ /^[a-z]/ and w !~ NAME_UNCAP
      if w.size <= 2
	num += 1
	return false if num > 2
      else
	num = 0
      end
    }

    # Restore period to salutations
    line.sub!(/\b#{SALUT}\b/, '\1.')

    # Okay, it is a room.
    return line
  end

  #
  # Determine if line corresponds to a room name
  #
  def room_name_all_caps(line)
    # Check if user/game has created a room with that name already
    return line if find_room(line, nil)

    # We have a room if we match darkness
    return line if line =~ DARKNESS

    # Remove unwanted stuff line (on the bed)
    line.sub!(NAME_REMOVE, '')

    # Check if user/game has created a room with that name already
    return line if find_room(line, nil)

    # Remove periods from salutations
    line.sub!(SALUTATIONS, '\1')

    # quick check for invalid format
    return false if line =~ NAME_INVALID

    # Qucik check for word characters
    return false unless line =~ /\w/

    # Check if we start line with uncapitalized words or symbols
    return false if line =~ /^[ a-z\/\\\-\(\)']/

    # Check if line holds only capitalized words or several spaces together
    # or a quote or a 1) line.  If so, not a room.
    return false if line =~ /^[a-z\d,\.\/\-"'\s]+$/ or line =~ /\s\s/ or 
      line =~ /^".*"$/ or line =~ /^"[^"]+$/ or line =~ /^\d+\)/

    # Check word count (if too many, not a room)
    words = line.split(' ')
    return false if words.size > NAME_MAXWORDS


    # If not, check all words of 4 chars or more are capitalized
    # and that there are no 3 or more short letter words together 
    # (which means a diagram)
    num = 0
    words.each { |w|
      if w.size <= 2
	num += 1
	return false if num > 2
      else
	num = 0
      end
    }

    # Restore period to salutations
    line.sub!(/\b#{SALUT}\b/, '\1.')

    # Okay, it is a room.
    return line
  end

  #
  # Create a new room
  #
  def new_room( move, name, desc, dir = nil, from = nil, go = nil )
    b = nil
    dark = false

    if not from
      debug "FROM undefined.  Increase section #{name}"
      @section += 1
      @map.new_section if @section >= @map.sections.size
      r = @map.new_room(0, 0)
      r.name = name
    else

      darkexits = []
      if name =~ DARKNESS
	dark = true
      else
	dark = false
	if from[dir]
	  # oops, we had a connection there. 
	  c = from[dir]
	  b = c.opposite(from)
	  if b and b.name =~ DARKNESS
	    # Was it a dark room that is now lit?  
	    # if so, set dark flag and delete dark room
	    @map.delete_connection(c)
	    @map.delete_room_only(b)
	    dark = true
	    c = nil
	  end
	end
      end

      x = from.x
      y = from.y
      dx, dy = Room::DIR_TO_VECTOR[dir]
      x += dx
      y += dy
      @map.shift(x, y, dx, dy) if not @map.free?(x, y)


      debug "+++ New Room #{name} from #{from}"
      r = @map.new_room(x, y)
      r.name = name
      r.darkness = dark
      if b and dark
	b.exits.each_with_index { |de, didx| 
	  next unless de
	  @map.sections[@map.section].connections << de
	  r[didx] = de
	  if de.roomA == b
	    de.roomA = r
	  else
	    de.roomB = r
	  end
	}
      end
      c = nil
      if from[dir]
	# oops, we had a connection there. 
	c = from[dir]
	b = c.roomB
	if c.stub?
	  # Stub connection.  Update it.
	  debug "\tUPDATE #{c}"
	  odir = (dir + 4) % 8
	  c.exitAtext = go if go
	  c.type  = Connection::SPECIAL if go == 0
	  c.roomB = r
	  r[odir] = c
	  debug "\tNOW IT IS #{c}"
	else
	  # Probably a link that is complex
	  # or oneway.  Shift it to some other location
	  shift_link(from, dir)
	  c = nil
	end
      end
      if c == nil
	begin
	  c = @map.new_connection( from, dir, r )
	  c.exitAtext = go if go
	  c.type = Connection::SPECIAL if go == 0
	  c.dir  = Connection::AtoB
	rescue Section::ConnectionError
	end
      end
    end

    parse_exits(r, desc)

    # Update room description
    r.desc = desc
    return r
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
      debug "Warning.  Cannot shift connection."
    end
  end


  def new_link(move, from, to, dir, go)
    odir = (dir + 4) % 8
    c = nil
    # If we have something in the from direction
    if from[dir]
      c = from[dir]
      debug "\tMOVE #{c} DIR: #{dir}"
      if c.stub?
	# Stub connection, fill it
	c.roomB     = to
	c.exitAtext = go if go
	c.type      = Connection::SPECIAL if go == 0
	# we still need to check the destination to[odir]...
	if not to[odir]
	  # nothing to do
	elsif to[odir].stub?
	  @map.delete_connection(to[odir])
	  debug "\tREMOVE #{to[odir]}"
	else
	  # this end cannot be deleted.  we need to shift odir
	  debug "\tCHOOSE NEW DIR for #{odir}"
	  rgo = nil
	  if go and go > 0
	    rgo = rgo % 2 == 0? go - 1 : go + 1
	  end
	  odir = choose_dir(to, from, rgo, dir)
	  @map.delete_connection(to[odir]) if to[odir]
	  debug "\tSHIFTED DESTINATION TO EXIT #{odir}"
	end
	to[odir] = c
      elsif c.roomB == to
	# We already went this way.  Nothing to do.
	debug "\tWE ALREADY PASSED THRU HERE"
      elsif c.roomA == to
	# We verified we can travel thru this connection in both
	# directions.  Change its status to both.
	c.dir = Connection::BOTH
	debug "\tSECTION: #{@map.section}"
	debug "\tVERIFIED EXIT BOTH WAYS"
      else
	debug "\tOTHER"
	if c.roomA == from
	  b = c.roomB
	  if b.name =~ DARKNESS
	    debug "*** REPLACING DARK ROOM ***"
	    @map.delete_connection(c)
	    to.darkness = true
	    @map.delete_room(b)
	    c = nil
	  else
	    if c.exitAtext != 0
	      # if it was an up/down/in/out dir, we shift it
	      shift_link(from, dir)
	      c = nil
	    else
	      # else, we really have a problem in the map
	      debug "*** CANNOT AUTOMAP --- MAZE ***"
	      dir = Room::DIRECTIONS[dir]
	      @map.cannot_automap "Maze detected.\n'#{from}' #{dir} leads to '#{c.roomB}',\nnot to this '#{to}'."
	      self.stop
	      return nil
	    end
	  end
	else
	  debug "SHIFT LINK #{from} #{dir}"
	  # We have a connection that turns.  Move the link around
	  shift_link(from, dir)
	  c = nil
	end
      end
    end

    if not c and to[odir]
      c = to[odir]
      if c.stub?
	debug "\tREMOVE #{to[odir]} and REPLACE with #{c}"
	# Stub connection, fill it
	c.roomB   = from
	# @map.delete_connection(from[dir]) if from[dir].stub?
	from[dir] = c
	c.dir = Connection::BtoA
	c.exitBtext = go if go
	c.type  = Connection::SPECIAL if go == 0
      elsif c.roomB == from
	c.exitBtext = go if go
	c.type  = Connection::SPECIAL if go == 0
      else
	# We need to change odir to something else
	rgo = nil
	if go and go > 0
	  rgo = go % 2 == 0? go - 1 : go + 1
	end
	odir = choose_dir(to, from, rgo, dir)
	@map.delete_connection(to[odir]) if to[odir] and to[odir].stub?
	c = nil
      end
    end

    if not c
      # First, check all from exits that are AtoB to see if we have one
      # that goes to the room we want.
      from.exits.each_with_index { |e, idx|
	next unless e
	if e.roomA == to and e.dir == Connection::AtoB
	  c = e
	  from[idx] = nil
	end
      }
      if c
	# If so, make that connection go both ways and attach it to
	# current direction.
	from[dir]   = c
	c.dir       = Connection::BOTH
	c.exitAtext = go if go
	c.type  = Connection::SPECIAL if go == 0
      end
    end

    if not c
      # No link exists -- create new one.  
      begin
	c = @map.new_connection( from, dir, to, odir )
	c.exitAtext = go if go
	c.dir = Connection::AtoB
      rescue Section::ConnectionError
      end
    end

    return c
  end


  # Choose a direction to represent up/down/in/out.
  def choose_dir(a, b, go = nil, exitB = nil)
    # Don't add a new connection if we already have a normal connection
    # to the room and we are moving up/down/etc.
    if go
      rgo = go % 2 == 0? go - 1 : go + 1
      debug "#{Connection::EXIT_TEXT[go]} <=> #{Connection::EXIT_TEXT[rgo]}"
      # First, check if room already has exit moving towards other room
      a.exits.each_with_index { |e, idx|
	next if not e
	roomA = e.roomA
	roomB = e.roomB
	if roomA == a and roomB == b
	  e.exitAtext = go if e.exitBtext == rgo
	  return idx
	elsif roomB == a and roomA == b
	  e.exitBtext = go if e.exitAtext == rgo
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
      inc   = dir % 2 == 1 ? 10 : 14
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

  def stop
    @t.kill if @t
  end

  def destroy
    @t.kill if @t
    @f.close if @f
    GC.start
  end


  def properties(modal = false)
    require 'IFMapper/TranscriptDialogBox'
    if not @@win
      @@win = TranscriptDialogBox.new(self)
    else
      @@win.copy_from(self)
    end
    if modal
      @@win.execute
    end
  end

  def initialize(map, file)
    @shortName = 0 
    @prompt    = /^>\s*/
    @identify  = 0

    @f        = nil
    @file     = file
    @map      = map
    @objects  = {}
    @moves    = []
    @here     = nil
    @section  = -1
    @last_obj = nil
  end

  # Step one user command at a time
  def step
    begin
      if @f.eof
        @map.status AUTOMAP_IS_WAITING_FOR_MORE_TEXT
      end
      FXApp.instance().runOnUiThread {parse_line(@f.gets)}
    rescue => e
      $stderr.puts e
      $stderr.puts e.backtrace
    end
  end

  def start
    if not @f
      @f = File.open(@file, 'r')
      while line = @f.gets
	if @map.name =~ /^Empty Map/ and line =~ TRANSCRIPT
	  if $1
	    @map.name = $1
	  else
	    @map.name = @f.gets.strip
	  end
	  @map.name = capitalize_room(@map.name)
	end
	break if @prompt =~ line
      end
      parse_line(line)
    end

    @t = Thread.new { 
      loop do
	self.step
	Thread.pass
	sleep 3
      end
    }
    @t.run
  end
end
