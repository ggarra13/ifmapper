
require 'IFMapper/FXSpline'
require 'IFMapper/Connection'
require 'IFMapper/FXConnectionDialogBox'

######################################################
#
#               WW
#    +---------------------+
#    |         W           |
#    |   +-------------+   |
# HH |   |             |WS2|
#    | HS |             |---|
#    |   +-------------+   |
#    |       |HS2          |
#    +---------------------+
#
#####################################################

W  = 120
H  = 75
WS = 40
HS = 40
WW = W+WS
HH = H+HS

WS_2 = WS / 2
HS_2 = HS / 2

WIDX = 24
HIDX = 18


class FXConnection < Connection
  attr_reader   :selected
  attr_accessor :failed
  attr_accessor :pts, :gpts

  @@win = nil

  def self.no_maps
    @@win.hide if @@win
  end

  def initialize( roomA, roomB, dir = Connection::BOTH, 
		 type = Connection::FREE )
    super( roomA, roomB, dir, type )
    @selected  = @failed = false
    @pts = @gpts = []
  end

  def marshal_load(vars)
    @pts = @gpts = []
    @selected = vars.shift
    @failed = false
    super(vars)
  end

  def marshal_dump
    [ @selected ] + super
  end

  def flip
    super
    pts.reverse!
    gpts.reverse!
    @@win.copy_from(self) if @@win
  end

  #
  # Change selection state of connection.  If Connection Properties
  # window is open, copy the connection data to it.
  #
  def selected=(value)
    @@win.copy_from(self) if value and @@win and @@win.shown?
    @selected = value
  end

  #
  # Change direction of connection
  #
  def toggle_direction
    # If a self-loop, we cannot change dir
    return if @room[0] == @room[1] and
      @room[0].exits.index(self) == @room[0].exits.rindex(self)

    @dir ^= 1
    @@win.copy_from(self) if @@win
  end

  #
  # Is this a complex path.  Check if connection is
  # contiguous
  #
  def complex?()
    return false if not @room[1]
    return true if @room[1] == @room[0]
    return true unless @room[0].next_to?(@room[1])

    # Even if rooms are next to each other, we need to
    # verify that following the exits does indeed take us to next room.
    exitA = @room[0].exits.index(self)
    dir   = Room::DIR_TO_VECTOR[exitA]

    if @room[0].x + dir[0] == @room[1].x and
	@room[0].y + dir[1] == @room[1].y
      exitB = @room[1].exits.rindex(self)
      dir   = Room::DIR_TO_VECTOR[exitB]
      if @room[1].x + dir[0] == @room[0].x and
	  @room[1].y + dir[1] == @room[0].y
	return false
      else
	return true
      end
    else 
      return true
    end
  end

  #
  # Main draw function
  #
  def draw(dc, zoom, opt)
    if @selected
      if @failed
        dc.foreground = 'cyan'
      else
        dc.foreground = 'yellow'
      end
    elsif @failed
      dc.foreground = 'red'
    else
      dc.foreground = opt['Arrow Color']
    end

    draw_exit_text(dc, zoom)
    if @type == SPECIAL
      dc.lineStyle = LINE_ONOFF_DASH
    else
      dc.lineStyle = LINE_SOLID
    end
    if pts.size > 0
      draw_complex(dc, zoom, opt)
    else
      draw_simple(dc, zoom)
    end
  end


  def update_properties(map)
    return if not @@win or not @@win.shown?
    @@win.map = map
    @@win.copy_from(self)
  end

  def properties(map, event = nil)
    if not @@win
      @@win = FXConnectionDialogBox.new(map, self, event)
    end
    @@win.show
    update_properties(map)
  end

  protected

  RAD_45 = 45 * Math::PI / 180
  SIN_45 = Math.sin(RAD_45)
  COS_45 = Math.cos(RAD_45)

  def _arrow_info( x1, y1, x2, y2, zoom = 1.0 )
    pt1  = []
    dir  = 0
    dir  = @room[1].exits.rindex(self)
    pt1  = [ x2, y2 ]
    x, y = Room::DIR_TO_VECTOR[dir]
    if @room[0] == @room[1]
      size = 15.0
    else
      size = 20.0
    end
    arrow_len = size / Math.sqrt(x * x + y * y)
    x *= arrow_len *  zoom
    y *= arrow_len * -zoom

    d = [
      x * COS_45 + y * SIN_45,
      x * SIN_45 - y * COS_45
    ]
    return pt1, d
  end


  #
  # Draw a complex connection as a line path
  #
  def draw_complex_as_lines(dc, zoom)
    p = []
    @pts.each { |pt|
      p << FXPoint.new( (pt[0] * zoom).to_i, (pt[1] * zoom).to_i )
    }
    dc.drawLines( p )
    return p
  end

  #
  # Draw a complex connection as a bspline path
  #
  def draw_complex_as_bspline(dc, zoom)
    p = []
    p << [ @pts[0][0] * zoom, @pts[0][1] * zoom ]
    p << p[0]
    p << p[0]
    @pts.each { |pt|
      p << [ pt[0] * zoom, pt[1] * zoom ]
    }
    p << p[-1]
    p << p[-1]
    p << p[-1]
    return drawBSpline( dc, p )
  end

  #
  # Draw a door
  #
  def draw_door(dc, zoom, x1, y1, x2, y2)
    v = [ (x2-x1), (y2-y1) ]
    t = 10 * zoom / Math.sqrt(v[0]*v[0]+v[1]*v[1])
    v = [ (v[0]*t).to_i, (v[1]*t).to_i ]
    m = [ (x2+x1)/2, (y2+y1)/2 ]
    x1, y1 = [m[0] + v[1], m[1] - v[0]]
    x2, y2 = [m[0] - v[1], m[1] + v[0]]
    if @type == LOCKED_DOOR
      # Locked door
      dc.drawLine(x1, y1, x2, y2)
    else
      # open door
      v = [ v[0] / 3, v[1] / 3]
      x1, y1 = x1.to_i, y1.to_i
      x2, y2 = x2.to_i, y2.to_i
      pts = []
      pts << FXPoint.new(x1 - v[0], y1 - v[1])
      pts << FXPoint.new(x1 + v[0], y1 + v[1])
      pts << FXPoint.new(x2 + v[0], y2 + v[1])
      pts << FXPoint.new(x2 - v[0], y2 - v[1])
      pts << pts[0]
      width = dc.lineWidth
      dc.lineWidth = 0
      dc.drawLines(pts)
      dc.lineWidth = width
    end
  end

  #
  # Draw a complex connection
  #
  def draw_complex(dc, zoom, opt)
    if opt['Paths as Curves']
      if @room[0] == @room[1]
	dirA, dirB = dirs
	if dirA == dirB
	  p = draw_complex_as_lines(dc, zoom)
	else
	  p = draw_complex_as_bspline(dc, zoom)
	end
      else
	p = draw_complex_as_bspline(dc, zoom)
      end
    else
      p = draw_complex_as_lines(dc, zoom)
    end

    x1, y1 = [p[0].x, p[0].y]
    x2, y2 = [p[-1].x, p[-1].y]
    draw_arrow(dc, zoom, x1, y1, x2, y2)

    if @type == LOCKED_DOOR or @type == CLOSED_DOOR
      t = p.size / 2
      x1, y1 = [ p[t].x, p[t].y ]
      x2, y2 = [ p[t-2].x, p[t-2].y ]
      draw_door(dc, zoom, x1, y1, x2, y2)
    end
  end

  #
  # Draw a simple connection.  Simple connections are straight
  # line connections or 'stub' connections.
  #
  def draw_simple(dc, zoom)
    dir    = @room[0].exits.index(self)
    x1, y1 = @room[0].corner(self, zoom, dir)
    if @room[1]
      x2, y2 = @room[1].corner(self, zoom)
      dc.drawLine( x1, y1, x2, y2 )
      draw_arrow(dc, zoom, x1, y1, x2, y2)
      if @type == LOCKED_DOOR or @type == CLOSED_DOOR
	draw_door(dc, zoom, x1, y1, x2, y2)
      end
    else
      # Complex connection in progress or "stub" exit
      v = FXRoom::DIR_TO_VECTOR[dir]
      x2, y2 = [ x1 + v[0] * WS * zoom * 0.4, y1 + v[1] * HS * zoom * 0.4 ]
      dc.drawLine( x1, y1, x2, y2 )
    end
  end


  #
  # Draw an arrow at one end of the path
  #
  def draw_arrow( dc, zoom, x1, y1, x2, y2 )
    return if @dir == BOTH
    pt1, d = _arrow_info( x1, y1, x2, y2, zoom )

    p = []
    p << FXPoint.new( pt1[0].to_i, pt1[1].to_i )
    pt2 = [ pt1[0] + d[0], pt1[1] + d[1] ]
    p << FXPoint.new( pt2[0].to_i, pt2[1].to_i )
    pt2 = [ pt1[0] + d[1], pt1[1] - d[0] ]
    p << FXPoint.new( pt2[0].to_i, pt2[1].to_i )
    
    dc.fillPolygon(p)
  end

  #
  # Draw the connection text next to the arrow ('I', 'O', etc)
  #
  def draw_text(dc, zoom, x, y, dir, text, arrow)
    if dir == 7 or dir < 6 and dir != 1
      if arrow and (dir == 0 or dir == 4)
	x += 10 * zoom
      end
      x += 5 * zoom
    elsif dir == 6 or dir == 1
      x -= 15 * zoom
    end
    
    if dir > 5 or dir < 4
      if arrow and (dir == 6 or dir == 2)
	y -= 10 * zoom
      end
      y -= 5 * zoom
    elsif dir == 4 or dir == 5
      y += 15 * zoom
    end
    
    dc.drawText(x, y, text)
  end

  #
  # Draw any exit text if available (exit text is 'U', 'D', 'I', 'O', etc)
  #
  def draw_exit_text(dc, zoom)
    return if zoom < 0.5
    if @exitText[0] != 0
      dir  = @room[0].exits.index(self)
      x, y = @room[0].corner(self, zoom, dir)
      draw_text( dc, zoom, x, y, dir, 
		DRAW_EXIT_TEXT[@exitText[0]], nil )
    end
    if @exitText[1] != 0
      dir  = @room[1].exits.rindex(self)
      x, y = @room[1].corner(self, zoom, dir)
      draw_text( dc, zoom, x, y, dir, 
		DRAW_EXIT_TEXT[@exitText[1]], @dir == AtoB)
    end
  end

end

