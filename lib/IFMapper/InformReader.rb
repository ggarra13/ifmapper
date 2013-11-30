
require "IFMapper/MapReader"


# Take a quoted Inform string and return a valid ASCII one, replacing
# Inform's special characters.
module InformUnquote
  TABLES = { 
    ":a" => "\204",
    ":e" => "\211",
    ":i" => "\213",
    ":o" => "\224",
    ":u" => "\201",
    ":y" => "\230",

    ":A" => "\216",
    ":E" => "\323",
    ":I" => "\330",
    ":O" => "\231",
    ":U" => "\232",

    "'a" => "\240",
    "'e" => "\202",
    "'i" => "\241",
    "'o" => "\242",
    "'u" => "\243",
    "'y" => "\354",

    "'A" => "\265",
    "'E" => "\220",
    "'I" => "\326",
    "'O" => "\340",
    "'U" => "\351",
    "'Y" => "\355",

    "^a" => "\203",
    "^e" => "\210",
    "^i" => "\214",
    "^o" => "\223",
    "^u" => "\226",

    "^A" => "\266",
    "^E" => "\322",
    "^I" => "\327",
    "^O" => "\342",
    "^U" => "\352",

    "`a" => "\205",
    "`e" => "\212",
    "`i" => "\215",
    "`o" => "\225",
    "`u" => "\227",

    "`A" => "\267",
    "`E" => "\324",
    "`I" => "\336",
    "`O" => "\343",
    "`U" => "\353",

    ",c" => "\207",
    ",C" => "\200",

    "~a" => "\306",
    "~A" => "\307",
    "~o" => "\344",
    "~o" => "\345",


    "~n" => "\244",
    "~N" => "\245",

    "!!"   => "\255",
    '\?\?' => "\250",

    ">>" => ">>",
    "<<" => "<<",

    # Missing 
    "LL" => "",  # British pound

    # greek letters
    "ss" => "",  # beta

    "et" => "",  # 
    "Et" => "",  # 
    "th" => "",  # thorn
    "Th" => "",  # thorn

    '\\o' => "",  # 
    '\\O' => "",  # 

    "oa" => "",  # o over a
    "oA" => "",  # o over A
    "ae" => "",
    "AE" => "",
    "oe" => "",
    "OE" => "",
  }

  def unquote(text)
    return '' unless text
    # deal with quotes
    text.gsub!(/\~/, '"')
    # and newlines
    text.gsub!(/\^/, "\n")

    # deal with accents and intl. chars
    TABLES.each { |k, v|
      text.gsub! /@#{k}/, v
    }

    # deal with zscii chars as numbers
    while text =~ /(@@(\d+))/
      text.sub!($1, $2.to_i.chr)
    end
    return text
  end
end


#
# Class that allows creating a map from an Inform source file.
#
class InformReader < MapReader

  STORY = /Constant\s+Story\s+\"([^"]+)\"/i

  DIRECTIONS = { 
    'n_to' => 0,
    'ne_to' => 1,
    'e_to' => 2,
    'se_to' => 3,
    's_to' => 4,
    'sw_to' => 5,
    'w_to' => 6,
    'nw_to' => 7,
    'u_to' => 8,
    'd_to' => 9,
    'in_to' => 10,
    'out_to' => 11
  }

  FUNCTION = /^\[ (\w+);/

  GO_OBJ = /\b(#{DIRECTIONS.keys.join('|').gsub(/_to/, '_obj')})\s*:/i


  # Direction list in order of positioning preference.
  DIRLIST = [ 0, 4, 2, 6, 1, 3, 5, 7 ]

  DIR_TO    = /(?:^|\s+)(#{DIRECTIONS.keys.join('|')})\s+/i

  DIR       = /(?:^|\s+)(#{DIRECTIONS.keys.join('|')})\s+(\w+)/i
  ENTER_DIR = /(?:^|\s+)(#{DIRECTIONS.keys.join('|')})\s+\[;\s*<<\s*Enter\s+(\w+)\s*>>/i

  attr_reader :map


  include InformUnquote

  class InformRoom < MapRoom
    include InformUnquote
  end

  class InformObject < MapObject
    include InformUnquote
  end


  def new_room
    super(InformRoom)
  end

  def new_obj(loc = nil)
    super(loc, InformObject)
  end

  #
  # Main parsing loop.  
  #
  def parse(file)
    # We start map at 0, 0
    @x, @y = [0, 0]
    @room  = nil

    if @map.kind_of?(FXMap)
      @map.options['Edit on Creation'] = false
      @map.window.hide
    end
    @map.section = 0

    @parsing      = nil
    @last_section = 0
    @ignore_first_section = true
    @room_idx = 0
    line_number = 0

    debug "...Parse... #{file.path}"
    while not file.eof?
      @line = ''
      while not file.eof? and @line == ''
	@line << file.readline()
	@line.sub!( /^\s*!.*$/, '')
	line_number += 1
      end
      # Remove comments at end of line
      @line.sub!( /\s+![^"]*$/, '')
      # Remove starting spaces (if any)
      @line.sub! /^\s+/, ''
      # Replace \n with simple space
      @line.gsub! /\n/, ' '
      next if @line == ''
      full_line = @line.dup
      begin
	parse_line
      rescue ParseError, MapError => e
	message = "#{e}.\nat #{file.path}, line #{line_number}:\n>>>> #{full_line};\n"
	raise message
      rescue => e
	message = "#{e}\n#{e.backtrace}" 
	raise message
      end
    end
    debug "...End Parse..."
  end


  CLASS       = /^class\s+(\w+)/i
  DOOR        = /(?:^|\s+)door_to(?:\s+([^,;\[]*)|$)/i
  INCLUDE     = /^#?include\s+"([^"]+)"/i
  PLAYER_TO   = /\bplayerto\((\w+)/i
  DESCRIPTION = /(?:^|\s+)description(?:\s*$|\s+"([^"]+)?("?))/i

  STD_LIB = [
    'Parser',
    'VerbLib',
    'Grammar'
  ]



  def find_file(file)
    return file if File.exists?(file)
    @include_dirs.each { |d|
      [ "#{d}/#{file}",
	"#{d}/#{file}.h",
	"#{d}/#{file}.inf", ].each { |full|	
	return full if File.exists?(full)
      }
    }
    return nil
  end

  #
  # Parse a line of file
  #
  def parse_line
    if @line =~ STORY
      @map.name = $1
      return
    end

    if @line =~ INCLUDE
      name = $1
      unless STD_LIB.include?(name)
	file = find_file(name)
	debug "include #{file}"
	if file
	  File.open(file, 'r') { |f| parse(f) }
	else
	  raise ParseError, "Include file '#{name}' not found"
	end
      end
    end

    if @line =~ CLASS
      @clas = $1
      debug "CLASS: #@clas"
      if @classes.has_key?(@clas)
	if @obj
	  @classes[@clas].each { |k, v| @obj.send("#{k}=", v) }
	elsif @room
	  @classes[@clas].each { |k, v| @room.send("#{k}=", v) }
	end
      else
	@classes[@clas] = {}
	@tag = @name = nil
      end
    end

    re = /^(#{@classes.keys.join('|')})((?:\s+->)+)?(\s+(\w+))?(\s+"([^"]+)")?(\s+(\w+))?/
    if @line =~ re
      @clas = $1
      prev  = $2
      @tag  = $4 || $6
      @name = $6
      @desc = ''
      @in_desc = false

      loc  = $8
      if prev and @room
	loc = @room.tag 
      end

      debug <<"EOF"
Name    : #@name
Class   : #@clas
Tag     : #@tag
Location: #{loc}  #{loc.class}
EOF

      @obj = nil

      c = @classes[@clas]
      if c[:door]
	new_door
      elsif @tag and (loc or c[:scenery] or c[:static])
	new_obj(loc)
	if c[:scenery] or c[:static]
	  @obj.scenery = true 
	end
      else
	@obj = @room = nil
	new_room if @tag and @name and c.has_key?(:light)
      end
      @before = false
      @go     = false

    end

    if @in_desc
      text = @line.scan( /\s*([^"]+)("\s*[,;])?/ )
      text.each { |t, q|
	@desc << t
	@in_desc = nil if q
      }
    end

    if @desc and @line =~ DESCRIPTION
      @desc << $1 if $1
      @in_desc = true unless $2
    end


    if @line =~ FUNCTION
      @functions << $1
    elsif @tag and @line =~ DOOR
      old_locations = []
      if @obj
	old_locations = @obj.location
	@objects.delete(@obj) if @obj.tag == @tag
	@tags[@tag] = nil
      end
      new_door
      @obj.location  = $1.split(' ')
      @obj.location += old_locations if old_locations.size > 0
    else
      dirs = @line.scan(DIR_TO) + @line.scan(DIR) + @line.scan(ENTER_DIR)
      if dirs.size > 0
	new_room if not @room
	dirs.each { |d, room|
	  dir = DIRECTIONS[d]
	  @room.exits[dir] = room
	}
      end      
    end


    if @line =~ /\bbefore\b/i
      @before = true
    end

    if @line =~ /\bgo\s*:/i and @room and @before
      if @line =~ GO_OBJ
	dir = DIRECTIONS[$1]
	if @line =~ PLAYER_TO
	  @room.exits[dir] = $1
	end
      end
    end

    if @obj.kind_of?(MapObject) and @before
      if @line =~ PLAYER_TO
	@obj.enterable << $1
	@obj.scenery = nil
      end
    end


    if @line =~ /(?:^|\s+)has\s+([\w\s]+)[,;]/i
      props = $1.split
      char  = props.include?('male') or props.include?('female')
      if @obj and char
	@obj.scenery = false
      end
      props.each { |p|
	if not @tag
	  if p[0,1] == '~'
	    @classes[@clas][p[1,-1].to_sym] = false
	  else
	    @classes[@clas][p.to_sym] = true
	  end
	else
	  if p == 'locked' and @doors.size > 0
	    @doors[-1].locked = true
	  end
	  if not char
	    if p =~ /(?:static|scenery)/ and @obj
	      @objects.delete(@obj)
	    end
	  end
	  if p =~ /(\~)?light/
	    new_room if not @room
	    @room.light = ($1 != '~')
	  end
	end
      }
    end

    if @line =~ /\bfound_in\s+([^;,\[]*)/
      if @tag and not @obj
	new_obj(loc)
      end
      if @obj
	locs = $1.split
	@obj.location = locs
	debug "#{@obj} #{@obj.location} FOUND_IN: #{locs.join(' ')}"
      end
    end
  end


  def set_include_dirs
    # Try to find inform(.exe) in path.
    paths = ENV['PATH'].split(SEP)
    paths.each { |p|
      next if not File.directory?(p)
      Dir.foreach(p) { |x|
 	if x =~ /^inform(.exe)?$/i
	  @include_dirs << p
	  @include_dirs << p + "/Base"
	  @include_dirs << p + "/Contrib"
	  @include_dirs << p + "/../Contrib"
	  @include_dirs << p + "/../Lib/Contrib"
	  break
	end
      }
    }
  end


  def initialize(file, map = Map.new('Inform Map'))
    debug "Initialize"
    @classes = { 'Object' => {} }

    super

    if @map.kind_of?(FXMap)
      @map.filename   = file.sub(/\.inf$/i, '.map')
      @map.options['Location Description'] = true
      @map.window.show
    end
    @objects   = nil
    @tags      = nil   # save some memory by clearing the tag list
    @rooms     = nil   # and room list
  end
end


if $0 == __FILE__
  p "Opening file '#{ARGV[0]}'"
  BEGIN { 
    $LOAD_PATH << 'C:\Windows\Escritorio\IFMapper\lib'
  }

  require "IFMapper/Map"
  InformReader.new(ARGV[0])
end
