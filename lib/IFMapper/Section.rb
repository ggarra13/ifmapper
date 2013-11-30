

require 'IFMapper/Connection'
require 'IFMapper/Room'

class Section
  attr_accessor :rooms
  attr_accessor :connections
  attr_accessor :name
  attr_accessor :comments

  class ConnectionError < StandardError; end

  def marshal_load(v)
    @rooms       = v[0]
    @connections = v[1]
    @name        = v[2]
    @comments    = v[3]
  end

  def marshal_dump
    return [ @rooms, @connections, @name, @comments ]
  end

  #
  # Return the number of rooms in width and height for this page
  #
  def rooms_width_height
    minXY, maxXY = min_max_rooms
    return [ 
      maxXY[0] - minXY[0] + 1,
      maxXY[1] - minXY[1] + 1
    ]
  end

  #
  # Return the min and max coordinates of all rooms in page
  #
  def min_max_rooms
    return [[0, 0],[0, 0]] if @rooms.empty?
    
    minXY = [ @rooms[0].x, @rooms[0].y ]
    maxXY = minXY.dup
    @rooms.each { |r|
      minXY[0] = r.x if r.x < minXY[0]
      minXY[1] = r.y if r.y < minXY[1]
      maxXY[0] = r.x if r.x > maxXY[0]
      maxXY[1] = r.y if r.y > maxXY[1]
    }
    return [ minXY, maxXY ]
  end

  #
  # Return true or false if map is free at location x,y
  #
  def free?(x,y)
    @rooms.each { |r|
      return false if r.x == x and r.y == y
    }
    return true
  end

  #
  # Shift rooms in dx and dy direction from x,y position on.
  #
  def shift(x, y, dx, dy)
    @rooms.each { |r|
      ox = oy = 0
      if (dx < 0 and r.x <= x) or
	  (dx > 0 and r.x >= x)
	ox = dx
      end
      if (dy < 0 and r.y <= y) or
	  (dy > 0 and r.y >= y)
	oy = dy
      end
      r.x += ox
      r.y += oy
    }
  end


  #
  # Delete a connection from section
  #
  def delete_connection(c)
    a = c.roomA
    if a
      e = a.exits.index(c)
      a[e] = nil if e
    end
    b = c.roomB
    if b
      e = b.exits.rindex(c)
      b[e] = nil if e
    end
    @connections.delete(c)
  end

  #
  # Delete a connection at a certain index location
  #
  def delete_connection_at( idx )
    c = @connections[idx]

    a = c.roomA
    if a
      e = a.exits.index(c)
      a[e] = nil if e
    end
    b = c.roomB
    if b
      e = b.exits.rindex(c)
      b[e] = nil if e
    end
    @connections.delete_at(idx)
  end

  #
  # Create a new connection among two rooms thru their exits
  #
  def new_connection( roomA, exitA, roomB, exitB = nil )

    # Verify rooms exist in section (ie. don't allow links across
    # sections)
    if not @rooms.include?(roomA)
      raise ConnectionError, "Room '#{roomA}' not in section #{self}"
    end
    if roomB and not @rooms.include?(roomB)
      raise ConnectionError, "Room '#{roomB}' not in section #{self}"
    end

    c = Connection.new( roomA, roomB )
    _new_connection( c, roomA, exitA, roomB, exitB )
  end

  #
  # Delete a room at a certain index
  #
  def delete_room_at(idx)
    r = @rooms[idx]
    r.exits.each { |e|
      next if not e
      delete_connection(e)
    }
    @rooms.delete_at(idx)
  end

  #
  # Delete a room, leaving its connections intact
  #
  def delete_room_only(r)
    @rooms.delete(r)
  end

  #
  # Delete a room and all of its connections
  #
  def delete_room(r)
    r.exits.each { |e|
      next if not e
      delete_connection(e)
    }
    delete_room_only(r)
  end

  #
  # Create a new room  (note: FXSection overrides this creating an
  # FXRoom instead).
  #
  def new_room( x, y )
    r = Room.new( x, y, 'New Location' )
    return _new_room(r, x, y)
  end

  def initialize()
    @rooms       = []
    @connections = []
    @name        = ''
    @comments    = ''
  end

  protected

  def _new_room( r, x, y )
    @rooms.push(r)
    return r
  end

  def _new_connection(c, roomA, exitA, roomB, exitB)
    exitA = roomA.exit_to(roomB) if not exitA
    if not exitA
      err = <<"EOF"
No exit given or guessed to connect: 
      Room #{roomA} (#{roomA.x}, #{roomA.y})
      Room #{roomB} (#{roomB.x}, #{roomB.y})
EOF
      raise ConnectionError, err
    end

    if roomA[exitA]
      if not @connections.include?(roomA[exitA])
	raise ConnectionError, "roomA exit #{exitA} for '#{roomA}' filled but not in section"
      end
      raise ConnectionError, "roomA exit #{exitA} for '#{roomA}' is filled" 
    end

    roomA[exitA] = c

    if roomB and not exitB
      dx, dy = Room::DIR_TO_VECTOR[exitA]
      x = roomA.x + dx
      y = roomA.y + dy
      if roomB.x == x and roomB.y == y
	exitB = (exitA + 4) % 8 
      else
	dx = x - roomB.x
	dy = y - roomB.y
	exitB = roomB.vector_to_dir(dx, dy)
      end
    end

    if roomB and roomB[exitB] and roomB[exitB] != c
      roomA[exitA] = nil
      raise ConnectionError, "roomB exit #{exitB} for #{roomB} is filled with #{roomB[exitB]}" 
    end
    roomB[exitB] = c if roomB

    @connections.push( c )
    return c
  end

  def to_s
    return @name
  end

end
