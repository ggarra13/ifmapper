


class TrizbortWriter

  W = 128
  H = 64


  DIRECTIONS = [
    'n',
    'ne',
    'e',
    'se',
    's',
    'sw',
    'w',
    'nw',
  ]

  OTHERDIRS = [
    '',
    'Up',
    'Down',
    'In',
    'Out',
  ]

  def write_objects( room )
    if room.objects
      @f.print "\t\t\t<objects>"
      room.objects.split("\n").each_with_index { |obj,idx|
        if idx > 0
          @f.print "|"
        end
        @f.print "#{obj}"
      }
      @f.puts "</objects>"
    end
  end

  def to_xml desc
    desc = desc.dup
    desc.gsub!( /&/, '&amp;' )
    desc.gsub!( /\n/, "&#xD;&#xA;" )
    desc.gsub!( /"/, '&quot;' )
    desc.gsub!( /'/, '&apos;' )
    return desc
  end

  def write_map
    @f.puts "\t<map>"
    hash = {}
    x = 0
    id = 0
    @map.sections.each { |s|
      maxX = 0
      s.rooms.each { |r|
        name = to_xml( r.name )
        @f.print "\t\t<room id=\"#{id}\" name=\"#{r.name}\" x=\"#{x + r.x*(W+32)}\" y=\"#{r.y*(H+32)}\" w=\"#{W}\" h=\"#{H}\""
        if r.darkness
          @f.print " isDark=\"yes\""
        end
        if r.desc
          desc = to_xml( r.desc )
          @f.print " description=\"#{desc}\""
        end
        @f.puts ">"
        write_objects r
        @f.puts "\t\t</room>"
        hash[r] = id
        id += 1
        maxX = r.x if r.x > maxX
      }
      x += maxX * (W+32)
      s.connections.each { |c|
        @f.print "\t\t<line id=\"#{id}\""
        if c.type == Connection::SPECIAL
          @f.print " style=\"dashed\""
        end
        if c.dir == Connection::AtoB
          @f.print " flow=\"oneWay\""
        end
        if c.exitAtext.to_i > 0
          @f.print " startText=\"#{OTHERDIRS[c.exitAtext]}\""
        end
        if c.exitBtext.to_i > 0
          @f.print "   endText=\"#{OTHERDIRS[c.exitBtext]}\""
        end
        @f.puts ">"
        dirA, dirB = c.dirs
        id += 1
        @f.print "\t\t\t<dock index=\"0\" id=\"#{hash[c.roomA]}\" "
        portA = DIRECTIONS[dirA]
        @f.puts "port=\"#{portA}\" />"
        if c.roomB
          portB = DIRECTIONS[dirB]
          @f.print "\t\t\t<dock index=\"1\" id=\"#{hash[c.roomB]}\" "
          @f.puts "port=\"#{portB}\" />"
        end
        @f.puts "\t\t</line>"
      }
    }
    @f.puts "\t</map>"
  end
  
  def write_info
    @f.puts "\t<info>\n\t\t<title>#{@map.name}</title>"
    @f.puts "\t\t<author>#{@map.creator}</author>"
    @f.puts "\t</info>"
  end

  def write
    @f.puts '<?xml version="1.0" encoding="utf-8"?>'
    @f.puts '<trizbort>'
    write_info
    write_map
    @f.puts '</trizbort>'
    @f.close
  end

  def initialize(map, fileroot)
    @root = fileroot
    @base = File.basename(@root)
    @f = File.open "#{fileroot}.trizbort", 'w'
    @map = map
    write
  end
end
