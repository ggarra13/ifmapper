
require 'date'

class TADSWriter



  DIRECTIONS = [
    'north',
    'northeast',
    'east',
    'southeast',
    'south',
    'southwest',
    'west',
    'northwest',
  ]

  OTHERDIRS = [
    '',
    'up',
    'down',
    'in',
    'out',
  ]


  def get_door_tag(e, r = nil)
    dirA  = e.roomA.exits.index(e)
    dirB  = e.roomB.exits.rindex(e)
    name  = Room::DIRECTIONS[dirA] + "_" + Room::DIRECTIONS[dirB]
    name << "_door"
    tag = get_tag(e, name)
    tag += 'B' if r and r == e.roomB and e.dir == Connection::BOTH
    return tag
  end

  def new_tag(elem, str)
    tag = str.dup

    # Take text from Unicode utf-8 to iso-8859-1
    if RUBY_VERSION.to_f < 1.9
      utf = Iconv.new( 'iso-8859-1', 'utf-8' )
      tag = utf.iconv( tag )
    else
      tag = tag.encode( 'utf-8', :invalid => :replace,
                        :undef => :replace, :replace => '' )
    end

    # Invalid tag characters, replaced with _
    tag.gsub!(/[\s"'\/\\\-&#\,.:;!\?\n\(\)]/,'_')

    tag.gsub!(/__/, '')                  # remove reduntant __ repetitions
    tag.sub!(/^([\d]+)_?(.*)/, '\2\1')   # No numbers allowed at start of tag
   # tag.downcase!                        # All tags are lowercase



    tag = tag[0..31]                     # Max. 32 chars. in tag

    # tag cannot be keyword (Doorway, Room, Class, etc)
    if tag =~ @keyword
      tag << '1'
    end

    if @tags.values.include?(tag)
      idx  = 2
      root = tag[0..29]  # to leave room for number
      while @tags.values.include?(tag)
	tag = "#{root}#{idx}"
	idx += 1
      end
    end

    if elem.kind_of?(String)
      @tags[tag] = tag
    else
      @tags[elem] = tag
    end

    return tag
  end



  def get_tag(elem, name = elem.name)
    return @tags[elem] if @tags[elem]
    return new_tag(elem, name)
  end



  def wrap_text(text, width = 74, indent = 79 - width)
    return 'UNDER CONSTRUCTION' if not text or text == ''
    str = TADSWriter::quote( text.dup )

    if text.size > width
      r   = ''
      while str
	if str.size >= width
	  idx = str.rindex(/[ -]/, width)
	  idx = str.size unless idx
	else
	  idx = str.size
	end
	r << str[0..idx]
	str = str[idx+1..-1]
	r << "\n" << ' ' * indent if str
      end
      return r
    else
      return str
    end
  end


  #
  # Take a text and quote it for TADS's double/single-quote text areas.
  #
  def self.quote(text)
    str = text.dup

    # Take text from Unicode utf-8 to iso-8859-1
    if RUBY_VERSION.to_f < 1.9
      utf = Iconv.new( 'iso-8859-1', 'utf-8' )
      str = utf.iconv( str )
    else
      str = str.encode( 'utf-8', :invalid => :replace,
                        :undef => :replace, :replace => '' )
    end

    # Quote special characters
    str.gsub!(/"/, '\"')
    str.gsub!(/'/, "\\\\'")
    return str
  end


  def objects(r)
    room = get_tag(r)
    objs = r.objects.split("\n")
    objs.each { |o|

      tag = new_tag(o, o)
      name = TADSWriter::quote(o)

      classname = 'Thing'

      # If name begins with uppercase, assume it is an NPC
      if name =~ /[A-Z]/
	classname = 'Person'
      end

      @f.print <<"EOF"

#{tag} : #{classname} '#{name}' '#{name}'
      @#{room}
      "#{name} is UNDER CONSTRUCTION."
;
EOF
    }


  end



  def door(e)
    tag = get_door_tag(e)

    b = nil
    destination = ''
    if e.dir == Connection::BOTH
      a = e.roomA
      t = e.exitAtext
      b = e.roomB
    elsif e.dir == Connection::AtoB
      a = e.roomA
      destination = "\n    destination = #{get_tag(e.roomB)}"
      t = e.exitAtext
    elsif e.dir == Connection::BtoA
      a = e.roomB
      destination = "\n    destination = #{get_tag(e.roomA)}"
      t = e.exitBtext
    end

    roomA = get_tag(a)

    dirA  = a.exits.index(e)
    if t > 0
      dirA = dirAern = ''
    else
      d       = DIRECTIONS[dirA]
      dirA    = "#{d} "
      dirAern = "#{d}ern "
    end

    prop = ''
    if e.type == Connection::LOCKED_DOOR
      prop = 'LockableWithKey, '
    elsif e.type == Connection::CLOSED_DOOR
    end


    @f.puts <<"EOF"

// Door connecting #{e}
#{tag} : #{prop}Door '#{dirA}#{dirAern}door' '#{dirAern}door'
    location = #{roomA}#{destination}
;
EOF

    if b
      roomB = get_tag(b)
      dirB  = b.exits.rindex(e)
      if e.exitBtext > 0
	dirB = dirBern = ''
      else
	d       = DIRECTIONS[dirB]
	dirB    = "#{d} "
	dirBern = "#{d}ern "
      end

      @f.puts <<"EOF"

#{tag}B : #{prop}Door -> #{tag} '#{dirB}#{dirBern}door' '#{dirBern}door'
    location = #{roomB}
;

EOF
    end

  end


  def room(r)
    tag = get_tag(r)
    name = TADSWriter::quote(r.name)
    dark = r.darkness ? "Dark" : ""
    @f.puts <<-"EOF"

//-------------------- #{r.name}
#{tag} : #{dark}Room '#{name}'
    \"#{wrap_text(r.desc)}\"
EOF

    # Now, handle exits...
    r.exits.each_with_index { |e, dir|
      next if (not e) or e.stub? or e.type == Connection::SPECIAL
      if e.loop?
        text = e.exitAtext
        b    = e.roomB
      else
        if e.roomB == r
          next if e.dir == Connection::AtoB
          text = e.exitBtext
          a    = e.roomB
          b    = e.roomA
        else
          next if e.dir == Connection::BtoA
          text = e.exitAtext
          a    = e.roomA
          b    = e.roomB
        end
      end
      @f.print '    '
      if text == 0
	@f.print "#{DIRECTIONS[dir]} = "
      else
	@f.print "#{OTHERDIRS[text]} = "
      end
      if e.type == Connection::CLOSED_DOOR or
	  e.type == Connection::LOCKED_DOOR
	@f.puts get_door_tag(e, r )
      else
	@f.puts get_tag(b)
      end
    }
    @f.puts ";"

    objects(r)
  end



  def section(sect, idx)
    @f = File.open("#@root-#{idx}.t", "w")
    @f.puts '//' + '=' * 78
    @f.puts "// Section: #{sect.name} "
    @f.puts '//' + '=' * 78
    sect.rooms.each { |r|
      room(r)
    }

    @f.puts
    @f.puts '//' + '-' * 78
    @f.puts '//  Doorways'
    @f.puts '//' + '-' * 78
    sect.connections.each { |e|
      next if (e.type != Connection::LOCKED_DOOR and
	       e.type != Connection::CLOSED_DOOR)
      door(e)
    }
    @f.close
  end



  def start
    @f = File.open("#@root.t", "w")
    @f.puts '#charset "us-ascii"'
    @f.puts
    @f.puts '//' + '=' * 78

    story = TADSWriter::quote(@map.name)
    story = 'Untitled' if story == ''
    today = Date.today

    start_location = ''
    if @map.sections.size > 0 and @map.sections[0].rooms[0]
      r   = @map.sections[0].rooms[0]
      tag = get_tag(r)
      start_location = "location = #{tag}"
    end

    @f.puts <<"EOF"

#include <adv3.h>
#include <en_us.h>

versionInfo: GameID
    name = '#{story}'
    byline = '#{@map.creator}'
    version = '1.0'
    release = '#{today}'
;

me: Actor
    #{start_location}
;

gameMain: GameMainDef
    initialPlayerChar = me
;

EOF
    @f.puts '//' + '=' * 78
    @f.puts "// Object classes"

    @f.puts '//' + '=' * 78
    @f.puts "// Map sections"
    @map.sections.each_index { |idx|
      @f.puts "#include \"#@base-#{idx}.t\""
    }
    @f.close

    @map.sections.each_with_index { |sect, idx|
      section(sect, idx)
    }
  end


  def initialize(map, fileroot)
    @tags = {}
    @root = fileroot
    @base = File.basename(@root)
    @map = map

    keywords = [
      'Door',
      'class',
      'include',
      'DarkRoom',
      'Room',
      'Thing',
      'case',
      'match',
      'Platform',
    ] + DIRECTIONS

    @keyword = /^(?:#{keywords.join('|')})$/i
    start
  end


end
