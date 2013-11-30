

class FXMapDialogBox < FXDialogBox

  def copy_to()
    @map.name       = @name.text
    @map.creator    = @creator.text
    @map.navigation = (@read.checkState == 1)

    if @map.navigation
      @name.disable
      @creator.disable
      @width.disable
      @height.disable
    else
      @name.enable
      @creator.enable
      @width.enable
      @height.enable
    end

    w = @width.text.to_i
    h = @height.text.to_i

    @map.update_title

    if w != @map.width or h != @map.height
      if w < @map.width or h < @map.height
	rooms = []
	@map.sections.each { |s|
	  s.rooms.each { |r|
	    if r.x >= w or r.y >= h
	      rooms << [s, r]
	    end
	  }
	}
	if not rooms.empty?
	  d = FXWarningBox.new(@map.window, WARN_MAP_SMALL)
	  if d.execute == 0
	    copy_from(@map)
	    return
	  end
	  rooms.each { |p| 
	    p[0].delete_room(p[1])
	  }
	end
      end
      @map.width      = w
      @map.height     = h
      @map.zoom       = @map.zoom
      @map.create_pathmap
      @map.draw
    end

  end

  def copy_from(map)
    @name.text       = map.name
    @creator.text    = map.creator
    @read.checkState = map.navigation
    @width.text      = map.width.to_s
    @height.text     = map.height.to_s
    if map.navigation
      @name.disable
      @creator.disable
      @width.disable
      @height.disable
    else
      @name.enable
      @creator.enable
      @width.enable
      @height.enable
    end
    @map = map
  end

  def initialize(parent)
    decor = DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE

    super( parent, BOX_MAP_INFORMATION, decor, 40, 40, 0, 0 )
    mainFrame = FXVerticalFrame.new(self,
				    FRAME_SUNKEN|FRAME_THICK|
				    LAYOUT_FILL_X|LAYOUT_FILL_Y)

    @read = FXCheckButton.new(mainFrame, BOX_MAP_READ_ONLY, nil, 0,
			      ICON_BEFORE_TEXT|LAYOUT_LEFT|LAYOUT_SIDE_TOP|
			      LAYOUT_SIDE_RIGHT)

    frame = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

    FXLabel.new(frame, "#{BOX_NAME}:", nil, 0, LAYOUT_FILL_X)
    @name = FXTextField.new(frame, 42, nil, 0, LAYOUT_FILL_ROW)

    frame = FXHorizontalFrame.new(mainFrame, 
				  LAYOUT_FILL_X|LAYOUT_FILL_Y)

    FXLabel.new(frame, BOX_MAP_CREATOR, nil, 0, LAYOUT_FILL_X)
    @creator = FXTextField.new(frame, 40, nil, 0, LAYOUT_FILL_ROW)

    frame = FXHorizontalFrame.new(mainFrame, 
				  LAYOUT_SIDE_TOP|FRAME_SUNKEN|
				  LAYOUT_FILL_X|LAYOUT_FILL_Y)

    frame2 = FXVerticalFrame.new(frame,
				 LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y )
    FXLabel.new(frame2, BOX_MAP_WIDTH, nil, 0, LAYOUT_FILL_X)
    @width = FXTextField.new( frame2, 6, nil, 0,
			     TEXTFIELD_INTEGER|LAYOUT_FILL_ROW)

    frame2 = FXVerticalFrame.new(frame,
				 LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y )
    FXLabel.new(frame2, BOX_MAP_HEIGHT, nil, 0, LAYOUT_FILL_X)
    @height = FXTextField.new( frame2, 6, nil, 0, 
			      TEXTFIELD_INTEGER|LAYOUT_FILL_ROW)

    @name.connect(SEL_CHANGED) { copy_to() }
    @creator.connect(SEL_CHANGED) { copy_to() }
    @read.connect(SEL_COMMAND) { copy_to() }
    @width.connect(SEL_COMMAND) { copy_to() }
    @height.connect(SEL_COMMAND) { copy_to() }
    
    @parent = parent

    # We need to create the dialog box first, so we can use select text.
    create
  end
end
