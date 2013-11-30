

#
# Class used to display a room dialog box
#
class FXRoomDialogBox < FXDialogBox

  attr_writer :map

  def copy_to()

    @room.name    = @name.text
    @room.objects = @objects.text
    @room.objects.gsub!(/[,\t]+/, "\n")
    @room.tasks = @tasks.text
    @room.darkness = (@darkness.checkState == 1)
    @room.desc = @desc.text
    @room.comment = @comment.text

    @map.draw_room(@room)
    @map.update_roomlist
  end


  def copy_from(room)
    @room                = room
    @name.text           = room.name
    @darkness.checkState = room.darkness
    @objects.text        = room.objects
    @tasks.text          = room.tasks
    @desc.text           = room.desc
    @comment.text        = room.comment

    # Select text for quick editing if it uses default location name
    @name.setCursorPos room.name.size 
    if room.name == MSG_NEW_LOCATION
      self.setFocus
      @name.selectAll
      @name.setFocus
    end
    if @map.navigation
      @name.disable
      @darkness.disable
      @objects.disable
      @tasks.disable
      @desc.disable
      @comment.disable
    else
      @name.enable
      @darkness.enable
      @objects.enable
      @tasks.enable
      @desc.enable
      @comment.enable
    end

    if @map.options['Location Tasks']
      @tasksFrame.show
    else
      @tasksFrame.hide
    end
    if @map.options['Location Description']
      @descFrame.show
    else
      @descFrame.hide
    end

    @desc.connect(SEL_CHANGED) { @room.desc = @desc.text }

    # Yuck!  Fox's packer is absolutely oblivious to hiding/showing of
    # elements, so we need to force a dummy resize so the layout is
    # recalculated.  But FUCK!  This completely fucks up the focus.
    # Fox is a piece of ****.  I **REALLY** need to go back to FLTK.
    ##  self.resize(self.defaultWidth, self.defaultHeight)
  end

  def initialize(map, room, event = nil, modal = nil)
    pos = [40, 40]
    if event
      pos  = [ event.last_x, event.last_y ]
    end
    maxW = map.window.width  - 390
    maxH = map.window.height - 300
    pos[0] = maxW if pos[0] > maxW
    pos[1] = maxH if pos[1] > maxH
    
    if modal
      decor = DECOR_TITLE|DECOR_BORDER
    else
      decor = DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE
    end

    super( map.window, BOX_ROOM_INFORMATION, decor, pos[0], pos[1], 0, 0 )
    mainFrame = FXVerticalFrame.new(self,
				    FRAME_SUNKEN|FRAME_THICK|
				    LAYOUT_FILL_X|LAYOUT_FILL_Y)

    frame = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

    FXLabel.new(frame, BOX_LOCATION, nil, 0, LAYOUT_FILL_X)
    @name = FXTextField.new(frame, 40, nil, 0, LAYOUT_FILL_ROW)


    all = FXHorizontalFrame.new(mainFrame,
				LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)

    leftFrame = FXVerticalFrame.new(all, 
				    LAYOUT_SIDE_TOP|LAYOUT_SIDE_LEFT|
				    LAYOUT_FILL_X|LAYOUT_FILL_Y)

    @darkness = FXCheckButton.new(leftFrame, BOX_DARKNESS, nil, 0,
				  ICON_BEFORE_TEXT|LAYOUT_LEFT|
				  LAYOUT_SIDE_RIGHT)
    @tab = FXTabBook.new(leftFrame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|
                         LAYOUT_LEFT)
    
    FXTabItem.new(@tab, BOX_OBJECTS, nil, 0, LAYOUT_FILL_X)
    boxFrame = FXHorizontalFrame.new(@tab, FRAME_THICK|FRAME_RAISED)
    @objects = FXText.new(boxFrame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @objects.visibleRows = 8
    @objects.visibleColumns = 40

    @tasksFrame = FXTabItem.new(@tab, BOX_TASKS, nil)
    frame = FXHorizontalFrame.new(@tab, FRAME_THICK|FRAME_RAISED)
    @tasks = FXText.new(frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @tasks.visibleRows = 8
    @tasks.visibleColumns = 40

    FXTabItem.new(@tab, BOX_COMMENTS, nil)
    @commentFrame = FXHorizontalFrame.new(@tab, FRAME_THICK|FRAME_RAISED)
    @comment = FXText.new(@commentFrame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @comment.visibleRows = 8
    @comment.visibleColumns = 40

    ######## Add description
    @descFrame = FXTabItem.new(@tab, BOX_DESCRIPTION, nil)
    frame = FXVerticalFrame.new(@tab, FRAME_THICK|FRAME_RAISED)
    @desc = FXText.new(frame, nil, 0, 
		       LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
    @desc.visibleColumns = 70
    @desc.visibleRows = 18


    if modal
      buttons = FXHorizontalFrame.new(mainFrame, 
				      LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|
				      PACK_UNIFORM_WIDTH)
      # Accept
      @ok = FXButton.new(buttons, BUTTON_ACCEPT, nil, self, 
			 FXDialogBox::ID_ACCEPT,
			 FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
      
      # Cancel
      FXButton.new(buttons, BUTTON_CANCEL, nil, self, 
                   FXDialogBox::ID_CANCEL,
                   FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
    else
      @name.connect(SEL_CHANGED) { copy_to() }
      @objects.connect(SEL_CHANGED) { copy_to()}
      @tasks.connect(SEL_CHANGED) { @room.tasks = @tasks.text }
      @darkness.connect(SEL_COMMAND) { copy_to() }
      @desc.connect(SEL_CHANGED) { @room.desc = @desc.text }
      @comment.connect(SEL_CHANGED) { @room.comment = @comment.text }
    end
    
    @map = map

    # We need to create the dialog box first, so we can use select text.
    create
  end
end
