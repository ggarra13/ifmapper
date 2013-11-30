
require 'IFMapper/MapReader'


# Take a quoted TADS string and return a valid ASCII one, replacing
# TADS's special characters.
module TADSUnquote
  def unquote(text)
    return '' unless text
    text.gsub!(/\\'/, "'")  # restore quotes
    text.gsub!(/\\"/, '"')  # restore quotes
    text.gsub!(/<<.*>>/, '')  # remove embedded functions
    text.gsub!(/<\/?q>/, '"') # Change quotes
    return text
  end
end


#
# Class that allows creating a map from an TADS source file.
#
class TADSReader < MapReader

  # TADS 3 directional properties need to be spelled fully
  DIRECTIONS = { 
    'north' => 0,
    'northeast' => 1,
    'east' => 2,
    'southeast' => 3,
    'south' => 4,
    'southwest' => 5,
    'west' => 6,
    'northwest' => 7,
    'up' => 8,
    'down' => 9,
    'in' => 10,
    'out' => 11
  }

  FUNCTION = /^\[ (\w+);/

  GO_OBJ = /\b(#{DIRECTIONS.keys.join('|').gsub(/_to/, '_obj')})\s*:/i

  # SINGLE QUOTED STRING
  SQ = '((?:\\\\\'|[^\'])+)'

  # DOUBLE QUOTED STRING
  DQ = '((?:\\\"|[^"])+)'

  # Equal sign (TADS supports C or Pascal-like =)
  EQ = '\s*(?:=|\:=)\s*'


  DIR_EQ     = "(#{DIRECTIONS.keys.join('|')})#{EQ}"
  DIR_TO     = /(?:^|\s+)#{DIR_EQ}/
  DIR        = /(?:^|\s+)#{DIR_EQ}(\w+)/
  DIR_OPEN   = /(?:^|\s+)#{DIR_EQ}\(\s*[\d\w]+\.isOpen\s*\?\s*([\d\w]+)/
  DIR_INSELF = /(?:^|\s+)#{DIR_EQ}\(\s*[\d\w]+\.isIn\(\s*self\s*\)\s*\?\s*([\d\w]+)/
  DIR_MSG    = /(?:^|\s+)(#{DIRECTIONS.keys.join('|')})\s*\:\s*TravelMessage\s*\{\s*\->\s*(\w+)/

  ENTER_DIR = /(?:^|\s+)(#{DIRECTIONS.keys.join('|')})\s*:\s*.*<<replaceAction\(Enter\s*,\s*(\w+)/i 

  OBJLOCATION = /(?:^|\s+)(?:(?:destination|location)#{EQ}(\w+)|@(\w+)|locationList#{EQ}\[([\w\s,]+)\])/
  OBJNAME     = /(?:^|\s+)name#{EQ}(?:'#{SQ}'|\(\s*described\s*\?\s*'#{SQ}')/
  CONNECTOR   = /(?:^|\s+)room\d+\s*#{EQ}\s*(\w+)/
  ROOMNAME    = /(?:^|\s+)roomName#{EQ}'#{SQ}'/
  DESCRIPTION = /(?:^|\s+)desc#{EQ}(?:\s*$|\s+"#{DQ}?("?))/


  # TADS3 template definitions are like:
  #  [+] [TAG:] Classes ['adjective nouns'] 'Name' @location
  PLUS = '\s*([\+]+\s*)?'
  TAG  = '(?:([\w\d]+)\s*:)?\s*'
  CLS  = '([\w\s\-\>,]+)'
  NOMS = "(?:\'#{SQ}\')?"
  NAME = "(?:\s+\'#{SQ}\')?"
  LOC  = '\s+(?:@([\d\w]+))?'

  CLASS       = /^class\s+(\w+)\s*:\s*([\w,\s]+)/i
  DOOR        = /(?:^|\s+)door_to(?:\s+([^,;]*)|$)/i
  INCLUDE     = /^#include\s+[<"]([^">]+)[">]/

  STD_LIB = [
    'adv3.h',
    'en_us.h',
    'bignum.h',
    'array.h',
    'tok.h',
    'bytearr.h',
    'charset.h',
    'dict.h',
    'reflect.h',
    'gramprod.h',
    'systype.h',
    'tads.h',
    'tadsgen.h',
    'tadsio.h',
    't3.h',
    'vector.h',
    'file.h',
    't3test.h',
    'strcomp.h',
  ]


  attr_reader :map



  include TADSUnquote

  class TADSRoom < MapRoom
    include TADSUnquote
  end

  class TADSObject < MapObject
    include TADSUnquote
  end


  def new_room
    super(TADSRoom)
  end

  def new_obj(loc = nil)
    super(loc, TADSObject)
  end

  #
  # Main parsing loop.  We basically parse the file twice to
  # solve dependencies.  Yes, this is inefficient, but the alternative
  # was to build a full parser that understands forward dependencies.
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

    @in_desc      = false
    @parsing      = nil
    @last_section = 0
    @ignore_first_section = true
    @room_idx = 0
    @gameid = nil
    @obj = nil
    line_number = 0

    debug "...Parse... #{file.path}"
    while not file.eof?
      @line = ''
      while not file.eof? and @line == ''
	@line << file.readline()
	@line.sub!( /^\s*\/\/.*$/, '')
	line_number += 1
      end
      # todo: Remove multi-line comments
      # Remove comments at end of line
      @line.sub!( /\s+\/\/[^"]*$/, '')
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

  def get_parent_classes(clist)
    ret = []
    clist.each { |c|
      c.strip!
      if @classes[c]
	ret += get_parent_classes(@classes[c])
      else
	ret << c
      end
    }
    return ret
  end

  #
  # Parse a line of file
  #
  def parse_line
    if @line =~ INCLUDE
      name = $1
      unless STD_LIB.include?(name)
	file = find_file(name)
	if file
	  File.open(file, 'r') { |f| parse(f) }
	else
	  raise ParseError, "Include file '#{name}' not found"
	end
      end
    end

    if @line =~ CLASS
      @clas = $1
      inherits = $2
      debug "CLASS: #@clas : #{inherits}"
      @classes[@clas] = inherits.split(/\s*,\s*/)
      @tag = @name = nil
      return
    end

    

    #
    # Handle room description
    #
    if @in_desc == 1 then
      if @line =~ /^\s*"#{DQ}("\s*)?$/
	# check for possible start description
	@room.desc << $1
	if $2
	  @in_desc = nil
	else
	  @in_desc = 2
	end
	return
      elsif @room.name == @room.tag and @line =~ /^\s*#{NOMS}#{NAME}\s*/
	name = $1 || $2
	@room.name = name
      end
    end

    if @in_desc == 2
      @line =~ /\s*#{DQ}?("\s*)?/
      @room.desc << $1 if @room and $1
      @in_desc = nil if $2
      return
    end

    if @gameid and @line =~ /name\s*=\s*'(#{SQ})'/
      @map.name = $1
    end

    # TADS3 definition is like:
    #  [+] [TAG:] Classes ['adjective nouns'] 'Name' @location
    re = /^#{PLUS}#{TAG}#{CLS}#{NOMS}#{NAME}#{LOC}/
    if @line =~ re


      prev  = $1
      @name = [$5, $4]
      @tag  = $2
      @clas = $3  # can be several classes
      @in_desc = false

      if @tag 
	if @clas == "GameID"
	  @gameid = true
	else
	  @gameid = false
	end
      end

      loc  = $6
      if prev and @room
	loc = @room.tag
      end

      ## For user classes, flatten inheritance
      clist = @clas.split(/(?:\s*,\s*|\s)/)
      flist = get_parent_classes(clist)
      @clas = flist.join(' ')

      if @clas =~ /\b(Outdoor|Dark)?Room\b/
	@obj = nil
	@name = @name[1] || @name[0] || @tag
	debug "+++ ROOM #@name TAG: #@tag"
	@tag  = @name if not @tag
	@desc = ''
	new_room
	@room.light = false if $1 == 'Dark'
	@in_desc = 1
      elsif @clas =~ /\bFakeConnector\b/
	@functions << @tag
      elsif @clas =~ /\bRoomConnector\b/
	debug "+++ CONNECTOR TAG: #@tag"
	@desc = ''
	new_door(loc)
	@obj.connector = true
      elsif @clas =~ /\b(?:(?:Hidden|Secret)?Door|ThroughPassage|PathPassage|TravelWithMessage|Stairway(?:Up|Down))\b/
	@desc = ''
	@name = @name[0] || @name[1]
	@tag  = @name if not @tag
	debug "+++ DOOR #@tag"
	if @clas =~ /\s+->\s*(\w+)/
	  # this is the other side of the door... find matching side
	  @obj = @tags[$1]
	  if not @obj
	    new_door(loc)
	    @tags[$1] = @obj
	  else
	    @tags[@tag] = @obj
	    @obj.location << loc if loc
	  end
	else
	  new_door(loc) if @tag
	  @obj.locked = true if @clas =~ /\bLockable(WithKey)?\b/
	end
	@obj.connector = true if @clas !~ /\b(?:Hidden|Secret)?Door\b/
      elsif @clas =~ /\b(?:Thing|Food|Person)\b/
	@obj = nil
	@desc = ''
	@name = @name[0] || @name[1]
	@name = '' if @name =~ /\//
	@tag  = @name if not @tag
	new_obj(loc) if @tag
      elsif @clas =~ /\bEnterable\b/ and @tag
	@desc = ''
	@name = @name[0] || @name[1]
	@name = '' if @name =~ /\//
	@tag  = @name if not @tag
	new_obj(loc)
	if @clas =~ /\s+->\s*(\w+)/
	  @obj.enterable << $1
	end
      else
	if @tag
	  @obj = nil
	end
	@name = (@name[0] || @name[1] || @tag)
      end

#       debug <<"EOF"
# Name: #@name
# 	Classes : #@clas
# 	Tag     : #@tag
# 	Location: #{loc}  #{loc.class}
# EOF


    end

    if @obj
      if @obj.name == '' and @line =~ /^\s*#{NOMS}#{NAME}\s*$/
	name = $2 || $1
	@obj.name = name
      end
      @obj.name = $1 || $2 if @line =~ OBJNAME
      if @line =~ OBJLOCATION
	loc = $1 || $2 || $3
	if loc
	  locs = loc.split(/\s*,\s*/)
	  @obj.location += locs
	  @obj.location.uniq!
	end
      end
      @obj.location << loc if @obj.connector and @line =~ CONNECTOR
    end

    if @room and @line =~ ROOMNAME
      @room.name = $1
      return
    end

    if @line =~ DESCRIPTION
      @desc << $1 if @desc and $1
      @in_desc = 2 if $2 == ''
    end

    # dirs = @line.scan(DIR_TO) + @line.scan(DIR) + @line.scan(DIR_MSG)
    if @room
      dirs = ( @line.scan(DIR) + @line.scan(DIR_MSG) + 
	       @line.scan(DIR_OPEN) + @line.scan(DIR_INSELF) +
	      @line.scan(ENTER_DIR) )
      if dirs.size > 0
	dirs.each { |d, room|
	  next if not room or room == 'nil' or room =~ /^noTravel/
	  dir = DIRECTIONS[d]
	  @room.exits[dir] = room
	}
      end
    end

  end




  def parse_makefile(file)
    dir = File.dirname(file)
    files = []
    File.foreach(file) { |line|
      if line =~ /-source\s*([^\s]+)/
	f = $1
	if f !~ /^(?:[A-Z]:|\/)/
	  f = dir + '/' + f
	end
	files << "#{f}.t"
      end
    }
    
    return files
  end

  def set_include_dirs
    # Try to find t3make(.exe) in path.
    paths = ENV['PATH'].split(SEP)
    paths.each { |p|
      next if not File.directory?(p)
      Dir.foreach(p) { |x|
 	if x =~ /^t3make(.exe)?$/i
	  @include_dirs << p
	  @include_dirs << p + "/include"
	  @include_dirs << p + "/lib"
	  @include_dirs << p + "/contrib"
	  break
	end
      }
    }
  end

  def read_file(file)
    if file =~ /.t3m/
      files = parse_makefile(file)
    else
      files = file
    end

    files.each_with_index { |file, idx|
      super(file)
    }
  end

  def initialize(file, map = Map.new('TADS Map'))
    debug "Initialize"
    @classes = { 'Object' => {} }
    super
  end
end


if $0 == __FILE__
  p "Opening file '#{ARGV[0]}'"
  BEGIN { 
    $LOAD_PATH << 'C:\Windows\Escritorio\IFMapper\lib'
  }

  require "IFMapper/Map"
  TADSReader.new(ARGV[0])
end
