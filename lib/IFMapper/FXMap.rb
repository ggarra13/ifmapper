#!/usr/bin/env ruby


require 'IFMapper/Map'
require 'IFMapper/FXSection'
require 'IFMapper/FXMapDialogBox'
require 'IFMapper/FXSectionDialogBox'
require 'IFMapper/AStar'
require 'IFMapper/FXWarningBox'
require 'thread'


class FXMap < Map
  FILE_FORMAT_VERSION = 1  # Upgrade this if incompatible changes are made
                           # in the class so that file loading of old files 
                           # can still be checked against.

  attr_reader   :zoom        # Current zooming factor
  attr_accessor :filename    # Filename of current map (if any)
  attr_reader   :modified    # Was map modified since being loaded?
  attr_accessor :navigation  # Map is navigation mode (no new nodes can be 
                             # created)
  attr_accessor :options     # Map options
  attr_reader   :window      # Fox Window for this map
  attr          :version     # file format version
  attr_reader   :mutex       # Mutex to avoid racing conditions while
                             # automapping
  attr_reader   :automap     # automapping transcript

  attr_reader   :complexConnection # Complex connection in progress
  attr_reader   :mouseButton       # Mouse button pressed


  # pmap is a path map (a matrix or grid used for path finding).  
  # Rooms and paths are recorded there.  Path finding is needed 
  # to draw complex connections (ie. those that are farther than one square)
  # We now also use this for selecting of stuff, particularly complex paths.
  attr          :pmap

  @@win      = nil  # Map Info  window
  @@roomlist = nil  # Room List Window
  @@itemlist = nil  # Item List Window

  # Cursors
  @@tooltip = nil
  @@cursor_arrow = nil
  @@cursor_cross = nil
  @@cursor_n = nil
  @@cursor_ne = nil
  @@cursor_e = nil
  @@cursor_se = nil
  @@cursor_s = nil
  @@cursor_sw = nil
  @@cursor_w = nil
  @@cursor_nw = nil

  #
  # Map has changed dramatically.  Update pathmap, title and redraw
  #
  def _changed
    create_pathmap
    if @window and @window.shown?
      update_title
      draw
    end
  end


  #
  # Jump to a certain section #
  #
  def section=(x)
    clear_selection
    super
    @complexConnection = false
    _changed
  end

  #
  # Go to previous section (if any)
  #
  def previous_section
    self.section = @section - 1
    _changed
  end

  #
  # Go to next section (if any)
  #
  def next_section
    self.section = @section + 1
    _changed
  end

  #
  # Map has been modified.  Update also pathmap.
  #
  def modified=(x)
    @modified = x
    _changed
  end

  #
  # Popup the section properties to allow renaming it
  #
  def rename_section
    @sections[@section].properties(self)
    self.modified = true
  end

  #
  # Delete current section from map
  #
  def delete_section
    return navigation_warning if @navigation
    w = FXWarningBox.new(@window, WARN_DELETE_SECTION)
    return if w.execute == 0

    delete_section_at(@section)
    self.modified = true
  end

  #
  # Add a new section to map and make it current
  #
  def new_section
    return navigation_warning if @navigation
    @sections.push( FXSection.new )
    @section = @sections.size - 1
  end

  #
  # Select all connections and rooms
  #
  def select_all
    sect = sections[section]
    sect.rooms.each { |r|
      r.selected = true
    }
    sect.connections.each { |c|
      c.selected = true
    }
    draw
  end

  #
  # A simple debugging function that will spit out the path map with a 
  # very simple ascii representation.
  #
  def dump_pathmap
    s = ' ' + ' ' * @width + "\n"
    m = s * @height
    (0...@width).each { |x|
      (0...@height).each { |y|
	m[y * (@width+2)] = (y % 10).to_s
	loc = y * (@width+2) + x + 1
	if @pmap.at(x).at(y).kind_of?(Connection)
	  m[loc] = '-'
	elsif @pmap.at(x).at(y).kind_of?(Room)
	  m[loc] = 'R'
	end
      }
    }
    puts ' 0123456789' * (@width/10)
    puts m
  end

  #
  # Determine whether a pathmap area from x,y to x+w,y+h is free
  # of rooms
  #
  def _free_area?(x, y, w, h)
    x.upto(x+w) { |xx|
      y.upto(y+h) { |yy|
	return false if @pmap.at(xx).at(yy).kind_of?(Room)
      }
    }
    return true
  end

  #
  # Return true or false if map is free at location x, y.
  # If x and y coords are within pathmap, we use it.
  # If not, we will use the brute force search of Map.rb
  #
  def free?(x, y)
    if @pmap and x >= 0 and y >= 0 and @pmap.size > x and @pmap.at(x).size > y
      return false if @pmap.at(x).at(y)
      return true
    else
      super
    end
  end

  #
  # Given a list of rooms, find an area in the map where we could
  # place them.  If found, return x/y offset so rooms can be moved
  # there.  This is used for pasting rooms.
  #
  def find_empty_area(rooms)
    return nil if rooms.empty?
    minx = maxx = rooms[0].x 
    miny = maxy = rooms[0].y
    rooms.each { |r|
      minx = r.x if r.x < minx
      maxx = r.x if r.x > maxx
      miny = r.y if r.y < miny
      maxy = r.y if r.y > maxy
    }
    w = maxx - minx
    h = maxy - miny

    # Find an area in pathmap that has w x h empty rooms
    0.upto(@width-1-w) { |x|
      0.upto(@height-1-h) { |y|
	if _free_area?(x, y, w, h)
	  return [x - minx, y - miny]
	end
      }
    }
    return nil
  end

  #
  # Reinitialize the pathmap to an empty matrix
  # 
  def empty_pathmap
    # First, create an empty grid of width x height
    @pmap = Array.new(@width)
    (0...@width).each { |x|
      @pmap[x] = Array.new(@height)
    }
    return pmap
  end

  #
  # Recreate the pathmap based on rooms and connections
  # This routine is used on loading a new map.
  #
  def create_pathmap
    # First, create an empty grid of width x height
    empty_pathmap
    # Then, fill it in with all rooms...
    @sections[@section].rooms.each { |r| @pmap[r.x][r.y] = r }
    # And following, add all paths
    @sections[@section].connections.each { |c| path_find(c) }
  end

  #
  # Given a connection, clean its path from path map.
  #
  def clean_path(c)
    c.gpts.each { |p| @pmap[p[0]][p[1]] = nil if @pmap[p[0]][p[1]] == c }
  end

  #
  # Remove a connection from map, since path creation failed.
  #
  def remove_connection(c)
    c.failed = true
    status "#{ERR_PATH_FOR_CONNECTION} #{c} #{ERR_IS_BLOCKED}."
  end

  # Given a connection, create the path for it, if not a simple
  # connection.  Also, add the paths to pathmap.
  def path_find(c)
    unless c.complex?
      c.pts = c.gpts = []
      c.failed = false
      return true
    end

    # Complex path... Generate points.
    a, b = c.room
    dirA, dirB = c.dirs
    raise "A connection not found #{c} at #{a}" unless dirA
    raise "B connection not found #{c} at #{b}" unless dirB

    vA = FXRoom::DIR_TO_VECTOR[dirA]
    vB = FXRoom::DIR_TO_VECTOR[dirB]

    pA = [ a.x + vA[0], a.y + vA[1] ]
    pB = [ b.x + vB[0], b.y + vB[1] ]

    c.gpts = []
    c.pts  = []

    # Check for the special case of looping path (path that begins and
    # returns to same exit)
    if a == b and dirA == dirB
      pt = a.corner(c, 1, dirA)
      n  = 1.0 / Math.sqrt(vA[0] * vA[0] + vA[1] * vA[1])
      vA = [ vA[0] * n, vA[1] * n ]
      c.pts.push( [ pt[0], pt[1] ] )
      pA = [ pt[0] + vA[0] * 20, pt[1] + vA[1] * 20 ]
      c.pts.push( [pA[0], pA[1]] )
      pB = [ pA[0] + vA[1] * 20, pA[1] - vA[0] * 20 ]
      c.pts.push( [pB[0], pB[1]] )
      pC = [ pB[0] - vA[0] * 20, pB[1] - vA[1] * 20 ]
      c.pts.push( [pC[0], pC[1]] )
      c.dir = Connection::AtoB
      return true
    end

    # Now check if start or goal are fully blocked. If so,
    # fail quickly
    if pA[0] < 0 or pA[0] >= @width or
	pB[0] < 0 or pB[0] >= @width or
	pA[1] < 0 or pA[1] >= @height or
	pB[1] < 0 or pB[1] >= @height or
	@pmap.at(pA[0]).at(pA[1]).kind_of?(Room) or 
	@pmap.at(pB[0]).at(pB[1]).kind_of?(Room)
      remove_connection(c)
      return false
    end

    if (pA[0] - pB[0]).abs > 30 or
	(pA[1] - pB[1]).abs > 30
      c.failed = true
      return
    end

    # No, okay, we need to do true A* path finding
    c.failed = false
    aStar    = AStar.new
    MapNode::map(@pmap)
    start    = MapNode.new( pA[0], pA[1] )
    goal     = MapNode.new( pB[0], pB[1] )
    aStar.goals( start, goal )
    while aStar.search_step == AStar::SEARCH_STATE_SEARCHING
    end

    # Oops, AStar failed.  Not a clean path
    if aStar.state == AStar::SEARCH_STATE_FAILED
      remove_connection(c)
      return false
    end

    # We succeeded.  Get the path
    c.failed = false
    c.gpts   = aStar.path
    # Put path in pathmap so subsequent paths will try to avoid crossing it.
    c.gpts.each { |p| @pmap[p[0]][p[1]] = c }

    # Okay, we have a valid path. 
    # Create real path in display coordinates now...
    # Start with a's corner
    pt = a.corner(c, 1, dirA)
    c.pts.push( [ pt[0], pt[1] ] )
    # Then, add each grid point we calculated
    c.gpts.each { |p| 
      x = p[0] * WW + WW / 2
      y = p[1] * HH + HH / 2
      c.pts.push([x, y])
    }
    # And end with b's corner
    pt = b.corner(c, 1, dirB)
    return c.pts.push([pt[0], pt[1]])
  end

  #
  # Add a new path point to a connection
  #
  def add_path_pt( c, x, y )
    @pmap[x][y] = c
    c.gpts.push([x, y])
  end

  #
  # Used for loading class with Marshal
  #
  def marshal_load(variables)
    @zoom       = variables.shift
    @navigation = variables.shift
    @options    = variables.shift
    super
    @modified   = false
    @complexConnection = nil
  end

  #
  # Used for saving class with Marshal
  #
  def marshal_dump
    [ @zoom, @navigation, @options ] + super 
  end

  #
  # Used to copy relevant data from one (temporary) map to another
  #
  def copy(b)
    super(b)
    if b.kind_of?(FXMap)
      @options  = b.options if b.options
      @filename = b.filename
      self.zoom = b.zoom
      @navigation = b.navigation
      @modified = true
      @complexConnection = nil
    end
  end

  #
  # Create a new room for the current section
  #
  def new_room(x, y)
    @modified = true
    r = @sections[@section].new_room(x, y)
    return r
  end

  #
  # Function used to add a new room. x and y are absolute pixel positions
  # in canvas.
  #
  def new_xy_room(x, y)
    x = x / WW
    y = y / HH
    r = new_room(x, y)
    @pmap[x][y] = r

    r.selected = true
    
    if @options['Edit on Creation']
       if not r.modal_properties(self)
	 @sections[@section].delete_room(r)
	 @pmap[x][y] = nil
	 return nil
       end
    end
    update_roomlist
    return r
  end

  #
  # Given a room, delete it
  #
  def delete_room_only(r)
    if @pmap and r.x < @pmap.size and r.y < @pmap.size and
	r.x >= 0 and r.y >= 0
      @pmap[r.x][r.y] = nil
    end
    super
  end

  #
  # Given a room, delete it
  #
  def delete_room(r)
    if @pmap and r.x < @pmap.size and r.y < @pmap.size and
	r.x >= 0 and r.y >= 0
      @pmap[r.x][r.y] = nil
    end
    super
  end

  # Given a canvas (mouse) x/y position, return:
  #
  # false - arrow click
  # true  - room  click
  #
  def click_type(x, y)
    x = (x % WW).to_i
    y = (y % HH).to_i

    if x >= WS_2 and y >= HS_2 and
	x <= (W + WS_2) and y <= (H + HS_2)
      return true
    else
      return false
    end
  end

  # Given an x and y canvas position, return room object, 
  # complex connection or nil
  def to_room(x,y)
    xx = x / WW
    yy = y / HH
    return @pmap.at(xx).at(yy)
  end

  # Given a mouse click x/y position, return object(s) if any or nil
  def to_object(x, y)

    exitA = get_quadrant(x, y)
    unless exitA
      # Not in arrow section, return element based on pmap
      # can be a room or complex arrow connection.
      xx = x / WW
      yy = y / HH
      return nil if xx >= @width or yy >= @height
      return @pmap.at(xx).at(yy)
    else
      # Possible arrow
      @sections[@section].connections.each { |c|
	a = c.roomA
	b = c.roomB
	next if not b and @complexConnection

	if c.gpts.size > 0
	  2.times { |t|
	    if t == 0
	      r = a
	      dir = r.exits.index(c)
	    else
	      r = b
	      dir = r.exits.rindex(c)
	    end
	    next if not r
	    x1, y1 = r.corner(c, 1, dir)
	    v = FXRoom::DIR_TO_VECTOR[dir]
	    x2 = x1 + v[0] * WS
	    y2 = y1 + v[1] * HS
	    if x1 == x2
	      x1 -= W / 2
	      x2 += W / 2
	    end
	    if y1 == y2
	      y1 -= H / 2
	      y2 += H / 2
	    end
	    x1, x2 = x2, x1 if x2 < x1
	    y1, y2 = y2, y1 if y2 < y1
	    
	    if x >= x1 and x <= x2 and
		y >= y1 and y < y2
	      return c
	    end
	  }
	else
	  x1, y1 = a.corner(c, 1, a.exits.index(c))
	  if b
	    x2, y2 = b.corner(c, 1, b.exits.rindex(c))
	  else
	    dir = a.exits.index(c)
	    v = FXRoom::DIR_TO_VECTOR[dir]
	    x2 = x1 + v[0] * WS
	    y2 = y1 + v[1] * HS
	  end

	  x1, x2 = x2, x1 if x2 < x1
	  y1, y2 = y2, y1 if y2 < y1
	  if x1 == x2
	    x1 -= W / 2
	    x2 += W / 2
	  end
	  if y1 == y2
	    y1 -= H / 2
	    y2 += H / 2
	  end
	  if x >= x1 and x <= x2 and
	      y >= y1 and y < y2
	    return c
	  end
	end
      }

      return nil
    end

    return nil
  end

  #
  # Update the map window's title
  #
  def update_title
    title = @name.to_s.dup
    if @navigation
      title << "     #{TITLE_READ_ONLY}"
    end
    if @automap
      title << "     #{TITLE_AUTOMAP}"
    end
    title << "      #{TITLE_ZOOM} %.3f" % @zoom
    title << "      #{TITLE_SECTION} #{@section+1} #{TITLE_OF} #{@sections.size}"
    title << "      #{@sections[@section].name}"  
    @window.title = title
  end

  # Change zoom factor of map.  Rebuild fonts and canvas sizes.
  def zoom=(value)
    @zoom = ("%.2f" % value).to_f
    # Create the font
    fontsize = (11 * @zoom).to_i

    if @window
      @font = FXFont.new(@window.getApp, @options['Font Text'], fontsize)
      @font.create

      @objfont = FXFont.new(@window.getApp, @options['Font Objects'], 
			    (fontsize * 0.75).to_i)
      @objfont.create

      width  = (WW * @width * @zoom).to_i
      height = (HH * @height * @zoom).to_i
      @canvas.width  = width
      @canvas.height = height

      # Then, create an off-screen image with that same size for double
      # buffering
      @image.release
      @image.destroy
      GC.start

      @image = FXBMPImage.new(@window.getApp, nil, IMAGE_SHMI|IMAGE_SHMP, 
			      width, height)
      @image.create
      update_title
    end

  end

  # Given a mouse x/y position to WS/HS, return an index 
  # indicating what quadrant it belongs to.
  def get_quadrant(ax, ay)
    # First get relative x/y position
    x = ax % WW
    y = ay % HH

    quadrant = nil
    if x < WS_2
      #left
      if y < HS_2
	# top
	quadrant = 7
      elsif y > H + HS_2
	# bottom
	quadrant = 5
      else
	# center
	quadrant = 6
      end
    elsif x > W + WS_2
      # right
      if y < HS_2
	# top
	quadrant = 1
      elsif y > H + HS_2
	# bottom
	quadrant = 3
      else
	# center
	quadrant = 2
      end
    else
      #center
      if y < HS_2
	# top
	quadrant = 0
      elsif y > H + HS_2
	# bottom
	quadrant = 4
      else
	# center
	quadrant = nil
      end
    end


    return quadrant
  end

  # Given an x,y absolute position corresponding to a connection,
  # return connected rooms (if any).
  def quadrant_to_rooms( q, x, y )
    maxX = @width  * WW
    maxY = @height * HH

    # First check if user tried adding a connection
    # at the edges of the map.  If so, return empty stuff.
    if  x < WS_2 or y < HS_2 or
	x > maxX - WS_2 or y > maxY - HS_2
      return [nil, nil, nil, nil]
    end

    x1 = x2 = x
    y1 = y2 = y

    case q
    when 0, 4
      y1 -= HS
      y2 += HS
    when 1, 5
      x1 -= WS
      x2 += WS
      y1 += HS
      y2 -= HS
    when 2, 6
      x1 -= WS
      x2 += WS
    when 3, 7 
      x1 -= WS
      y1 -= HS
      x2 += WS
      y2 += HS
    end

    case q
      when 0, 5, 6, 7
      x1, x2 = x2, x1
      y1, y2 = y2, y1
    end

    roomA = to_room(x1, y1)
    roomB = to_room(x2, y2)
    # Oops, user tried to create rooms where we already
    # have a complex connection.  Don't create anything, then.
    if roomA.kind_of?(Connection) or 
	(roomB.kind_of?(Connection) and not @complexConnection)
      return [roomA, roomB, nil, nil]
    end

    return [roomA, roomB, [x1, y1], [x2, y2]]
  end

  #
  # Add a new complex connection (or its first point)
  #
  def new_complex_connection( x, y )
    exitA = get_quadrant(x, y)
    unless exitA
      raise "not a connection"
    end
    roomA, roomB, a, b = quadrant_to_rooms( exitA, x, y )
    unless a and roomA and roomA[exitA] == nil
      return
    end
    _new_complex_connection(roomA, exitA)
  end
    
  def _new_complex_connection(roomA, exitA)
    if @complexConnection.kind_of?(TrueClass)
      @complexConnection = [roomA, exitA]
      c = new_connection( roomA, exitA, nil )
      status MSG_COMPLEX_CONNECTION_OTHER_EXIT
    else
      @sections[@section].delete_connection_at(-1)
      c = new_connection( @complexConnection[0], 
			 @complexConnection[1], roomA, exitA )
      if path_find(c)  # Do A* path finding to connect both exits
	@modified = true
	status MSG_COMPLEX_CONNECTION_DONE
      else
	@sections[@section].delete_connection_at(-1)
      end
      draw
      @complexConnection = nil
    end
  end

  #
  # Add a new room connection among contiguous rooms.
  #
  def new_xy_connection( x, y )
    exitA = get_quadrant(x, y)
    unless exitA
      raise "not a connection"
    end

    # Then, get rooms being connected
    roomA, roomB, a, b = quadrant_to_rooms( exitA, x, y )
    return unless a # User click outside map

    if @options['Create on Connection']
      roomA = new_xy_room( a[0], a[1] ) unless roomA
      roomB = new_xy_room( b[0], b[1] ) unless roomB
    end

    return nil unless roomA and roomB

    if roomA == roomB
      raise "error: same room connection"
    end

    @modified = true
    if roomA and exitA
      # get old connection
      if roomA[exitA]
	c = roomA[exitA]
	delete_connection(c) if c.roomB == nil
      end
      exitB = (exitA + 4) % 8
      if roomB[exitB]
	c = roomB[exitB]
	delete_connection(c) if c.roomB == nil
      end
    end
    begin
      new_connection( roomA, exitA, roomB )
    rescue Section::ConnectionError
    end
  end

  #
  # Handle mouse button double clicks in canvas
  #
  def double_click_cb(selection, event)
    return unless selection
    # If in navigation mode, we don't allow user to modify map.
    return navigation_warning if @navigation
    if selection.kind_of?(FXRoom) or selection.kind_of?(FXConnection)
      selection.properties( self, event )
    end
  end

  # Self-explanatory.
  def zoom_out
    if @zoom > 0.1
      self.zoom -= 0.1
    end
  end

  # Self-explanatory.
  def zoom_in
    if @zoom < 1.25
      self.zoom += 0.1
    end
  end

  # Spit out a new message to the status line.
  def status(msg)
    mw  = @window.parent.parent
    statusbar = mw.children.find() { |x| x.kind_of?(FXStatusBar) }
    s = statusbar.statusLine
    s.normalText = s.text = msg
  end

  #
  # Based on x,y coordinate, switch mouse icon shape
  #
  def cursor_switch(x, y)
    if not @options['Use Room Cursor']
      @canvas.defaultCursor = @@cursor_arrow
      return
    end
    q = get_quadrant(x, y)
    case q
    when 0
      @canvas.defaultCursor = @@cursor_n
    when 1
      @canvas.defaultCursor = @@cursor_ne
    when 2
      @canvas.defaultCursor = @@cursor_e
    when 3
      @canvas.defaultCursor = @@cursor_se
    when 4
      @canvas.defaultCursor = @@cursor_s
    when 5
      @canvas.defaultCursor = @@cursor_sw
    when 6
      @canvas.defaultCursor = @@cursor_w
    when 7
      @canvas.defaultCursor = @@cursor_nw
    else
      @canvas.defaultCursor = @@cursor_arrow
    end
  end

  #
  # Based on mouse position on canvas, create a tooltip
  #
  def tooltip_cb(sender, id, ptr)
    if @zoom < 0.6 and @tooltip_msg != ''
      sender.text = @tooltip_msg.to_s
      sender.show
    else
      sender.hide
    end
  end


  #
  # Show some help status in status line based on cursor position
  #
  def help_cb(sender, sel, event)

    x = (event.last_x / @zoom).to_i
    y = (event.last_y / @zoom).to_i
    if @complexConnection
      cursor_switch(x,y)
      return
    end

    @tooltip_msg = ''
    sel = to_object(x, y)
    if sel
      @canvas.defaultCursor = @@cursor_arrow
      if sel.kind_of?(Room)
	@tooltip_msg = sel.name
	status "\"#{sel.name}\": #{MSG_CLICK_TO_SELECT_AND_MOVE}"
      elsif sel.kind_of?(Connection)
	status MSG_CLICK_TOGGLE_ONE_WAY_CONNECTION
      end
    else
      if click_type(x, y)
	@canvas.defaultCursor = @@cursor_cross
	status MSG_CLICK_CREATE_ROOM
      else
	cursor_switch(x, y)
	status MSG_CLICK_CREATE_LINK
      end
    end
  end

  #
  # zoom in/out based on mousewheel, keeping position relative
  # to cursor position
  #
  def mousewheel_cb(sender, sel, event)
    case event.code
    when -120   # Hmm, there does not seem to be constants for these
      zoom_out
      # @scrollwindow.setPosition( -x, -y )
    when 120    # Hmm, there does not seem to be constants for these
      # pos = @scrollwindow.position
      # w = @scrollwindow.maxChildWidth
      # h = @scrollwindow.maxChildHeight
      #p @scrollwindow.range
      # puts "pos: #{pos[0]} #{pos[1]}"
      # x = event.last_x
      # y = event.last_y
      # puts "event: #{x} #{y}"
      zoom_in
      # @scrollwindow.setPosition( -x, -y )
    end
  end

  #
  # Handle middle mouse button click in canvas
  #
  def mmb_click_cb(server, sel, event)
    @canvas.grab
    @dx = @dy = 0
    @mouseButton = MIDDLEBUTTON
  end

  #
  # Select all rooms and connections within (drag) rectangle
  #
  def select_rectangle(x1, y1, x2, y2)
    x1, x2 = x2, x1 if x2 < x1
    y1, y2 = y2, y1 if y2 < y1

    x = x1 * zoom
    y = y1 * zoom
    w = x2 - x1
    h = y2 - y1

    x1 = ((x1 + WS_2) / WW).floor
    y1 = ((y1 + HS_2) / HH).floor
    x2 = ((x2 - WS_2) / WW).ceil
    y2 = ((y2 - HS_2) / HH).ceil

    @sections[@section].rooms.each { |r|
      if r.x >= x1 and r.x <= x2 and
	  r.y >= y1 and r.y <= y2
	r.selected = true
	r.update_properties(self)
      else
	r.selected = false
      end
    }

    @sections[@section].connections.each { |c|
      next if not c.roomB
      a = c.roomA
      b = c.roomB

      if (a.x >= x1 and a.x <= x2 and
	  a.y >= y1 and a.y <= y2) or
	  (b.x >= x1 and b.x <= x2 and
	   b.y >= y1 and b.y <= y2)
	c.selected = true
	c.update_properties(self)
      else
	c.selected = false
      end
    }

    draw
    dc = FXDCWindow.new(@canvas)
    dc.function = BLT_NOT_SRC_XOR_DST 
    dc.drawRectangle(x, y, w * @zoom, h * @zoom)
    dc.end
  end

  #
  # Handle mouse motion in canvas
  #
  def motion_cb(server, sel, event)
    if @mouseButton == MIDDLEBUTTON
      @canvas.dragCursor = @@cursor_move
      pos = @scrollwindow.position
      dx = event.last_x - event.win_x
      dy = event.last_y - event.win_y
      if (dx != 0 or dy != 0) and !(dx == @dx and dy == @dy)
	pos[0] += dx
	pos[1] += dy
	@dx = dx
	@dy = dy
	@scrollwindow.setPosition(pos[0], pos[1])
	@canvas.repaint
      end
    elsif @mouseButton == LEFTBUTTON
      x = (event.last_x / @zoom).to_i
      y = (event.last_y / @zoom).to_i
      select_rectangle( @dx, @dy, x, y )
    else
      help_cb(server, sel, event)
    end
  end

  #
  # Handle release of middle mouse button
  #
  def mmb_release_cb(server, sel, event)
    if @mouseButton
      @canvas.ungrab
      @canvas.dragCursor = @@cursor_arrow
      if @mouseButton == LEFTBUTTON
	draw
      else
	@canvas.repaint
      end
      @mouseButton = nil
    end
  end

  #
  # Given a room, center scrollwindow so room is visible
  #
  def center_view_on_room(r)
    xx = (r.xx + W / 2) * @zoom
    yy = (r.yy + H / 2) * @zoom
    center_view_on_xy(xx, yy)
  end

  #
  # Given an x and y coordinate for the canvas, center on it
  #
  def center_view_on_xy(xx, yy)
    cw = @scrollwindow.getContentWidth
    ch = @scrollwindow.getContentHeight
    w = @scrollwindow.getViewportWidth
    h = @scrollwindow.getViewportHeight

    xx -= w / 2
    yy -= h / 2
    maxx = cw - w / 2
    maxy = ch - h / 2
    if xx > maxx
      xx = maxx
    elsif xx < 0
      xx = 0
    end
    if yy > maxy
      yy = maxy
    elsif yy < 0
      yy = 0
    end

    @scrollwindow.setPosition( -xx, -yy )
  end

  #
  # Return current selection as an array of rooms and an array of
  # connections
  #
  def get_selection
    rooms = @sections[@section].rooms.find_all { |r| r.selected }
    conns = @sections[@section].connections.find_all { |r| r.selected }
    return rooms, conns
  end

  #
  # Clear rooms/connections selected
  #
  def clear_selection
    @sections[@section].rooms.each { |r| r.selected = false }
    @sections[@section].connections.each { |r| r.selected = false }
  end

  #
  # Add a proper link submenu option for an exit  
  #
  def rmb_link_menu(submenu, c, room, idx, old_idx)
    return if room[idx] == c
    dir = Room::DIRECTIONS[idx]
    dir = dir.upcase
    if room[idx]
      cmd = FXMenuCommand.new(submenu, "#{MENU_SWITCH_WITH_LINK} #{dir}")
      cmd.connect(SEL_COMMAND) { 
	c2 = room[idx]
	room[old_idx] = c2
	room[idx] = c
	create_pathmap
	draw
      }
    else
      cmd = FXMenuCommand.new(submenu, "#{MENU_MOVE_LINK} #{dir}")
      cmd.connect(SEL_COMMAND) { 
	room[old_idx] = nil
	room[idx] = c
	create_pathmap
	draw
      }
    end
  end

  #
  # Handle right mouse button click
  #
  def rmb_click_cb(sender, sel, event)
    rooms, links = get_selection

    menu = nil
    if not links.empty? and links.size == 1
      c = links[0]
      a = c.roomA
      b = c.roomB
      menu = FXMenuPane.new(@window)
      if c.dir == Connection::AtoB
	cmd = FXMenuCommand.new(menu, MENU_FLIP_DIRECTION)
	cmd.connect(SEL_COMMAND) { c.flip; draw }
	FXMenuSeparator.new(menu)
      end

      submenu = FXMenuPane.new(@window)
      old_idx = a.exits.index(c)
      0.upto(7) { |idx|
	rmb_link_menu( submenu, c, a, idx, old_idx )
      }
      FXMenuCascade.new(menu, a.name, nil, submenu)
      if b
	submenu = FXMenuPane.new(@window)
	old_idx = b.exits.rindex(c)
	0.upto(7) { |idx|
	  rmb_link_menu( submenu, c, b, idx, old_idx )
	}
	FXMenuCascade.new(menu, b.name, nil, submenu)
      end
    end
    if menu
      menu.create
      menu.popup(nil, event.root_x, event.root_y)
      @window.getApp.runModalWhileShown(menu)
    end
  end


  #
  # Handle left mouse button click
  #
  def lmb_click_cb(sender, sel, event)
    x = (event.last_x / @zoom).to_i
    y = (event.last_y / @zoom).to_i

    if event.state & ALTMASK != 0
      mmb_click_cb(sender, sel, event)
      return
    end

    selection = to_object(x, y)

    if event.state & SHIFTMASK != 0
      @mouseButton = LEFTBUTTON
      @canvas.grab
      @dx, @dy = [ x, y ]
      return if not selection
    end


    if event.click_count == 2
      double_click_cb(selection, event)
      return
    end

    unless selection
      clear_selection

      # If in navigation mode, we don't allow user to modify map.
      return if @navigation

      # if we did not select anything, check to see if we
      # clicked in a room area or connection area.
      if click_type(x, y)
	return if @complexConnection
	# Add a new room
	roomB = @sections[@section].rooms[-1]
	roomA = new_xy_room( x, y )
	if roomB and roomA and @options['Automatic Connection']
	  # check to see if rooms are next to each other
	  # if so, try to connect them (assuming there's no connection there
	  # already).
	  exitB = roomB.next_to?(roomA)
	  if exitB and roomB.exits[exitB] == nil
	    new_connection( roomB, exitB, roomA )
	  end
	end
      else
	# Add a new connection
	if @complexConnection
	  new_complex_connection(x, y)
	else
	  # Add a new simple connection (plus rooms if needed)
	  if event.state & CONTROLMASK != 0
	    exitA = get_quadrant(x, y)
	    roomA, roomB, a, b = quadrant_to_rooms( exitA, x, y )
	    if not roomA
	      new_xy_connection( x, y )
	    else
	      if a and roomA
		@complexConnection = [roomA, exitA]
		new_connection( roomA, exitA, nil )
		_new_complex_connection( roomA, exitA )
	      end
	    end
	  else
	    new_xy_connection( x, y )
	  end
	end
      end
    else
      if selection.kind_of?(Connection) and selection.selected
	# Toggle arrow direction
        # If in navigation mode, we don't allow user to modify map.
        return if @navigation
	selection.toggle_direction
	draw
	return
      else
	if event.state & SHIFTMASK == 0 and
	    event.state & CONTROLMASK == 0
	  clear_selection
	end
	# Select the stuff
	selection.update_properties(self)
	if event.state & CONTROLMASK != 0
	  selection.selected ^= true # toggle selection
	else
	  selection.selected  = true
	end
      end
    end
    draw(sender, sel, event)
  end

  #
  # Close the map.  Pop up a warning box to allow saving
  # if map has been modified.
  #
  def close_cb()
    if @modified
      dlg = FXDialogBox.new( @window.parent, "Warning", 
			    DECOR_ALL,
			    0, 0, 400, 130)
      # Frame
      s = FXVerticalFrame.new(dlg,
			      LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

      f = FXHorizontalFrame.new(s, LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)

      font = FXFont.new(@window.getApp, "Helvetica", 30)
      font.create
      oops = FXLabel.new(f, "!", nil, 0, LAYOUT_SIDE_LEFT|LAYOUT_FILL_X|
			 LAYOUT_CENTER_Y)
      oops.frameStyle = FRAME_RAISED|FRAME_THICK
      oops.baseColor = 'dark grey'
      oops.textColor = 'red'
      oops.padLeft = oops.padRight = 15
      oops.shadowColor = 'black'
      oops.borderColor = 'white'
      oops.font = font

      FXLabel.new(f, 
                  "\n#{@name} #{MSG_WAS_MODIFIED}#{MSG_SHOULD_I_SAVE_CHANGES}",
		  nil, 0)

      # Separator
      FXHorizontalSeparator.new(s,
				LAYOUT_SIDE_TOP|LAYOUT_FILL_X|SEPARATOR_GROOVE)

      # Bottom buttons
      buttons = FXHorizontalFrame.new(s,
				      LAYOUT_SIDE_BOTTOM|FRAME_NONE|
				      LAYOUT_FILL_X|PACK_UNIFORM_WIDTH)
      # Accept
      yes = FXButton.new(buttons, BUTTON_YES, nil, dlg, FXDialogBox::ID_ACCEPT,
			 FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_X|
			 LAYOUT_RIGHT|LAYOUT_CENTER_Y)
      yes.connect(SEL_COMMAND) { 
	dlg.close
	if save
	  @window.close
	  return true
	else
	  return false
	end
      }
      FXButton.new(buttons, BUTTON_NO, nil, dlg, FXDialogBox::ID_ACCEPT,
		   FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_X|
		   LAYOUT_RIGHT|LAYOUT_CENTER_Y)
      
      # Cancel
      FXButton.new(buttons, BUTTON_CANCEL, nil, dlg, FXDialogBox::ID_CANCEL,
		   FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_X|
		   LAYOUT_RIGHT|LAYOUT_CENTER_Y)
      yes.setDefault
      yes.setFocus

      return false if dlg.execute == 0
    end
    @automap.destroy if @automap
    @automap = nil
    @window.close
    return true
  end

  #
  # Create cursors
  #
  def _make_cursors
    pix = []
    32.times { 32.times { pix << 255 << 255 << 255 << 255 } }
    pix = pix.pack('c*')


    ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'].each { |d|
      eval(<<-"EOF")
      @@cursor_#{d} = FXGIFCursor.new(@window.getApp, pix)
      FXFileStream.open('icons/room_#{d}.gif', FXStreamLoad) { |stream|
	@@cursor_#{d}.loadPixels(stream)
      }
      @@cursor_#{d}.create
      EOF
    }

    @@cursor_move = FXCursor.new(@window.getApp, CURSOR_MOVE)
    @@cursor_move.create

    @@cursor_arrow = FXCursor.new(@window.getApp, CURSOR_ARROW)
    @@cursor_arrow.create
    
    @@cursor_cross = FXCursor.new(@window.getApp, CURSOR_CROSS)
    @@cursor_cross.create
  end

  #
  # Create widgets for this map window
  #
  def _make_widgets
    @scrollwindow = FXScrollWindow.new(@window, 
				       SCROLLERS_NORMAL|SCROLLERS_TRACK)
    width  = WW * @width
    height = HH * @height

    @canvasFrame = FXVerticalFrame.new(@scrollwindow,
				       FRAME_SUNKEN|LAYOUT_FILL_X|
				       LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT)

    # First, create an off-screen image for drawing and double buffering
    @image  = FXBMPImage.new(@window.getApp, nil, IMAGE_SHMI|IMAGE_SHMP, 
			     width, height)
    @image.create

    # Then create canvas
    @canvas = FXCanvas.new(@canvasFrame, nil, 0,
    			   LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT|
			   LAYOUT_TOP|LAYOUT_LEFT,
    			   0, 0, width, height)
    @dirty = true
    # @canvas.connect(SEL_UPDATE, method(:update_cb))

    @canvas.connect(SEL_PAINT, method(:draw))
    @canvas.backColor = @options['BG Color']

    @canvas.connect(SEL_MOUSEWHEEL, method(:mousewheel_cb))
    @canvas.connect(SEL_LEFTBUTTONPRESS, method(:lmb_click_cb))
    @canvas.connect(SEL_LEFTBUTTONRELEASE, method(:mmb_release_cb))
    @canvas.connect(SEL_MOTION, method(:motion_cb))
    @canvas.connect(SEL_MIDDLEBUTTONPRESS, method(:mmb_click_cb))
    @canvas.connect(SEL_MIDDLEBUTTONRELEASE, method(:mmb_release_cb))
    @canvas.connect(SEL_RIGHTBUTTONPRESS, method(:rmb_click_cb))
    @canvas.connect(SEL_KEYPRESS, method(:keypress_cb))

    if fxversion !~ /^1.2/
      @@tooltip = FXToolTip.new(@canvas.app, FXToolTip::TOOLTIP_PERMANENT)
      # Tooltip is too buggy and annoying.  Turning it off for now.
      # @canvas.connect(SEL_QUERY_TIP, method(:tooltip_cb))
    end
  end

  #
  # Main constructor.  Create the object, initialize the pathmap
  # and initialize the widgets and cursors if a parent window is passed.
  #
  def initialize(name, parent = nil, default_options = nil,
		 icon = nil, menu = nil, mode = nil, 
		 x = 0, y = 0, w = 0, h = 0)
    @mutex      = Mutex.new
    @automap    = nil
    @navigation = false
    @modified   = false
    @mouseButton = false
    @filename = nil
    @complexConnection = false
    super(name)
    if parent
      @window  = FXMDIChild.new(parent, name, icon, menu, mode, x, y, w, h)
      @options = default_options
      _make_cursors if not @@cursor_arrow
      _make_widgets
    end
    empty_pathmap
    self.zoom = 0.8
  end

  #
  # Handle 'cutting' any selected rooms and/or connections
  #
  def _cut_selected
    rooms, conns = get_selection
    ############################
    # First, handle rooms...
    ############################
    # Remove rooms from path map
    rooms.each { |r| @pmap[r.x][r.y] = nil }
    # Remove rooms from current section in map
    @sections[@section].rooms -= rooms
    # Add any connections pointing to removed rooms as 
    # connection to remove
    rooms.each { |r|
      conns += r.exits.find_all { |e| e != nil }
    }


    #########################
    # Now, handle connections
    #########################
    conns.uniq!

    # Remove connections from path map
    conns.each { |c| clean_path(c) }

    # Remove connections from current section in map
    @sections[@section].connections -= conns


    return rooms, conns
  end

  def cut_selected
    rooms, conns = _cut_selected

    # Remove room exits pointing to any removed connection
    if conns
      conns.each { |c|
        a = c.roomA
        b = c.roomB
        if not rooms.member?(a)
          a[a.exits.index(c)] = nil
        end
        if b and not rooms.member?(b)
          idx = b.exits.rindex(c)
          b[idx] = nil if idx
        end
      }
    end

    if @complexConnection
      @complexConnection = false
      status MSG_COMPLEX_CONNECTION_STOPPED
    end

    self.modified = true
    create_pathmap
    draw
  end

  #
  # Handle deleting selected rooms and/or connections
  #
  def delete_selected
    return navigation_warning if @navigation
    rooms, conns = _cut_selected

    # Remove room exits pointing to any removed connection
    if conns
      conns.each { |c|
        a = c.roomA
        b = c.roomB
        if not rooms.member?(a)
          a[a.exits.index(c)] = nil
        end
        if b and not rooms.member?(b)
          idx = b.exits.rindex(c)
          b[idx] = nil if idx
        end
      }
    end

    if @complexConnection
      @complexConnection = false
      status MSG_COMPLEX_CONNECTION_STOPPED
    end

    self.modified = true
    create_pathmap
    draw
  end

  #
  # Start a complex connection
  #
  def complex_connection
    return if @complexConnection or @navigation
    @complexConnection = true
    status MSG_COMPLEX_CONNECTION
  end

  #
  # Given a selection of rooms, clear all of them from path map
  #
  def clean_room_selection(selection)
    selection.each { |r| 
      @pmap[r.x][r.y] = nil
      clean_exits(r)
    }
  end

  #
  # Given a selection of rooms, clear all of them from path map
  #
  def store_room_selection(selection)
    selection.each { |r| 
      @pmap[r.x][r.y] = r
    }
    update_exits(selection)
  end

  #
  # Clean all paths from path map for a room
  #
  def clean_exits(room)
    room.exits.each { |c|
      next if not c
      clean_path(c)
    }
  end

  def show_roomlist
    if @@roomlist
      @@roomlist.copy_from(self)
    else
      require 'IFMapper/FXRoomList'
      @@roomlist = FXRoomList.new(self)
    end
    @@roomlist.show
  end

  def show_itemlist
    if @@itemlist
      @@itemlist.copy_from(self)
    else
      require 'IFMapper/FXItemList'
      @@itemlist = FXItemList.new(self)
    end
    @@itemlist.show
  end

  def self.no_maps
    @@roomlist.hide if @@roomlist
    @@itemlist.hide if @@itemlist
    @@win.hide      if @@win
    FXRoom::no_maps
    FXConnection::no_maps
  end

  #
  # If roomlist window is present, update it
  #
  def update_roomlist
    @@roomlist.copy_from(self) if @@roomlist
    @@win.copy_from(self)      if @@win
  end

  def update_itemlist
    @@itemlist.copy_from(self) if @@itemlist
  end

  #
  # Find and update all paths in path map for a room
  #
  def update_exits(selection)
    create_pathmap
    @modified = true
  end


  #
  # Return the current active room
  #
  def current_room
    rooms = @sections[@section].rooms.find_all { |r| r.selected }
    return nil if rooms.empty? or rooms.size > 1
    return rooms[0]
  end

  def cannot_automap(why)
    w = FXWarningBox.new(@window, "#{ERR_CANNOT_AUTOMAP}\n#{why}")
    w.execute
  end

  #
  # Give user some warning if he tries to modify a read-only mode.
  #
  def navigation_warning
    w = FXWarningBox.new(@window, ERR_READ_ONLY_MAP)
    w.execute
  end


  #
  # Move selected rooms in one of the 8 cardinal directions.
  #
  def move_to(idx)
    return navigation_warning if @navigation
    selection = @sections[@section].rooms.find_all { |r| r.selected }
    return if selection.empty?
    clean_room_selection(selection)


    dx, dy = Room::DIR_TO_VECTOR[idx]

    # Check that all nodes can be moved in the specified direction
    selection.each { |r|
      x = r.x + dx
      y = r.y + dy
      if x < 0 or y < 0 or x >= @width or y >= @height or
	  @pmap.at(x).at(y).kind_of?(Room)
	store_room_selection(selection)
	dir = Room::DIRECTIONS[idx]
	status "#{ERR_CANNOT_MOVE_SELECTION} #{dir}."
	return
      end
    }
    selection.each { |r| 
      r.x += dx
      r.y += dy
    }
    update_exits(selection)
    draw
  end

  #
  # Move through an exit into another room.  If exit is empty, create
  # a new neighboring room.
  #
  def move_thru(idx)
    room = current_room
    return if not room
    exit = room[idx]
    if exit
      room.selected = false
      if room == exit.roomA
	roomB = exit.roomB
	else
	roomB = exit.roomA
      end
      roomB.selected = true
      draw
    else
      return navigation_warning if @navigation
      x, y = room.x, room.y
      dx, dy = Room::DIR_TO_VECTOR[idx]
      x += dx
      y += dy
      x = 0 if x < 0
      y = 0 if y < 0
      x = @width-1  if x > @width-1
      y = @height-1 if y > @height-1
      if not @pmap.at(x).at(y).kind_of?(Room)
	room.selected = false
	roomB = new_xy_room(x * WW, y * HH)
	exitB = roomB.next_to?(room)
	if exitB and roomB.exits[exitB] == nil
	  new_connection( roomB, exitB, room )
	end
	draw
      end
    end
  end

  #
  # Handle a keypress
  #
  def keypress_cb( server, sel, event)
    case event.code
    when KEY_Escape
      if @complexConnection 
	if @complexConnection.kind_of?(Array)
	  @sections[@section].delete_connection_at(-1)
	  status MSG_COMPLEX_CONNECTION_STOPPED
	  draw
	end
	@complexConnection = false
      end
    when KEY_BackSpace, KEY_Delete
      return navigation_warning if @navigation
      delete_selected
    when KEY_a
      if event.state & ALTMASK != 0
        select_all
      end
    when KEY_n
      if event.state & ALTMASK != 0
        clear_selection
        draw
      end
    when KEY_c
      if event.state & CONTROLMASK != 0
	FXMapperWindow::copy_selected(self)
	draw
      end
    when KEY_v
      if event.state & CONTROLMASK != 0
	FXMapperWindow::paste_selected(self)
	@modified = true
	draw
      end
    # when KEY_u
    #   if event.state & CONTROLMASK != 0
    #     FXMapperWindow::undo(self)
    #     @modified = true
    #     draw
    #   end
    when KEY_x
      return navigation_warning if @navigation
      if event.state & CONTROLMASK != 0
	FXMapperWindow::cut_selected(self)
	@modified = true
	draw
      else
	complex_connection
      end
    when KEY_plus
      zoom_in
    when KEY_minus
      zoom_out
    when KEY_KP_8
      move_thru(0)
    when KEY_KP_9
      move_thru(1)
    when KEY_KP_6
      move_thru(2)
    when KEY_KP_3
      move_thru(3)
    when KEY_KP_2
      move_thru(4)
    when KEY_KP_1
      move_thru(5)
    when KEY_KP_4
      move_thru(6)
    when KEY_KP_7
      move_thru(7)
    when KEY_Up
      move_to(0)
    when KEY_Down
      move_to(4)
    when KEY_Left
      move_to(6)
    when KEY_Right
      move_to(2)
    when KEY_End
      move_to(5)
    when KEY_Home
      move_to(7)
    when KEY_Page_Up
      move_to(1)
    when KEY_Page_Down
      move_to(3)
    end
  end

  #
  # Draw template of diagonal connections in grid background
  #
  def draw_diagonal_connections(dc, event)
    ww = WW * @zoom
    hh = HH * @zoom

    w = W * @zoom
    h = H * @zoom

    ws = WS * @zoom
    hs = HS * @zoom

    ws_2 = WS_2 * @zoom
    hs_2 = HS_2 * @zoom

    maxy = @height - 1
    maxx = @width  - 1

    (0...@height).each { |yy|
      (0...@width).each { |xx|
	next if @pmap.at(xx).at(yy).kind_of?(Connection)
	x = xx * ww
	y = yy * hh

	if yy < maxy and xx < maxx
	  # First, draw \
	  x1 = x + w + ws_2
	  y1 = y + h + hs_2
	  
	  x2 = x1 + ws
	  y2 = y1 + hs
	  dc.drawLine( x1, y1, x2, y2 )

	end

	if yy < maxy and xx > 0 and xx <= maxx
	  # Then, draw /
	  x1 = x + ws_2
	  y1 = y + h + hs_2

	  x2 = x1 - ws
	  y2 = y1 + hs
	  dc.drawLine( x2, y2, x1, y1 )
	end
      }
    }
  end

  #
  # Draw template of straight connections in grid background
  #
  def draw_straight_connections(dc, event)
    ww = WW * @zoom
    hh = HH * @zoom

    w = W * @zoom
    h = H * @zoom

    ws_2 = WS_2 * @zoom
    hs_2 = HS_2 * @zoom

    #---- dummy check to catch an ugly bug that I cannot track...
    create_pathmap if @pmap.size < @width or @pmap[0].size < @height

    # First, draw horizontal lines
    (0...@height).each { |yy|
      (0..@width-2).each { |xx|
	next if @pmap.at(xx).at(yy).kind_of?(Connection) or
	  @pmap.at(xx+1).at(yy).kind_of?(Connection)
	x1 =       xx * ww + w + ws_2
	x2 = (xx + 1) * ww + ws_2
    	y1 = yy * hh + h / 2 + hs_2
	
	dc.drawLine( x1, y1, x2, y1 )
      }
    }

    # Then, draw vertical lines
    (0...@width).each { |xx|
      (0..@height-2).each { |yy|
	next if @pmap.at(xx).at(yy).kind_of?(Connection) or
	  @pmap.at(xx).at(yy+1).kind_of?(Connection)
	x1 = xx * ww + w / 2 + ws_2
    	y1 =       yy * hh + h + hs_2
	y2 = (yy + 1) * hh + hs_2
	
	dc.drawLine( x1, y1, x1, y2 )
      }
    }
  end



  #
  # Draw template of room squares in background
  #
  def draw_grid(dc, event = nil)

    dc.foreground = "black"
    dc.lineWidth  = 0
    dc.lineStyle  = LINE_ONOFF_DASH

    ww = WW * @zoom
    hh = HH * @zoom

    w = W * @zoom
    h = H * @zoom

    ws_2 = WS_2 * @zoom
    hs_2 = HS_2 * @zoom

    (0...@width).each { |xx|
      (0...@height).each { |yy|
	next if @pmap.at(xx).at(yy)
	x = xx * ww + ws_2
    	y = yy * hh + hs_2
	dc.drawRectangle( x, y, w, h )
      }
    }
  end

  #
  # Clean background to solid color
  #
  def draw_background(dc, event = nil)
    dc.foreground = @options['BG Color']
    dc.fillRectangle(0,0, @canvas.width, @canvas.height)
  end

  #
  # Draw connections among rooms
  #
  def draw_connections(dc)
    dc.lineStyle = LINE_SOLID
    dc.lineWidth = 3 * @zoom
    dc.lineWidth = 3 if dc.lineWidth < 3
    @sections[@section].connections.each { |c| c.draw(dc, @zoom, @options) }
  end

  #
  # Draw a single room (callback used when editing room dialog box)
  #
  def draw_room(room)
    idx = @sections[@section].rooms.index(room)
    return unless idx

    dc = FXDCWindow.new(@canvas)
    dc.font = @font
    data = { }
    data['font']    = @font
    data['objfont'] = @objfont
    room.draw(dc, @zoom, idx, @options, data)
    dc.end
  end

  #
  # Draw all rooms in current section
  #
  def draw_rooms(dc)
    data = { }
    data['font']    = @font
    data['objfont'] = @objfont
    @sections[@section].rooms.each_with_index { |room, idx| 
      room.draw(dc, @zoom, idx, @options, data) 
    }
  end

  #
  # Draw mapname
  #
  def draw_mapname(dc)
    fontsize = (24 * @zoom).to_i
    font = FXFont.new(@window.getApp, @options['Font Text'], fontsize)
    font.create

    x = @width * WW / 2.0 - @name.size * 24
    dc.drawText(x, 30, @name)
  end

  #
  # Print map
  #
  def print(printer)
    # dc = FXDCPrint.new(@window.getApp)
    require 'IFMapper/MapPrinting'
    require 'IFMapper/FXDCPostscript'
    oldzoom = @zoom
    oldsection = @section
    self.zoom = 1.0

    num = pack_sections( @width, @height )
    begin
      dc = FXDCPostscript.new(@window.getApp)
      xmax = @width  * WW
      ymax = @height * HH
      dc.setContentRange(0, 0, xmax, ymax)
      dc.beginPrint(printer) {
	page = -1
	0.upto(@sections.size-1) { |p|
	  self.section = p
	  clear_selection
	  if page != sect.page
	    dc.beginPage(sect.page)
	    draw_mapname( dc )
	  end

	  dc.lineCap = CAP_ROUND
	  # draw_grid(dc)
	  draw_connections(dc)
	  draw_rooms(dc)

	  if page != sect.page
	    page = sect.page
	    dc.endPage()
	  end
	}
      }
    rescue => e
      status "#{e}"
    end
    self.section = oldsection
    self.zoom = oldzoom
    draw
  end


  #
  # Draw map
  #
  def draw(sender = nil, sel = nil, event = nil)
    return if @mutex.locked? or not @canvas.created?

    if not @image.created?
      # puts "Image was not created.  Try again"
      self.zoom = @zoom 
    end

    pos = @scrollwindow.position
    w   = @scrollwindow.getViewportWidth
    h   = @scrollwindow.getViewportHeight

    # The -5 seems to be a bug in fox.  don't ask me.
    cx  = -pos[0]-5
    cx  = 0 if cx < 0
    cy  = -pos[1]-5
    cy  = 0 if cy < 0

    dc = FXDCWindow.new(@image)
    dc.setClipRectangle( cx, cy, w, h)
    dc.font = @font
    #dc.lineCap = CAP_ROUND
    draw_background(dc, event)
    draw_grid(dc, event) if @options['Grid Boxes']
    if @options['Grid Straight Connections']
      draw_straight_connections(dc, event)
    end
    if @options['Grid Diagonal Connections']
      draw_diagonal_connections(dc, event)
    end
    draw_connections(dc)
    draw_rooms(dc)
    dc.end
    

    # Blit the off-screen image into canvas
    dc = FXDCWindow.new(@canvas)
    dc.setClipRectangle( cx, cy, w, h)
    dc.drawImage(@image,0,0)
    dc.end

  end


  #
  # Perform the actual saving of the map
  #
  def _save
    if @complexConnection
      # If we have an incomplete connection, remove it
      @sections[@section].delete_connection_at(-1)
    end

    if @filename !~ /\.map$/i
      @filename << '.map'
    end

    status "#{MSG_SAVING} '#{@filename}'..."

    # Make sure we save a valid map.  This is mainly a fail-safe
    # in case of an autosave due to a bug.
    verify_integrity

    @version = FILE_FORMAT_VERSION
    begin
      f = File.open(@filename, "wb")
      f.puts Marshal.dump(self)
      f.close
    rescue => e
      status "#{ERR_COULD_NOT_SAVE} '#{@filename}': #{e}"
      sleep 4
      return false
    end
    @modified = false
    status "#{MSG_SAVED} '#{@filename}'."
    sleep 0.5
    return true
  end

  #
  # Save the map.  If the map's filename is not defined, call save_as
  #
  def save
    unless @filename
      save_as
    else
      _save
    end
  end


  #
  # Export map as an IFM map file
  #
  def export_ifm(file)
    require 'IFMapper/IFMWriter'
    file += '.ifm' if file !~ /\.ifm$/
    IFMWriter.new(self, file)
  end


  #
  # Export map as a set of TADS3 source code files
  #
  def export_tads(file)
    require 'IFMapper/TADSWriter'
    file.sub!(/(-\d+)?\.t/, '')
    TADSWriter.new(self, file)
  end

  #
  # Export map as a set of Inform source code files
  #
  def export_inform7(file)
    require 'IFMapper/Inform7Writer'
    file.sub!(/\.inform$/, '')
    Inform7Writer.new(self, file)
  end

  #
  # Export map as a set of Inform source code files
  #
  def export_trizbort(file)
    require 'IFMapper/TrizbortWriter'
    file.sub!(/\.trizbort$/, '')
    TrizbortWriter.new(self, file)
  end

  #
  # Export map as a set of Inform source code files
  #
  def export_inform(file, version = 6)
    if file =~ /\.inform$/ or version > 6
      return export_inform7(file)
    end

    require 'IFMapper/InformWriter'
    file.sub!(/(-\d+)?\.inf/, '')
    InformWriter.new(self, file)
  end

  #
  # Save the map under a new filename, bringing up a file requester
  #
  def save_as
    require 'IFMapper/FXMapFileDialog'
    file = FXMapFileDialog.new(@window, "#{MSG_SAVE_MAP} #{@name}",
			       FXMapFileDialog::KNOWN_SAVE_EXTENSIONS).filename
    if file != ''
      if File.exists?(file)
	dlg = FXWarningBox.new(@window, "#{file}\n#{WARN_OVERWRITE_MAP}")
	return if dlg.execute == 0
      end

      case file
      when /\.inform$/, /\.inf$/
	export_inform(file)
      when /\.ifm$/
	export_ifm(file)
      when /\.t$/
	export_tads(file)
      when /\.trizbort$/
        export_trizbort(file)
      else
	@filename = file
	return _save
      end
    end
    return false
  end

  #
  # Open the map's property window
  #
  def properties
    if not @@win
      @@win = FXMapDialogBox.new(@window)
    end
    @@win.copy_from(self)
    @@win.show
  end

  def stop_automap
    return unless @automap
    @automap.destroy
    @automap = nil
    GC.start
    update_title
  end

  def start_automap
    if @automap
      stop_automap
    end
    require 'IFMapper/FXMapFileDialog'
    file = FXMapFileDialog.new(@window, MSG_LOAD_TRANSCRIPT, 
			       [
				 EXT_TRANSCRIPT,
				 EXT_ALL_FILES
			       ]).filename
    return if file == ''
    require 'IFMapper/TranscriptReader'

    begin
      @automap = TranscriptReader.new(self, file)
      @automap.properties(true)
      @automap.start
    rescue Errno::EACCES, Errno::ENOENT => e
      dlg = FXWarningBox.new(@window, "#{ERR_CANNOT_OPEN_TRANSCRIPT}\n#{e}")
      dlg.execute
      return
    rescue => e
      puts e.backtrace
      dlg = FXWarningBox.new(@window, "#{ERR_PARSE_TRANSCRIPT}\n#{e}\n#{e.backtrace}")
      dlg.execute
      raise
    end
    create_pathmap
    draw
    update_title
  end

end
