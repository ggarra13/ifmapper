
#
# Class used to represent a Room or Location in a Map.
#
class Room
  attr_accessor  :name      # Name of room
  attr_accessor  :objects   # Objects found in room
  attr_accessor  :tasks     # Tasks that need to be performed in room
  attr_reader    :exits     # An array of 8 possible exits in room
  attr_accessor  :darkness  # Isxxxxxxxxxx room in darkness?
  attr_accessor  :x, :y     # Room location in grid
  attr_accessor  :desc      # Room description
  attr_accessor  :comment   # Room comment

  DIR_TO_VECTOR = { 
    0 => [  0, -1 ],
    1 => [  1, -1 ],
    2 => [  1,  0 ],
    3 => [  1,  1 ],
    4 => [  0,  1 ],
    5 => [ -1,  1 ],
    6 => [ -1,  0 ],
    7 => [ -1, -1 ]
  }

  def marshal_load(vars)
    @name     = vars.shift
    @objects  = vars.shift
    @tasks    = vars.shift
    @exits    = vars.shift
    @darkness = vars.shift
    @x        = vars.shift
    @y        = vars.shift
    @desc     = nil
    @comment  = nil
    if not vars.empty? and vars[0].kind_of?(String)
      @desc     = vars.shift
      @desc.gsub!(/(\w)\s*\n/, '\1 ')
      @desc.sub!(/\n+$/, '')
      @desc.strip!
    end
    if not vars.empty? and vars[0].kind_of?(String)
      @comment = vars.shift
    end
  end

  def marshal_dump
    [ @name, @objects, @tasks, @exits, @darkness, @x, @y, @desc, @comment ]
  end

  def [](dir)
    return @exits[dir]
  end

  def []=(dir, connection)
    @exits[dir] = connection
  end

  #
  # Return the number of doors present in room
  #
  def num_doors
    num = 0
    @exits.each { |e|
      next if not e
      num += 1 if e.door?
    }
    return num
  end

  #
  # Return the number of exits present in room
  #
  def num_exits
    return @exits.nitems
  end

  #
  # Return a direction from the vector of the exit that would take
  # us to the 'b' room more cleanly.
  #
  def self.vector_to_dir(dx, dy)
    if dx == 0
      return 4 if dy > 0
      return 0 if dy < 0
      raise "vector_to_dir: dx == 0 and dy == 0"
    elsif dx > 0
      return 1 if dy < 0
      return 2 if dy == 0
      return 3
    else
      return 7 if dy < 0
      return 6 if dy == 0
      return 5
    end
  end

  def vector_to_dir(dx, dy)
    return Room::vector_to_dir( dx, dy )
  end

  #
  # Given an 'adjacent' room, return the most direct exit from this
  # room to room b.
  #
  def exit_to(b)
    dx = (b.x - @x)
    dy = (b.y - @y)
    return vector_to_dir(dx, dy)
  end
  
  # Check if two rooms are next to each other.  If so,
  # return the exit that would take us from this room to the other.
  # Otherwise, return nil
  def next_to?(b)
    if not b.kind_of?(Room)
      raise "next_to?(b): #{b} is not a room."
    end
    if self == b
      raise "next_to? comparing same room #{self}"
    end
    if b.x == @x and b.y == @y
      raise "#{self} and #{b} in same location."
    end
    dx = (b.x - @x)
    dy = (b.y - @y)
    return nil if dx.abs > 1 or dy.abs > 1
    return vector_to_dir(dx, dy)
  end

  #
  # Copy a room to another
  #
  def copy(b)
    @name     = b.name
    @objects  = b.objects
    @tasks    = b.tasks
    @darkness = b.darkness
    @desc     = b.desc
  end


  def initialize(x, y, name = 'Room')
    @exits    = Array.new( DIRECTIONS.size )
    @darkness = false
    @name     = name
    @x = x
    @y = y

    @desc     = nil
    @objects  = ''
    @tasks = ''
    @comment = nil
  end

  def to_s
    "\"#{@name}\""
  end

  def inspect
    puts to_s
    puts "Exits:"
    @exits.each { |c|
      puts "\t#{c}" if c != nil
    }
  end
end
