
#
# Class used to represent a connection between one
# room and another
#
class Connection
  attr_accessor :type
  attr_reader   :dir
  attr_accessor :room
  attr_accessor :exitText

  # Type constants
  FREE        = 0
  LOCKED_DOOR = 1
  SPECIAL     = 2
  CLOSED_DOOR = 3

  # Direction constants
  BOTH = 0
  AtoB = 1
  BtoA = 2  # NO LONGER USED.

  # Text near connection (to indicate other dir)
  EXIT_TEXT = [
    '',
    'U',
    'D',
    'I',
    'O'
  ]

  def dir=(x)
    if x == BtoA
      @dir = AtoB
      flip
    else
      @dir = x
    end
  end

  def roomA=(x)
    @room[0] = x
  end

  def roomB=(x)
    @room[1] = x
  end

  def roomA
    return @room[0]
  end

  def roomB
    return @room[1]
  end

  def exitAtext=(x)
    @exitText[0] = x
  end

  def exitBtext=(x)
    @exitText[1] = x
  end

  def exitAtext
    return @exitText[0]
  end

  def exitBtext
    return @exitText[1]
  end

  def marshal_load(vars)
    if vars[2].kind_of?(Array)
      @type, @dir, @room, @exitText = vars
    else
      @type     = vars[0]
      @dir      = vars[1]
      @room     = [vars[2], vars[3]]
      @exitText = [vars[4], vars[5]]
      if @dir == BtoA
	@dir = AtoB
	flip
      end
    end
  end

  def marshal_dump
    [ @type, @dir, @room, @exitText ]
  end

  def initialize( roomA, roomB, dir = BOTH, type = FREE )
    @room     = []
    @room[0]  = roomA
    @room[1]  = roomB
    @dir      = dir
    @type     = type
    @exitText = [0, 0]
  end

  #
  # Given a room, return the opposite room in the connection.
  # If room passed is not present in connection, raise an exception.
  #
  def opposite(room)
    idx = self.index(room)
    raise "Room #{room} not part of connection #{c}" unless idx
    return @room[idx ^ 1]
  end

  #
  # Given a room, return the index of that room in the room[] array
  # If room is not present in connection, return nil.
  #
  def index(room)
    @room.each_with_index { |r, idx| return idx if r == room }
    return nil
  end

  #
  # Flip A and B rooms.  This is mainly used to make a oneway AtoB
  # connection become a BtoA connection.
  #
  def flip
    return unless @room[1]
    @room.reverse!
    @exitText.reverse!
  end

  #
  # Return the connected direction index for each room
  #
  def dirs
    dirA = @room[0].exits.index(self)
    if @room[1]
      dirB = @room[1].exits.rindex(self)
    else
      dirB = nil
    end
    return [dirA, dirB]
  end

  #
  # Return true if connection is a stub exit (ie. an exit leading nowhere)
  #
  def stub?
    return true unless @room[1]
    return false
  end

  #
  # Return true if connection is a self-looping connection
  #
  def loop?
    return false if @room[0] != @room[1]
    dirA, dirB = dirs
    return true if dirA == dirB
    return false
  end

  #
  # Return true if connection is a door
  #
  def door?
    return true if @type == CLOSED_DOOR or @type == LOCKED_DOOR
    return false
  end

  #
  # For debugging purposes, print ourselves nicely
  #
  def to_s
    dirA = dirB = ''
    a = @room[0]? @room[0].name : 'nil'
    b = @room[1]? @room[1].name : 'nil'
    if @exitText[0] > 0
      dirA = EXIT_TEXT[@exitText[0]]
    else
      if @room[0]
	idx  = @room[0].exits.index(self)
	dirA = Room::DIRECTIONS[idx] if idx
	dirA = dirA.upcase
      end
    end
    if @exitText[1] > 0
      dirB = EXIT_TEXT[@exitText[1]]
    else
      if @room[1]
	idx  = @room[1].exits.rindex(self)
	dirB = Room::DIRECTIONS[idx] if idx
	dirB = dirB.upcase
      end
    end
    if @dir == AtoB
      sym = '  --> '
    else
      sym = ' <-> '
    end
    "#{a} #{dirA}#{sym}#{b} #{dirB}"
  end
end

