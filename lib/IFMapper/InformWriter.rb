
require 'date'

class InformWriter



  DIRECTIONS = [
    'n_to',
    'ne_to',
    'e_to',
    'se_to',
    's_to',
    'sw_to',
    'w_to',
    'nw_to',
  ]

  OTHERDIRS = [
    '',
    'u_to',
    'd_to',
    'in_to',
    'out_to',
  ]


  def get_door_tag(e)
    dirA  = e.roomA.exits.index(e)
    dirB  = e.roomB.exits.rindex(e)
    name  = Room::DIRECTIONS[dirA] + "_" + Room::DIRECTIONS[dirB]
    name << "_door"
    get_tag(e, name)
  end

  def new_tag(elem, str)
    tag = str.dup
    if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('1.9.0')
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
    tag.downcase!                        # All tags are lowercase



    tag = tag[0..31]                     # Max. 32 chars. in tag (inform limit)

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


  def wrap_text(text, width = 65, indent = 79 - width)
    return 'UNDER CONSTRUCTION' unless text
    str = inform_quote( text )

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
  # Take a text and quote it for inform's double-quote text areas.
  #
  def inform_quote(text)
    str = text.dup

    # Take text from Unicode utf-8 to iso-8859-1
    if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('1.9.0')
      utf = Iconv.new( 'iso-8859-1', 'utf-8' )
      str = utf.iconv( str )
    else
      str = str.encode( 'utf-8', :invalid => :replace,
                        :undef => :replace, :replace => '' )
    end

    # Quote special characters
    str.gsub!(/@/, '@@64')
    str.gsub!(/"/, '@@34')
    str.gsub!(/~/, '@@126')
    str.gsub!(/\\/, '@@92')
    str.gsub!(/\^/, '@@94')
    return str
  end


  def objects(r)
    room = get_tag(r)
    objs = r.objects.split("\n")
    objs.each { |o|

      tag = new_tag(o, o)
      names = o.dup
      names.gsub!(/"/, '')      # remove any quotes
      names.gsub!(/'/, '^')     # change ' to ^ (inform convention)
      names.gsub!(/\b\w\b/, '') # remove single letter words
      names = names.split(' ')
      names = "'" + names.join("' '") + "'"

      name = inform_quote(o)

      classname = 'Object'

      # If name begins with uppercase, assume it is an NPC
      if name =~ /[A-Z]/
	classname = 'NPC'
      end

      @f.print <<"EOF"

#{classname} #{tag} "#{name}" #{room}
      with name #{names},
      description "#{name} is UNDER CONSTRUCTION.";
EOF
    }


  end

  def door(e)
    tag = get_door_tag(e)
    roomA = get_tag(e.roomA)
    roomB = get_tag(e.roomB)
    dirA  = e.roomA.exits.index(e)
    dirB  = e.roomB.exits.rindex(e)
    dirA  = Room::DIRECTIONS[dirA]
    dirB  = Room::DIRECTIONS[dirB]

    props = ''
    if e.type == Connection::LOCKED_DOOR
      props = "\n    has lockable locked"
    elsif e.type == Connection::CLOSED_DOOR
      props = "\n    has ~open"
    end

    if e.dir == Connection::BOTH
      found_in = "#{roomA} #{roomB}"
    elsif e.dir == Connection::AtoB
      found_in = roomA
    elsif e.dir == Connection::BtoA
      found_in = roomB
    end

    @f.puts <<"EOF"

! Door connecting #{e}
Doorway #{tag} "door"
    with name 'door',
    side1_to  #{roomA},
    side1_dir #{dirA}_to,
    side2_to  #{roomB},
    side2_dir #{dirB}_to,
    found_in  #{found_in}#{props};
EOF

  end


  def room(r)
    tag = get_tag(r)
    name = inform_quote(r.name)
    @f.puts <<-"EOF"

!-------------------- #{r.name}
Room #{tag} "#{name}"
EOF

    @f.puts  "    with description"
    @f.print "             \"#{wrap_text(r.desc)}\""

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
          b    = e.roomA
        else
          next if e.dir == Connection::BtoA
          text = e.exitAtext
          b    = e.roomB
        end
      end
      @f.puts  ','
      @f.print '    '
      if text == 0
	@f.print "#{DIRECTIONS[dir]} "
      else
	@f.print "#{OTHERDIRS[text]} "
      end
      if e.type == Connection::CLOSED_DOOR or
	  e.type == Connection::LOCKED_DOOR
	@f.print get_door_tag(e)
      else
	@f.print get_tag(b)
      end
    }
    if r.darkness
      @f.print "    has ~light"
    end
    @f.puts ";"

    objects(r)
  end

  def section(sect, idx)
    @f = File.open("#@root-#{idx}.inf", "w")
    @f.puts '!' + '=' * 78
    @f.puts "! Section: #{sect.name} "
    @f.puts '!' + '=' * 78
    sect.rooms.each { |r|
      room(r)
    }

    @f.puts '!' + '-' * 78
    @f.puts '!  Doorways'
    @f.puts '!' + '-' * 78
    sect.connections.each { |e|
      next if (e.type != Connection::LOCKED_DOOR and
	       e.type != Connection::CLOSED_DOOR)
      door(e)
    }
    @f.close
  end

  def start
    @f = File.open("#@root.inf", "w")
    @f.puts '!' + '=' * 78
    story = @map.name
    story = 'Untitled' if story == ''
    today = Date.today
    serial = today.strftime("%y%m%d")
    @f.puts <<"EOF"
Constant Story "#{story}";
Constant Headline
           "^A game map done with IFMapper
            ^by #{@map.creator}.^";
Release 1;
Serial "#{serial}"; ! #{Time.now}

! These constants are to make the game also potentially Glulx compatible
#ifndef WORDSIZE;
Constant TARGET_ZCODE;
Constant WORDSIZE 2;
#endif;

!Constant ZDEBUG;

Include "Parser";
Include "VerbLib";


EOF
    @f.puts '!' + '=' * 78
    @f.puts "! Object classes"
    @f.puts <<"EOF"

! We use Andrew MacKinnon's EasyDoors for our doors.
Include "easydoors";

! We define a class for NPC (non-player characters)
class   NPC
  has   animate;

EOF

    @f.puts '!' + '=' * 78
    @f.puts "! Map sections"
    @map.sections.each_index { |idx|
      @f.puts "#include \"#@base-#{idx}.inf\";"
    }

    start_location = ''
    if @map.sections.size > 0 and @map.sections[0].rooms[0]
      r   = @map.sections[0].rooms[0]
      tag = get_tag(r)
      start_location = "location = #{tag}"
    end

    @f.puts <<"EOF";
!============================================================================
! Entry point routines

[ Initialise;
  #{start_location};
  lookmode = 2; ! verbose
  inventory_style = FULLINV_BIT + ENGLISH_BIT + RECURSE_BIT; ! wide
];
EOF

    @f.puts <<"EOF"
!============================================================================
! Standard and extended grammar

Include "Grammar";
EOF

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
      'doorway',
      'class',
      'include',
      'room',
      'has',
      'with',
      'description',
    ] + DIRECTIONS

    @keyword = /^(?:#{keywords.join('|')})$/i
    start
  end
end
