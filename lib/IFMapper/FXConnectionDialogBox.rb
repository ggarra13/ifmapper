
#
# Class used to display a connection dialog box
#
class FXConnectionDialogBox < FXDialogBox


  TYPE_NUM = [
    Connection::FREE,        # free
    Connection::CLOSED_DOOR, # door
    Connection::LOCKED_DOOR, # locked
    Connection::SPECIAL,     # special
  ]


  attr_writer :map

  def copy_to()
    @conn.dir       = @dir.currentNo
    @conn.type      = TYPE_NUM[ @type.currentNo ]
    @conn.exitAtext = @exitA.currentNo
    @conn.exitBtext = @exitB.currentNo

    @map.draw
  end


  def copy_from(conn)
    title = conn.to_s
    self.title = title

    @dir.currentNo   = conn.dir
    @type.currentNo  = TYPE_NUM.index(conn.type) || 0
    @exitA.currentNo = conn.exitAtext
    @exitB.currentNo = conn.exitBtext
    @conn = conn

    if @map.navigation
      @dir.disable
      @type.disable
      @exitA.disable
      @exitB.disable
    else
      @dir.enable
      @type.enable
      @exitA.enable
      @exitB.enable
    end
    if conn.loop? or conn.stub?
      @type.disable
      @dir.disable
      @exitB.disable
    end
  end

  def initialize(map, conn, event = nil)
    pos = [40, 40]
    if event
      pos  = [ event.last_x, event.last_y ]
    end
    maxW = map.window.width  - 390
    maxH = map.window.height - 300
    pos[0] = maxW if pos[0] > maxW
    pos[1] = maxH if pos[1] > maxH
    
    decor = DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE
    super( map.window, '', decor, pos[0], pos[1], 0, 0 )
    mainFrame = FXVerticalFrame.new(self,
				    FRAME_SUNKEN|FRAME_THICK|
				    LAYOUT_FILL_X|LAYOUT_FILL_Y)

    frame = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

    FXLabel.new(frame, BOX_CONNECTION_TYPE, nil, 0, LAYOUT_FILL_X)
    pane = FXPopup.new(self)
    BOX_CONNECTION_TYPE_TEXT.each { |t|
      FXOption.new(pane, t, nil, nil, 0, JUSTIFY_HZ_APART|ICON_AFTER_TEXT)
    }
    @type = FXOptionMenu.new(frame, pane, FRAME_RAISED|FRAME_THICK|
			     JUSTIFY_HZ_APART|ICON_AFTER_TEXT|
			     LAYOUT_CENTER_X|LAYOUT_CENTER_Y)


    FXLabel.new(frame, BOX_DIRECTION, nil, 0, LAYOUT_FILL_X)
    pane = FXPopup.new(self)
    BOX_DIR_TEXT.each { |t|
      FXOption.new(pane, t, nil, nil, 0, JUSTIFY_HZ_APART|ICON_AFTER_TEXT)
    }
    @dir = FXOptionMenu.new(frame, pane, FRAME_RAISED|FRAME_THICK|
			    JUSTIFY_HZ_APART|ICON_AFTER_TEXT|
			    LAYOUT_CENTER_X|LAYOUT_CENTER_Y)

    frame = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
    FXLabel.new(frame, BOX_EXIT_A_TEXT, nil, 0, LAYOUT_FILL_X)
    pane = FXPopup.new(self)
    BOX_EXIT_TEXT.each { |t|
      FXOption.new(pane, t, nil, nil, 0, JUSTIFY_HZ_APART|ICON_AFTER_TEXT)
    }
    @exitA = FXOptionMenu.new(frame, pane, FRAME_RAISED|FRAME_THICK|
			      JUSTIFY_HZ_APART|ICON_AFTER_TEXT|
			      LAYOUT_CENTER_X|LAYOUT_CENTER_Y)
    FXLabel.new(frame, BOX_EXIT_B_TEXT, nil, 0, LAYOUT_FILL_X)
    pane = FXPopup.new(self)
    BOX_EXIT_TEXT.each { |t|
      FXOption.new(pane, t, nil, nil, 0, JUSTIFY_HZ_APART|ICON_AFTER_TEXT)
    }
    @exitB = FXOptionMenu.new(frame, pane, FRAME_RAISED|FRAME_THICK|
			      JUSTIFY_HZ_APART|ICON_AFTER_TEXT|
			      LAYOUT_CENTER_X|LAYOUT_CENTER_Y)

    @dir.connect(SEL_COMMAND) { 
      copy_to() 
      title = @conn.to_s
      self.title = title
    }
    @type.connect(SEL_COMMAND) { copy_to() }
    @exitA.connect(SEL_COMMAND) { copy_to() }
    @exitB.connect(SEL_COMMAND) { copy_to() }
    @map = map

    # We need to create the dialog box first, so we can use select text.
    create
  end
end
