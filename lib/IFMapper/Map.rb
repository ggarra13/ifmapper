#!/usr/bin/env ruby

require 'IFMapper/Room'
require 'IFMapper/Section'

class Map
  attr_accessor :name
  attr_accessor :creator
  attr_accessor :date

  attr_reader   :section
  attr_accessor :sections

  attr_accessor :width
  attr_accessor :height


  #
  # Used for loading class with Marshal
  #
  def marshal_load(v)
    @name     = v.shift
    @creator  = v.shift
    @date     = v.shift
    @section  = v.shift
    @sections = v.shift
    @width    = v.shift
    @height   = v.shift
  end

  #
  # Used for saving class with Marshal
  #
  def marshal_dump
    [ @name, @creator, @date, @section, @sections, @width, @height ] 
  end

  def section=(x)
    x = 0               if x < 0 
    x = @sections.size - 1 if x >= @sections.size
    @section = x
  end

  #
  # Auxiliary debugging function to verify the integrity of the map
  #
  def verify_integrity
    @sections.each { |sect|
      sect.rooms.each { |r|
	r.exits.each_with_index { |e, idx|
	  next if not e
	  if not sect.connections.include?(e)
	    $stderr.puts "Exit #{e} in room, but not in section #{sect.name}."
	    r.exits[idx] = nil
	    sect.connections.delete(e)
	  end
	}
      }

      sect.connections.each { |c|
	a = c.roomA
	b = c.roomB
	if not a.exits.index(c) or 
	    (b and not b.exits.rindex(c))
	  $stderr.puts "Exit #{c} not present in room."
	  sect.connections.delete(c)
	end
      }
    }
  end

  #
  # Change map's width and height to make sure all rooms and connections
  # will fit in map
  #
  def fit
    # First, adjust map's width and height
    @width = @height = 3
    minXY = []
    maxXY = []

    @sections.each { |section|
      next if section.rooms.empty?

      sizes = section.min_max_rooms
      minXY.push sizes[0]
      maxXY.push sizes[1]

      w = maxXY[-1][0] - minXY[-1][0]
      h = maxXY[-1][1] - minXY[-1][1]

      # We store +3 to allow for complex connections if needed.
      @width  = w + 3 if w >= @width - 2
      @height = h + 3 if h >= @height - 2
    }


    # Okay, minXY[]/maxXY[] contains all the minXY/maxXY positions of
    # each section.  With that info and @weight/@height, we can
    # start shifting all nodes in the section so that they will fit.
    idx = 0
    @sections.each  { |p|
      next if p.rooms.size == 0
      x = y = 0
      x = 1 - minXY[idx][0] if minXY[idx][0] < 1
      y = 1 - minXY[idx][1] if minXY[idx][1] < 1
      x = @width  - maxXY[idx][0] - 2 if maxXY[idx][0] >= @width  - 1
      y = @height - maxXY[idx][1] - 2 if maxXY[idx][1] >= @height - 1
      idx += 1
      next if x == 0 and y == 0 # nothing to shift
      p.rooms.each { |r| 
	r.x += x
	r.y += y
      }
    }
  end

  def initialize(name)
    @section = 0
    @name    = name
    @creator = ''

    @width  = 8
    @height = 11

    @date = nil

    # Add at least one section
    @sections = []
    new_section
  end

  def copy(b)
    @section  = b.section
    @sections = b.sections
    @name     = b.name
    @creator  = b.creator
    @width    = b.width
    @height   = b.height
    @date     = b.date
  end

  #
  # Return true or false if map is free at location x,y
  #
  def free?(x, y)
    return @sections[@section].free?(x,y)
  end

  def shift(x, y, dx, dy)
    @sections[@section].shift(x, y, dx, dy)
  end

  def delete_connection(c)
    @sections[@section].delete_connection(c)
  end

  def delete_connection_at( idx )
    @sections[@section].delete_connection_at(idx)
  end


  def new_connection( roomA, exitA, roomB, exitB = nil )
    @sections[@section].new_connection(roomA, exitA, roomB, exitB)
  end


  def delete_room_at(idx)
    @sections[@section].delete_room_at(idx)
  end

  def delete_room_only(r)
    @sections[@section].delete_room_only(r)
  end

  def delete_room(r)
    @sections[@section].delete_room(r)
  end

  def new_room( x, y )
    @sections[@section].new_room(x, y)
  end

  def new_section
    @sections.push( Section.new )
    @section = @sections.size - 1
  end

  def _check_section
    @section = @sections.size - 1 if @section >= @sections.size
    new_section if @sections.size == 0
  end

  def delete_section_at(idx)
    @sections.delete_at(idx)
    _check_section
  end


end


