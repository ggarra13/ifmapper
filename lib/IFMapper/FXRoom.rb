
require 'IFMapper/Room'
require 'IFMapper/FXRoomDialogBox'

#
# Class used to reprent an IF room
#
class FXRoom < Room
  attr_accessor :xx, :yy
  attr_reader   :selected

  @@win = nil

  def copy(b)
    self.xx = b.xx
    self.yy = b.yy
    self.selected = b.selected
    super b
  end

  def self.no_maps
    @@win.hide if @@win
  end

  def marshal_dump
    super + [ @selected ]
  end

  def marshal_load(vars)
    super(vars)
    @selected = vars[-1]
    @xx = x * WW + WS_2
    @yy = y * HH + HS_2
  end

  def initialize(x, y, *opts)
    @xx = x * WW + WS_2
    @yy = y * HH + HS_2
    @selected = false
    super(x, y, *opts)
  end

  #
  # Set a new x position for the room.  Value is in grid units.
  #
  def x=(v)
    @x  = v
    @xx = v * WW + WS_2
  end

  #
  # Set a new y position for the room.  Value is in grid units.
  #
  def y=(v)
    @y  = v
    @yy = v * HH + HS_2
  end

  #
  # Set selection.  If floating Room Properties window is open, copy
  # the room data over to it.
  #
  def selected=(value)
    if value and @@win and @@win.shown?
      @@win.copy_from(self)
    end
    @selected = value
  end

  #
  # Open a modal requester to change properties
  #
  def modal_properties(map)
    if @@win and @@win.shown?
      shown = @@win
      @@win.hide
    end
    win = FXRoomDialogBox.new(map, self, nil, true)
    win.setFocus
    win.show
    win.copy_from(self)
    if win.execute != 0
      win.copy_to()
    else
      return false
    end
    if shown
      @@win.show
    end
    return true
  end

  def update_properties(map)
    return if not @@win or not @@win.shown?
    @@win.map = map
    @@win.copy_from(self)
  end

  # Open a new requester to change room properties
  def properties( map, event = nil )
    if not @@win
      @@win = FXRoomDialogBox.new(map, self, event, false)
    end
    @@win.show
    update_properties(map)
  end

  #
  # Given a connection and/or an exit index, return the x and y offset
  # multipliers needed from the top corner of the box.
  #
  def _corner(c, idx)
    idx = @exits.index(c) unless idx
    raise "corner: #{c} not found in #{self}" unless idx
    x = y = 0
    case idx
    when 0
      x = 0.5
    when 1
      x = 1
    when 2
      x = 1
      y = 0.5
    when 3
      x = 1
      y = 1
    when 4
      x = 0.5
      y = 1
    when 5
      y = 1
    when 6
      y = 0.5
    when 7
    else
      raise "error wrong index #{idx}"
    end
    return [ x, y ]
  end


  # Given a connection belonging to a room, return draw coordinate
  # of that corner.
  def corner( c, zoom, idx = nil )
    x, y = _corner(c, idx)
    x = @xx + W * x
    y = @yy + H * y
    return [x * zoom, y * zoom]
  end

  
  #
  # Main draw function for room
  #
  def draw(dc, zoom, idx, opt, data)
    dc.font = data['objfont']
    draw_box(dc, zoom, idx, opt)
    return if zoom < 0.5
    dc.font = data['font']
    x, y = draw_name(dc, zoom)
    dc.font = data['objfont']
    draw_objects(dc, zoom, x, y)
  end


  protected

  #
  # Draw the room index number
  #
  def draw_index(dc, zoom, idx)
    x = (@xx + W  - 20 ) * zoom
    y = (@yy + HH - HS - 5 ) * zoom
    dc.drawText(x, y, (idx + 1).to_s)
  end

  #
  # Draw the 'room' and 'index' boxes
  #
  def draw_box(dc, zoom, idx, opt)
    if @selected
      dc.foreground = 'yellow'
      if @darkness
        dc.foreground = 'orange'
      end
    else
      if @darkness
	dc.foreground = opt['Box Darkness Color']
      else
	dc.foreground = opt['Box BG Color']
      end
    end

    x = @xx * zoom
    y = @yy * zoom
    w = W * zoom
    h = H * zoom
    dc.fillRectangle(x, y, w, h)


    dc.foreground = opt['Box Border Color']
    dc.lineWidth  = 2 * zoom
    dc.lineWidth  = 2 if dc.lineWidth < 2
    dc.lineStyle  = LINE_SOLID
    dc.drawRectangle(x, y, w, h)

    # Draw grey square for index
    if opt['Location Numbers'] and zoom >= 0.5
      dc.foreground = opt['Box Number Color']
      x += w # Index goes at bottom right of square
      y += h 
      w = WIDX * zoom
      h = HIDX * zoom
      x -= w
      y -= h
      dc.fillRectangle(x, y, w, h)
      
      dc.foreground = opt['Box Border Color']
      dc.drawRectangle(x, y, w, h)

      draw_index(dc, zoom, idx)
    end
  end

  #
  # Draw text line wrapping after certain length (in chars)
  #
  def draw_text_wrap(dc, x, y, zoom, maxLen, text)
    return if y > (@yy + H) * zoom
    if text.size > maxLen
      str = text
      fh  = dc.font.getFontHeight
      while str and str.size > maxLen
	idx = str.rindex(/[ -]/, maxLen)
	unless idx
	  idx = str.index(/[ -]/, maxLen)
	  idx = str.size unless idx
	end
	dc.drawText(x, y, str[0..idx])
	str = str[idx+1..-1]
	y  += fh
	str = nil if y > (@yy + H) * zoom
      end
      dc.drawText(x, y, str) if str
    else
      dc.drawText(x, y, text)
    end
    return [x, y]
  end

  #
  # Draw name of room
  #
  def draw_name(dc, zoom)
    x = (@xx + 5)  * zoom
    y = (@yy + 15) * zoom
    return draw_text_wrap( dc, x, y, zoom, 15, @name )
  end


  #
  # Draw the objects as a comma separated list
  #
  def draw_objects(dc, zoom, x, y)
    return if @objects == ''
    fh  = dc.font.getFontHeight
    y += fh
    objs = @objects.split("\n")
    objs = objs.join(', ')
    return draw_text_wrap( dc, x, y, zoom, 23, objs )
  end

end
