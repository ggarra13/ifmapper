

class Inform7Writer


  DIRECTIONS = [
    'North',
    'Northeast',
    'East',
    'Southeast',
    'South',
    'Southwest',
    'West',
    'Northwest',
  ]

  OTHERDIRS = [
    '',
    'Above',
    'Below',
    'Inside',
    'Outside',
  ]

  IGNORE_WORDS = [
    'a', 'the', 'and', 'of', 'your', 'to', 'out', 'in'
  ]

  IGNORED_ARTICLES = /^(?:#{IGNORE_WORDS.join('|')})$/



  KEYWORDS = [
    'include',
    'has',
    'with',
    'is',
    'in',
    'container',
    'to',
    'and',
    'side',
    '\s*,\s*',
    '\s*\(\s*',
  ] + DIRECTIONS + OTHERDIRS[1..-1]

  INVALID_KEYWORD = /\b(?:#{KEYWORDS.join('|')})\b/i


  LOCATION_NAMES = [
    'door',
    'include',
    'room',
    'has',
    'with',
    'is',
    'container',
  ] + DIRECTIONS
  INVALID_LOCATION_NAME = /^(?:#{LOCATION_NAMES.join('|')})$/i


  #
  # Some common animals in adventure games
  #
  ANIMALS = [
    'horse',
    'donkey',
    'mule',
    'goat',
    # lizards
    'lizard',
    'snake',
    'turtle',
    # fishes
    'fish',
    'dolphin',
    'whale',
    'tortoise',
    # dogs
    'dog',
    'wolf',
    # cats
    'cat',
    'leopard',
    'tiger',
    'lion',
    # fantastic
    'grue',
    # birds
    'bird',
    'pigeon',
    'peacock',
    'eagle',
  ]

  IS_ANIMAL = /\b(?:#{ANIMALS.join('|')})\b/i

  MALE_PEOPLE = [
    'boy',
    'man',
    'sir',
  ]
  IS_MALE_PERSON = /\b(?:#{MALE_PEOPLE.join('|')})\b/i

  FEMALE_PEOPLE = [
    'girl',
    'woman',
    'lady',
    'actress',
  ]
  IS_FEMALE_PERSON = /\b(?:#{FEMALE_PEOPLE.join('|')})\b/i

  PEOPLE = MALE_PEOPLE + FEMALE_PEOPLE + [
    'child',
    'attendant',
    'doctor',
    'actor',
    'character',
    'engineer',
    'bum',
    'nerd',
    'ghost',
  ]

  IS_PERSON = /\b(?:#{PEOPLE.join('|')})\b/i

  #
  # Some common container types
  #
  CONTAINERS = [
    'box',
    'cup',
    'crate',
    'tin',
    'can',
    'chest',
    'wardrobe',
    'jacket',
    'suit',
    'trophy case',
    'coffin',
    'briefcase',
    'suitcase',
    'bag',
    'flask',
  ]
  IS_CONTAINER = /\b(?:#{CONTAINERS.join('|')})\b/i

  #
  # Some common lit types
  #
  UNLIT_TYPES = [
    'lantern',
    'torch',
  ]
  IS_LIGHT = /\b(?:#{UNLIT_TYPES.join('|')})\b/i

  #
  # Some common wearable types
  #
  CLOTHES = [
    'cape',
    'glove',
    'jeans',
    'trousers',
    'hat',
    'gown',
    'backpack',
    'shirt',
    'jacket',
    'suit',
    'ring',
    'bracelet',
    'amulet',
    'locket',
  ]
  IS_WEARABLE = /\b(?:#{CLOTHES.join('|')})\b/i

  #
  # Some common supporter types
  #
  SUPPORTERS = [
    'table',
    'shelf',
  ]
  IS_SUPPORTER = /\b(?:#{SUPPORTERS.join('|')})\b/i

  #
  # Some common edible types
  #
  FOOD = [
    'bread',
    'cake',
    # drinks
    'water',
    'soda',
    'beer',
    'beverage',
    'potion',
    # fruits
    'fruit',
    'apple',
    'orange',
    'banana',
    'almond',
    'nut',
  ]
  IS_EDIBLE = /\b(?:#{FOOD.join('|')})\b/i

  def new_tag(elem, str)
    tag = str.dup

    # Take text from Unicode utf-8 to iso-8859-1
    if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('1.9.0')
      utf = Iconv.new( 'iso-8859-1', 'utf-8' )
      tag = utf.iconv( tag )
    else
      tag = tag.encode( 'utf-8', :invalid => :replace, 
                        :undef => :replace, :replace => '' )
    end

    # Remove redundant spaces
    tag.sub!(/^\s/, '')
    tag.sub!(/\s$/, '')

    # Invalid tag characters, replaced with _
    tag.gsub!(/[\s"\\\#\&,\.:;!\?\n\(\)]+/,'_')
    tag.sub!(/^([\d]+)_?(.*)/, '\2\1')   # No numbers allowed at start of tag

    tag.gsub!(/__/, '_')

    # tag cannot be repeated and cannot be keyword (Doorway, Room, etc)
    # In those cases, we add a number to the tag name.
    idx = 0
    if @tags.values.include?(tag) or tag =~ INVALID_LOCATION_NAME
      idx = 1
    end



    if idx > 0
      root = tag.dup
      tag = "#{root}#{idx}"
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

  def get_tag(elem, name)
    return @tags[elem] if @tags[elem]
    tag = name
    if tag =~ INVALID_KEYWORD or @tags.values.include?(tag)
      return new_tag(elem, name)
    else
      @tags[elem] = tag
    end
    return tag
  end

  def get_room_tag(elem)
    return @tags[elem] if @tags[elem]
    tag = elem.name
    if tag =~ INVALID_KEYWORD or @tags.values.include?(tag)
      tag = new_tag(elem, elem.name)
    else
      @tags[elem] = tag
    end
    return tag
  end

  def get_door_name(e)
    dirA  = e.roomA.exits.index(e)
    dirB  = e.roomB.exits.rindex(e)
    name  = DIRECTIONS[dirA].downcase + "-" + DIRECTIONS[dirB].downcase
    name << " door"
  end

  def get_door_tag(e)
    name = get_door_name(e)
    name.upcase
    get_tag(e, name)
  end

  def wrap_text(text, width = 75, indent = 78 - width)
    return 'UNDER CONSTRUCTION.' if not text or text == ''
    str = inform_quote( text )

    if str.size > width
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

    # Take text from Unicode utf-8 to iso-8859-1859-1
    if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('1.9.0')
      utf = Iconv.new( 'iso-8859-1', 'utf-8' )
      str = utf.iconv( str )
    else
      str = str.encode( 'utf-8', :invalid => :replace, 
                        :undef => :replace, :replace => '' )
    end

    # Quote special characters
#     str.gsub!(/@/, '@@64')
    str.gsub!(/"/, '\'')
#     str.gsub!(/~/, '@@126')
#     str.gsub!(/\\/, '@@92')
#     str.gsub!(/\^/, '@@94')
    return str
  end


  def objects(r)
    room = get_room_tag(r)
    objs = r.objects.split("\n")
    objs.each { |o|

      tag = get_tag(o, o)

      names = o.dup
      names.gsub!(/"/, '')      # remove any quotes
      names.gsub!(/\b\w\b/, '') # remove single letter words

      name  = names
      names = name.split(' ')

      article = 'a '
      if name =~ /ves$/ or name =~ /s$/
	article = 'some '
      elsif name =~ /^[aeiou]/
	article = 'an '
      end


      # If name begins with uppercase, assume it is an NPC
      type = 'a thing'

      if name =~ IS_ANIMAL
	type = 'an animal'
      elsif name =~ IS_PERSON
	article = 'a '
	type = 'a person'
	if name =~ IS_MALE_PERSON
	  type = 'a male person'
	elsif name =~ IS_FEMALE_PERSON
	  type = 'a female person'
	end
      elsif name =~ /[A-Z]/
	if name !~ /'/  # possesive, like Michael's wallet
	  # if too many words, probably a book's title
	  if names.size <= 3
	    article = ''
	    if name =~ /^(?:Miss|Mrs)/
	      type = 'a woman'
	    else
	      type = 'a person'
	    end
	  end
	end
      end


      props = ''

      if tag != name
	props << "\n   The printed name of #{tag} is \"#{article}#{name}\"."
      else
	tag = article + tag
      end

      if name =~ IS_LIGHT
	props << "\n   It is not lit."
      end

      if name =~ IS_CONTAINER
	props << "\n   It is a container."
      end

      if name =~ IS_SUPPORTER
	props << "\n   It is a supporter."
      end

      if name =~ IS_WEARABLE
	props << "\n   It is wearable."
      end

      if name =~ IS_EDIBLE
	props << "\n   It is edible."
      end

      @f.print <<"EOF"

In #{room}, there is #{type} called #{tag}. #{props}
   The description of #{tag} is \"UNDER CONSTRUCTION.\"
EOF
      if names.size > 1
	names.each { |n|
          next if n =~ IGNORED_ARTICLES
	  @f.puts "   Understand \"#{n}\" as #{tag}."
	}
      end
    }


  end

  def door(e)
    name  = get_door_name(e)
    tag   = get_tag(e, name)
    roomA = get_room_tag(e.roomA)
    roomB = get_room_tag(e.roomB)
    dirA  = e.roomA.exits.index(e)
    dirB  = e.roomB.exits.rindex(e)
    dirA  = DIRECTIONS[dirA].downcase
    dirB  = DIRECTIONS[dirB].downcase

    props = ''
    if e.type == Connection::LOCKED_DOOR
      props = "It is locked."
    elsif e.type == Connection::CLOSED_DOOR
      props = "It is closed."
    end

    found_in = 'It is '
    if e.dir == Connection::BOTH
      found_in << "#{dirA} of #{roomA} and #{dirB} of #{roomB}"
    elsif e.dir == Connection::AtoB
      found_in << "#{dirA} of #{roomA}.  Through it is #{roomB}"
    elsif e.dir == Connection::BtoA
      found_in << "#{dirB} of #{roomB}.  Through it is #{roomA}"
    end

    @f.puts <<"EOF"

The #{tag} is a door. #{props}  
The printed name of #{tag} is "a #{name}".
Understand "#{name}" as #{tag}.
Understand "door" as #{tag}.
#{found_in}.
EOF

  end


  def room(r)
     tag = get_room_tag(r)
    name = r.name

    prop = ''
    if r.darkness
      prop << 'dark '
    end

    @f.print "\n#{tag} is a #{prop}room."

    if name != tag
      name = inform_quote(name)
      @f.print "  The printed name of #{tag} is \"#{name}\"."
    end

    @f.puts
    @f.puts "  \"#{wrap_text(r.desc)}\""

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
      @f.print '  '
      if text == 0
        @f.print "#{DIRECTIONS[dir]} is "
      else
        @f.print "#{OTHERDIRS[text]} is "
      end

      if e.type == Connection::CLOSED_DOOR or
          e.type == Connection::LOCKED_DOOR
	@f.print get_door_tag(e)
      else
	@f.print get_room_tag(b)
      end
      @f.puts  '.'
    }
    objects(r)
  end

  def section(sect, idx)
    name = sect.name
    name = 'Unnamed' if name.to_s == ''

    @f.puts
    @f.puts "Section #{idx+1} - #{name}"
    @f.puts

    @f.puts
    @f.puts "Part 1 - Room Descriptions"
    @f.puts
    sect.rooms.each { |r| room(r) }
    @f.puts
    @f.puts

    @f.puts
    @f.puts "Part 2 - Doors"
    @f.puts
    sect.connections.each { |e|
      next if (e.type != Connection::LOCKED_DOOR and
	       e.type != Connection::CLOSED_DOOR)
      door(e)
    }
  end

  def start
    @f = File.open("#@root.inform", "w")
    story = @map.name
    story = 'Untitled' if story == ''
    today = Date.today
    serial = today.strftime("%y%m%d")

    @f.puts 
    @f.puts "\"#{story}\" by \"#{@map.creator}\""
    @f.puts
    @f.puts <<"EOF"
The story genre is "Unknown".  The release number is 1.
The story headline is "An Interactive Fiction".
The story description is "".
The story creation year is #{today.year}.


Use full-length room descriptions. 

EOF

    @map.sections.each_with_index { |sect, idx|
      section(sect, idx)
    }
    @f.close
  end

  def initialize(map, fileroot)
    @tags = {}
    @root = fileroot
    @base = File.basename(@root)
    @map = map

    start
  end
end
