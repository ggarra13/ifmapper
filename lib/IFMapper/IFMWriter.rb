


class IFMWriter
  
  EXIT_TEXT = [
               '',
               'up',
               'down',
               'in',
               'out'
              ]



  def link(c)
    return if @links.include?(c) # already spit out
    return if c.stub?
    a = c.roomA
    return if not a
    b = c.roomB
    roomA = @elem[a]
    roomB = @elem[b]
    @f.puts
    @f.print "link #{roomA} to #{roomB}"
    directions(c, a, b)
    @f.print ";\n"
  end

  def directions(c, a, b)
    return if c.stub?

    @links << c
    if c.gpts.empty?
      # self connection
      if a == b
        idx = c.dirs[0]
      else
        # simple connection
        idx = a.next_to?(b)
      end
      if idx != nil
	dir = ' ' + Room::DIRECTIONS_ENGLISH[idx]
      end
    else
      # complex path
      dir = ''
      pts = c.gpts.dup
      x = a.x
      y = a.y
      if c.roomA != a
	pts.reverse!
      end
      
      pts.each { |p|
	dx, dy = [ p[0] - x, p[1] - y ]
	idx = Room::vector_to_dir(dx, dy)
	dir += " #{Room::DIRECTIONS_ENGLISH[idx]}"
	x = p[0]
	y = p[1]
      }
      dx, dy = [ b.x - x, b.y - y ]
      idx = Room::vector_to_dir(dx, dy)
      dir += " #{Room::DIRECTIONS_ENGLISH[idx]}"
    end
    @f.print " dir#{dir}"

  end

  def get_tag(e, t)
    return @elem[e] if @elem.has_key?(e)

    tag = t.dup

    version = RUBY_VERSION.split('.').map { |x| x.to_i }
    if (version <=> [1,9,0]) < 0
      utf = Iconv.new( 'iso-8859-1', 'utf-8' )
      tag = utf.iconv( tag )
    else
      tag = tag.encode( 'utf-8', :invalid => :replace, 
                        :undef => :replace, :replace => '' )
    end

    tag.gsub!(/[\-\(\s,\.!'&"\#$@\/\\\-\)]+/, '_')
    tag.gsub!(/__/, '')                  # remove reduntant __ repetitions
    tag.sub!(/^([\d]+)_?(.*)/, '\2\1')   # No numbers allowed at start of tag
    tagname = tag
    idx = 2
    while @tags.include?(tagname) or tagname.empty? or tagname.size == 1
      tagname = tag + '_' + idx.to_s
      idx += 1
    end
    @tags    << tagname
    @elem[e] = tagname
    return tagname
  end

  # hook up two rooms that are not linked
  def nolink(a, b)
    x = a.x
    y = a.y
    # find free room exit in a
    exit = 0
    a.exits.each_with_index { |e, idx|
      next if e
      exit = idx
      break
    }
    dir = Room::DIRECTIONS_ENGLISH[exit]
    dx, dy = Room::DIR_TO_VECTOR[exit]
    x += dx
    y += dy
    while x != b.x or y != b.y
      dx = dy = 0
      if b.x > x
	dx = 1
      elsif b.x < x
	dx = -1
      end
      if b.y > y
	dy = 1
      elsif b.y < y
	dy = -1
      end
      idx  = Room::vector_to_dir(dx, dy)
      dir += " #{Room::DIRECTIONS[idx]}"
      x += dx
      y += dy
    end

    @f.print " dir #{dir} nolink"
  end

  def room(r)
    return if @rooms.include?(r) or r == nil
    @rooms << r
    tag = get_tag(r, r.name)

    @f.puts 
    @f.print "room \"#{r.name}\" tag #{tag}"
    if not @link.empty?
      if @link[3]
	nolink(@last_room, r)
      else
	directions(@link[0], @link[1], @link[2])
	if @last_room and @link[1] != @last_room
	  tag = get_tag(@link[1], @link[1].name)
	  @f.print " from #{tag}"
	end
        if @link[0].exitAtext != 0
          dir = EXIT_TEXT[@link[0].exitAtext]
          @f.print " go #{dir}"
        end

        if @link[0].dir == Connection::AtoB
          @f.print " oneway"
        end

        if @link[0].type == Connection::SPECIAL
          @f.print " style special"
        end

      end
    end
    @f.print ";\n"
    @last_room = r

    objs = r.objects.split("\n")
    objs.each { |obj|
      tag = get_tag(obj, obj)      
      @f.puts "\titem \"#{obj}\" tag #{tag};"
    }
    tasks = r.tasks.split("\n")
    tasks.each { |task|
      tag = get_tag(task, task)
      @f.puts "\ttask \"#{task}\" tag #{tag};"
    }

    r.exits.each { |c|
      next if not c or @links.include?(c)
      if c.roomA == c.roomB
	# self-link
	link(c)
	next
      end
      if r == c.roomA
	@link = [c, c.roomA, c.roomB]
	room(c.roomB) # Recurse along this branch...
      else
	@link = [c, c.roomB, c.roomA]
	room(c.roomA) # Recurse along this branch...
      end
    }
  end

  def sections
    old_section = @map.section
    @map.sections.each_with_index { |section, idx|
      @f.puts
      @f.puts '#' * 79
      @f.puts
      if section.name.to_s == ''
	if @map.sections.size > 1
	  @f.puts "map \"Section #{idx+1}\";"
	end
      else
	@f.puts "map \"#{section.name}\";"
      end
      @map.section = idx
      @link = []
      section.rooms.each { |r|
	room(r)
	@link << 'nolink'
      }
      section.connections.each { |c|
	link(c)
      }
    }
    @map.section = old_section
  end

  def header
    @f.puts <<-"HEADER"
#
# IFM map for #{@map.name}
# Created by #{@map.creator}
# #{Time.now}
#
# Map created using the Interactive Fiction Mapper
# (C) 2005 - Gonzalo Garramuno
#

HEADER

    if @map.name.to_s != ''
      @f.puts "title \"#{@map.name}\";\n"
    end

  end


  def export(file)
    @f = File.open(file, 'w')
    header
    sections
    @f.close
  end

  def initialize(map, file)
    @link  = nil
    @links = []
    @rooms = []
    @last_room = nil
    @tags  = []
    @elem  = {}
    @map   = map
    export(file)
  end
end
