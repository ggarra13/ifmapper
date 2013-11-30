class FXSVGMapExporterOptionsDialogBox < FXDialogBox

  def initialize(parent, title, map)
        
    decor = DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE

    super( parent, title, decor, 40, 40, 0, 0 )
    mainFrame = FXVerticalFrame.new(self,
                    FRAME_SUNKEN|FRAME_THICK|
                    LAYOUT_FILL_X|LAYOUT_FILL_Y)

    @locationnos = FXCheckButton.new(mainFrame, BOX_SVG_LOCATIONNOS, nil, 0,
                  ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|
                  LAYOUT_SIDE_RIGHT)
    @locationnos.setCheck(true)
    map.options['print_room_nums'] = true

    @interactive = FXCheckButton.new(mainFrame, BOX_SVG_INTERACTIVE, nil, 0,
                  ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|
                  LAYOUT_SIDE_RIGHT)
    @interactive.setCheck(true)
    map.options['draw_interactive'] = true
    
    @connections = FXCheckButton.new(mainFrame, BOX_SVG_CONNECTIONS, nil, 0,
            ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|
            LAYOUT_SIDE_RIGHT)
    @connections.setCheck(true)
    map.options['draw_connections'] = true

    @roomnames = FXCheckButton.new(mainFrame, BOX_SVG_ROOMNAMES, nil, 0,
            ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|
            LAYOUT_SIDE_RIGHT)
    @roomnames.setCheck(true)
    map.options['draw_roomnames'] = true
    
    @sectioncomments = FXCheckButton.new(mainFrame, BOX_SVG_SECTIONCOMMENTS, nil, 0,
            ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|
            LAYOUT_SIDE_RIGHT)
    @sectioncomments.setCheck(true)
    map.options['draw_sectioncomments'] = true
    
    @splitsections = FXCheckButton.new(mainFrame, BOX_SVG_SPLITSECTIONS, nil, 0,
            ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|
            LAYOUT_SIDE_RIGHT)
    @splitsections.setCheck(false)
    map.options['split_sections'] = false
  
    compassframe = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
    FXLabel.new(compassframe, BOX_SVG_COMPASS_SIZE, nil, 0, LAYOUT_SIDE_RIGHT)
    @compasssize = FXSlider.new(compassframe, nil, 0, 
                  SLIDER_HORIZONTAL|LAYOUT_FIX_WIDTH|
                  SLIDER_TICKS_TOP|LAYOUT_SIDE_TOP|LAYOUT_SIDE_RIGHT,
                  :width => 100)
    @compasssize.range = (0..15)
    @compasssize.value = 3
    map.options['compass_size'] = 3
  
    thicknessframe = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
    FXLabel.new(thicknessframe, BOX_SVG_LINE_THICKNESS, nil, 0, LAYOUT_SIDE_RIGHT)
    @linethickness = FXSlider.new(thicknessframe, nil, 0, 
                  SLIDER_HORIZONTAL|LAYOUT_FIX_WIDTH|
                  SLIDER_TICKS_TOP|LAYOUT_SIDE_TOP|LAYOUT_SIDE_RIGHT,
                  :width => 100)
    @linethickness.range = (1..5)
    @linethickness.value = 2
    map.options['room_line_width'] = 2
    map.options['conn_line_width'] = 2
    map.options['door_line_width'] = 2
    
    colourframe = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
    
    FXLabel.new(colourframe, BOX_SVG_COLOUR_SCHEME, nil, 0, LAYOUT_FILL_X)
    pane = FXPopup.new(self)
    BOX_SVG_COLOUR_SCHEME_TEXT.each { |t|
      FXOption.new(pane, t, nil, nil, 0, JUSTIFY_HZ_APART|ICON_AFTER_TEXT)
    }
    @colourscheme = FXOptionMenu.new(colourframe, pane, FRAME_RAISED|FRAME_THICK|
                JUSTIFY_HZ_APART|ICON_AFTER_TEXT|
                LAYOUT_CENTER_X|LAYOUT_CENTER_Y|LAYOUT_FIX_WIDTH, :width => 100)
    @colourscheme.currentNo = 1
    map.options['objs_fill_colour'] = "lightgreen"
    map.options['corner_fill_colour'] = "lightgreen"
    map.options['num_fill_colour'] = "lightgreen"
    map.options['door_line_colour'] = "forestgreen"
    
                
    buttons = FXHorizontalFrame.new(mainFrame, 
                    LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|
                    PACK_UNIFORM_WIDTH)

    @locationnos.connect(SEL_COMMAND) { 
        map.options['print_room_nums'] = (@locationnos.check == true)
    }
    @interactive.connect(SEL_COMMAND) {
        map.options['draw_interactive'] = (@interactive.check == true)
    }
    @connections.connect(SEL_COMMAND) {
        map.options['draw_connections'] = (@connections.check == true)
    }
    @roomnames.connect(SEL_COMMAND) {
        map.options['draw_roomnames'] = (@roomnames.check == true)
    }
    @sectioncomments.connect(SEL_COMMAND) {
        map.options['draw_sectioncomments'] = (@sectioncomments.check == true)
    }
    @splitsections.connect(SEL_COMMAND) {
        map.options['split_sections'] = (@splitsections.check == true)
    }
    @linethickness.connect(SEL_COMMAND) {
        map.options['room_line_width'] = (@linethickness.value)
        map.options['conn_line_width'] = (@linethickness.value)
        map.options['door_line_width'] = (@linethickness.value)
    }
    @compasssize.connect(SEL_COMMAND) {
        map.options['compass_size'] = (@compasssize.value)
    }
    
    @colourscheme.connect(SEL_COMMAND) {
        case @colourscheme.currentNo
            when 0
                map.options['objs_fill_colour'] = "lightpink"
                map.options['corner_fill_colour'] = "lightpink"
                map.options['num_fill_colour'] = "lightpink"
                map.options['door_line_colour'] = "firebrick"
            when 1
                map.options['objs_fill_colour'] = "lightgreen"
                map.options['corner_fill_colour'] = "lightgreen"
                map.options['num_fill_colour'] = "lightgreen"
                map.options['door_line_colour'] = "forestgreen"
            when 2
                map.options['objs_fill_colour'] = "yellow"
                map.options['corner_fill_colour'] = "yellow"
                map.options['num_fill_colour'] = "yellow"
                map.options['door_line_colour'] = "goldenrod"            
            when 3
                map.options['objs_fill_colour'] = "lightblue"
                map.options['corner_fill_colour'] = "lightblue"
                map.options['num_fill_colour'] = "lightblue"
                map.options['door_line_colour'] = "darkslateblue"
        end
    }
    
    # Accept
    FXButton.new(buttons, "&OK", nil, self, FXDialogBox::ID_ACCEPT,
         FRAME_RAISED|LAYOUT_FILL_X|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)

    create
    
  end
end
