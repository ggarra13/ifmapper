
require 'IFMapper/FXConnection'
require 'IFMapper/FXRoom'
require 'IFMapper/Section'

class FXSection < Section
  def new_connection( roomA, exitA, roomB, exitB = nil )
    # Verify rooms exist in section (ie. don't allow links across
    # sections)
    if not @rooms.include?(roomA)
      raise ConnectionError, "Room #{roomA} not in section #{self}"
    end
    if roomB and not @rooms.include?(roomB)
      raise ConnectionError, "Room #{roomB} not in section #{self}"
    end

    c = FXConnection.new( roomA, roomB )
    return _new_connection(c, roomA, exitA, roomB, exitB)
  end

  def new_room(x, y)
    r = FXRoom.new( x, y, MSG_NEW_LOCATION )
    return _new_room(r, x, y)
  end

  def properties(map)
    if not @win
      @win = FXSectionDialogBox.new(map)
    end
    @win.copy_from(self)
    @win.show
  end

  def initialize()
    super
    @win = nil
  end

end
