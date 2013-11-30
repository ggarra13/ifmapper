
#
# Class that lists all rooms in a map and allows you to jump to them
#
class FXRoomList < FXDialogBox

  def pick(sender, sel, ptr)
    item = @box.currentItem
    idx, r = @box.getItemData(item)

    @map.section = idx
    @map.clear_selection
    r.selected = true
    @map.center_view_on_room(r)
    @map.draw
  end

  def copy_from(map)
    @map = map
    sort
  end

  def sort
    item = @box.currentItem
    room = nil
    if item >= 0
      idx, room = @box.getItemData(item)
    end

    @box.clearItems

    rooms = []
    @map.sections.each_with_index { |s, i| 
      s.rooms.each { |r|
	rooms << [i, r]
      }
    }

    dir = @box.header.getArrowDir(0)
    if dir != MAYBE
      rooms = rooms.sort_by { |r| r[0] }
    else
      dir = @box.header.getArrowDir(1)
      if dir != MAYBE
	rooms = rooms.sort_by { |r| r[1].name }
      end
    end

    if dir == Fox::TRUE
      rooms.reverse! 
    end

    rooms.each { |r|
      item = "#{r[0] + 1}\t#{r[1].name}"
      @box.appendItem(item, nil, nil, r)
    }

    if room
      rooms.each_with_index { |r, i|
	if r[1] == room
	  @box.currentItem = i
	  break
	end
      }
    end
  end

  def initialize(map)
    super(map.window.parent, BOX_LOCATIONS, DECOR_ALL, 40, 40, 300, 400)
  
    @box = FXIconList.new(self, nil, 0, 
			   ICONLIST_BROWSESELECT|
			   LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @box.appendHeader(BOX_SECTION, nil, 60)
    @box.appendHeader(BOX_NAME, nil, 200)
    @box.header.connect(SEL_COMMAND) { |sender, sel, which|
      if @box.header.arrowUp?(which)
	dir = MAYBE
      elsif @box.header.arrowDown?(which)
	dir = TRUE
      else
	dir = FALSE
      end
      @box.header.setArrowDir(which, dir)
      @box.header.setArrowDir(which ^ 1, MAYBE)
      sort
    }

    @box.connect(SEL_COMMAND, method(:pick))

    create
    copy_from(map)
  end

end
