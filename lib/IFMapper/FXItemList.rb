
#
# Class that lists all rooms in a map and allows you to jump to them
#
class FXItemList < FXDialogBox

  def pick(sender, sel, ptr)
    it = @box.currentItem
    name, section, room = @box.getItemData(it)

    @map.section = section - 1
    @map.clear_selection
    room.selected = true
    @map.center_view_on_room(room)
    @map.draw
  end

  def copy_from(map)
    @map = map
    sort
  end

  def sort
    it = @box.currentItem
    room = nil
    if it >= 0
      item, section, room = @box.getItemData(it)
    end

    @box.clearItems

    items = []
    @map.sections.each_with_index { |s, idx| 
      s.rooms.each { |r|
        r.objects.each_line { |i|
          i.chomp!
          next if i.empty?
          items << [i, idx+1, r ]
        }
      }
    }

    dir = @box.header.getArrowDir(0)
    if dir != MAYBE
      items = items.sort_by { |r| r[0] }
    else
      dir = @box.header.getArrowDir(1)
      if dir != MAYBE
	items = items.sort_by { |r| r[1] }
      else
        dir = @box.header.getArrowDir(2)
        if dir != MAYBE
          items = items.sort_by { |r| r[2].name }
        end
      end
    end

    if dir == Fox::TRUE
      items.reverse! 
    end

    items.each { |r|
      item = "#{r[0]}\t#{r[1]}\t#{r[2].name}"
      @box.appendItem(item, nil, nil, r)
    }

    if room
      items.each_with_index { |r, idx|
        if r[2] == room
          @box.currentItem = idx
          break
        end
      }
    end
  end

  def initialize(map)
    super(map.window.parent, BOX_LOCATIONS, DECOR_ALL, 40, 40, 420, 400)
  
    @box = FXIconList.new(self, nil, 0, 
			   ICONLIST_BROWSESELECT|
			   LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @box.appendHeader(BOX_NAME, nil, 120)
    @box.appendHeader(BOX_SECTION, nil, 60)
    @box.appendHeader(BOX_LOCATION, nil, 200)
    @box.header.connect(SEL_COMMAND) { |sender, sel, which|
      if @box.header.arrowUp?(which)
	dir = MAYBE
      elsif @box.header.arrowDown?(which)
	dir = TRUE
      else
	dir = FALSE
      end
      0.upto(2) { |idx|
        @box.header.setArrowDir(idx, MAYBE)
      }
      @box.header.setArrowDir(which, dir)
      
      sort
    }

    @box.connect(SEL_COMMAND, method(:pick))

    create
    copy_from(map)
  end

end
