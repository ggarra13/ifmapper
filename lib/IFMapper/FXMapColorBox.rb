

class FXMapColorBox < FXDialogBox

  def copy_from(map)
    @backwell.rgba     = map.options['BG Color']
    @boxwell.rgba      = map.options['Box BG Color']
    @boxdarknesswell.rgba  = map.options['Box Darkness Color']
    @boxnumberwell.rgba    = map.options['Box Number Color']
    @boxborderwell.rgba    = map.options['Box Border Color']
    @arrowwell.rgba       = map.options['Arrow Color']
    @map = map
  end

  def copy_to(sender, id, event)
    @map.options['BG Color'] = @backwell.rgba
    @map.options['Box BG Color'] = @boxwell.rgba
    @map.options['Box Darkness Color'] = @boxdarknesswell.rgba
    @map.options['Box Number Color'] = @boxnumberwell.rgba
    @map.options['Box Border Color'] = @boxborderwell.rgba
    @map.options['Arrow Color'] = @arrowwell.rgba
    @map.draw
  end

  def initialize(parent)
    decor = DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE
    super(parent, BOX_COLOR, decor)

    # pane for the buttons
    contents = FXVerticalFrame.new(self, (FRAME_SUNKEN|LAYOUT_FILL_Y|
      LAYOUT_TOP|LAYOUT_LEFT), 0, 0, 0, 0, 10, 10, 10, 10)

    frame = FXHorizontalFrame.new(contents, (FRAME_SUNKEN|LAYOUT_FILL_X|
      LAYOUT_TOP|LAYOUT_LEFT), 0, 0, 0, 0, 10, 10, 10, 10)

    FXLabel.new(frame, BOX_BG_COLOR, nil, JUSTIFY_CENTER_X|LAYOUT_FILL_X)
    @backwell = FXColorWell.new(frame, FXColor::White,
      nil, 0, (LAYOUT_CENTER_X|LAYOUT_TOP|LAYOUT_LEFT|LAYOUT_SIDE_RIGHT|
      LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT), 0, 0, 100, 30)
    @backwell.connect(SEL_COMMAND, method(:copy_to))

    frame = FXHorizontalFrame.new(contents, (FRAME_SUNKEN|LAYOUT_FILL_X|
      LAYOUT_TOP|LAYOUT_LEFT), 0, 0, 0, 0, 10, 10, 10, 10)
    FXLabel.new(frame, BOX_ARROWS_COLOR, nil, JUSTIFY_CENTER_X|LAYOUT_FILL_X)
    @arrowwell = FXColorWell.new(frame, FXColor::White,
      nil, 0, (LAYOUT_CENTER_X|LAYOUT_TOP|LAYOUT_LEFT|LAYOUT_SIDE_RIGHT|
      LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT), 0, 0, 100, 30)
    @arrowwell.connect(SEL_COMMAND, method(:copy_to))

    frame = FXHorizontalFrame.new(contents, (FRAME_SUNKEN|LAYOUT_FILL_X|
      LAYOUT_TOP|LAYOUT_LEFT), 0, 0, 0, 0, 10, 10, 10, 10)
    FXLabel.new(frame, BOX_BOX_BG_COLOR, nil,JUSTIFY_CENTER_X|LAYOUT_FILL_X)
    @boxwell = FXColorWell.new(frame, FXColor::White,
      nil, 0, (LAYOUT_CENTER_X|LAYOUT_TOP|LAYOUT_LEFT|LAYOUT_SIDE_RIGHT|
      LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT), 0, 0, 100, 30)
    @boxwell.connect(SEL_COMMAND, method(:copy_to))

    frame = FXHorizontalFrame.new(contents, (FRAME_SUNKEN|LAYOUT_FILL_X|
      LAYOUT_TOP|LAYOUT_LEFT), 0, 0, 0, 0, 10, 10, 10, 10)
    FXLabel.new(frame, BOX_BOX_DARK_COLOR, nil,	
		JUSTIFY_CENTER_X|LAYOUT_FILL_X)
    @boxdarknesswell = FXColorWell.new(frame, FXColor::White,
      nil, 0, (LAYOUT_CENTER_X|LAYOUT_TOP|LAYOUT_LEFT|LAYOUT_SIDE_RIGHT|
      LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT), 0, 0, 100, 30)
    @boxdarknesswell.connect(SEL_COMMAND, method(:copy_to))

    frame = FXHorizontalFrame.new(contents, (FRAME_SUNKEN|LAYOUT_FILL_X|
      LAYOUT_TOP|LAYOUT_LEFT), 0, 0, 0, 0, 10, 10, 10, 10)
    FXLabel.new(frame, BOX_BOX_BORDER_COLOR, nil,
		JUSTIFY_CENTER_X|LAYOUT_FILL_X)
    @boxborderwell = FXColorWell.new(frame, FXColor::White,
      nil, 0, (LAYOUT_CENTER_X|LAYOUT_TOP|LAYOUT_LEFT|LAYOUT_SIDE_RIGHT|
      LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT), 0, 0, 100, 30)
    @boxborderwell.connect(SEL_COMMAND, method(:copy_to))

    frame = FXHorizontalFrame.new(contents, (FRAME_SUNKEN|LAYOUT_FILL_X|
      LAYOUT_TOP|LAYOUT_LEFT), 0, 0, 0, 0, 10, 10, 10, 10)
    FXLabel.new(frame, BOX_BOX_NUMBER_COLOR, nil,
		JUSTIFY_CENTER_X|LAYOUT_FILL_X)
    @boxnumberwell = FXColorWell.new(frame, FXColor::White,
      nil, 0, (LAYOUT_CENTER_X|LAYOUT_TOP|LAYOUT_LEFT|LAYOUT_SIDE_RIGHT|
      LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT), 0, 0, 100, 30)
    @boxnumberwell.connect(SEL_COMMAND, method(:copy_to))

    create
    show
  end
end
