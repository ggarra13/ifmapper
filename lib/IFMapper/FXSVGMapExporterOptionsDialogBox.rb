class FXSVGMapExporterOptionsDialogBox < FXDialogBox

  def initialize(parent, title, map)

    decor = DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE

    super( parent, title, decor, 40, 40, 0, 0 )
    mainFrame = FXVerticalFrame.new(self,
                    FRAME_SUNKEN|FRAME_THICK|
                    LAYOUT_FILL_X|LAYOUT_FILL_Y)


    # Show location text (draw_roomnames):
    # ====================================
    showlocationtext = FXCheckButton.new(mainFrame, BOX_SVG_SHOWLOCTEXT, nil, 0,
            ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|
            LAYOUT_SIDE_RIGHT)
    showlocationtext.setCheck(true)
    showlocationtext.tipText = BOX_SVG_SHOWLOCTEXT_TOOLTIP
    map.options['draw_roomnames'] = true

    showlocationtext.connect(SEL_COMMAND) {
      map.options['draw_roomnames'] = (showlocationtext.check == true)
    }


    # Show location numbers (print_room_nums):
    # ========================================
    showlocationnumbers = FXCheckButton.new(mainFrame, BOX_SVG_SHOWLOCNUMS, nil, 0,
                  ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|
                  LAYOUT_SIDE_RIGHT)
    showlocationnumbers.setCheck(true)
    showlocationnumbers.tipText = BOX_SVG_SHOWLOCNUMS_TOOLTIP
    map.options['print_room_nums'] = true

    showlocationnumbers.connect(SEL_COMMAND) {
      map.options['print_room_nums'] = (showlocationnumbers.check == true)
    }


    # Show interactive location information:
    # ======================================

    # Section title label
    showinteractivelabel = FXLabel.new(mainFrame, BOX_SVG_SHOWINTERTITLE, nil, 0, LAYOUT_FILL_X)
    showinteractivelabel.padTop = 10

    # Objects checkbox (draw_objects):
    showinteractiveobjects = FXCheckButton.new(mainFrame, BOX_SVG_SHOWINTEROBJECTS, nil, 0,
                  ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|
                  LAYOUT_SIDE_RIGHT)
    showinteractiveobjects.setCheck(true)
    showinteractiveobjects.padLeft = 20
    showinteractiveobjects.tipText = BOX_SVG_SHOWINTEROBJECTS_TOOLTIP
    map.options['draw_objects'] = true

    showinteractiveobjects.connect(SEL_COMMAND) {
      map.options['draw_objects'] = (showinteractiveobjects.check == true)
    }

    # Tasks checkbox (draw_tasks):
    showinteractivetasks = FXCheckButton.new(mainFrame, BOX_SVG_SHOWINTERTASKS, nil, 0,
                  ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|
                  LAYOUT_SIDE_RIGHT)
    showinteractivetasks.setCheck(true)
    showinteractivetasks.padLeft = 20
    showinteractivetasks.tipText = BOX_SVG_SHOWINTERTASKS_TOOLTIP
    map.options['draw_tasks'] = true

    showinteractivetasks.connect(SEL_COMMAND) {
      map.options['draw_tasks'] = (showinteractivetasks.check == true)
    }

    # Comments checkbox (draw_comments):
    showinteractivecomments = FXCheckButton.new(mainFrame, BOX_SVG_SHOWINTERCOMMENTS, nil, 0,
                  ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|
                  LAYOUT_SIDE_RIGHT)
    showinteractivecomments.setCheck(true)
    showinteractivecomments.padLeft = 20
    showinteractivecomments.tipText = BOX_SVG_SHOWINTERCOMMENTS_TOOLTIP
    map.options['draw_comments'] = true

    showinteractivecomments.connect(SEL_COMMAND) {
      map.options['draw_comments'] = (showinteractivecomments.check == true)
    }

    # Description checkbox (draw_description):
    showinteractivedescription = FXCheckButton.new(mainFrame, BOX_SVG_SHOWINTERDESCRIPTION, nil, 0,
                  ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|
                  LAYOUT_SIDE_RIGHT)
    showinteractivedescription.setCheck(true)
    showinteractivedescription.padLeft = 20
    showinteractivedescription.tipText = BOX_SVG_SHOWINTERDESCRIPTION_TOOLTIP
    map.options['draw_description'] = true

    showinteractivedescription.connect(SEL_COMMAND) {
      map.options['draw_description'] = (showinteractivedescription.check == true)
    }


    # Show section comments (draw_sectioncomments):
    # =============================================
    showsectioncomments = FXCheckButton.new(mainFrame, BOX_SVG_SHOWSECTCOMMENTS, nil, 0,
            ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|
            LAYOUT_SIDE_RIGHT)
    showsectioncomments.setCheck(true)
    showsectioncomments.tipText = BOX_SVG_SHOWSECTCOMMENTS_TOOLTIP
    showsectioncomments.padTop = 10
    showsectioncomments.padBottom = 10
    map.options['draw_sectioncomments'] = true

    showsectioncomments.connect(SEL_COMMAND) {
      map.options['draw_sectioncomments'] = (showsectioncomments.check == true)
    }


    # Compass size (compass_size):
    # =============================================

    # Horizontal frame to hold label and slider
    compasssizeframe = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

    # Compass size label
    compasssizelabel = FXLabel.new(compasssizeframe, BOX_SVG_COMPASSSIZE, nil, 0, LAYOUT_LEFT)
    compasssizelabel.tipText = BOX_SVG_COMPASSSIZE_TOOLTIP

    # Compass size slider
    compasssizeslider = FXSlider.new(compasssizeframe, nil, 0,
                  SLIDER_HORIZONTAL|LAYOUT_FIX_WIDTH|
                  SLIDER_TICKS_TOP|LAYOUT_RIGHT,
                  :width => 100)
    compasssizeslider.range = (0..15)
    compasssizeslider.value = 3
    compasssizeslider.tipText = BOX_SVG_COMPASSSIZE_TOOLTIP
    map.options['compass_size'] = 3

    compasssizeslider.connect(SEL_COMMAND) {
      map.options['compass_size'] = (compasssizeslider.value)
    }


    # Location line thickness (room_line_width):
    # =============================================

    # Horizontal frame to hold label and slider
    locationlinethicknessframe = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

    # Location line thickness label
    locationlinethicknesslabel = FXLabel.new(locationlinethicknessframe, BOX_SVG_LOCTHICKNESS, nil, 0, LAYOUT_LEFT)
    locationlinethicknesslabel.tipText = BOX_SVG_LOCTHICKNESS_TOOLTIP

    # Location line thickness slider
    locationlinethicknessslider = FXSlider.new(locationlinethicknessframe, nil, 0,
                  SLIDER_HORIZONTAL|LAYOUT_FIX_WIDTH|
                  SLIDER_TICKS_TOP|LAYOUT_RIGHT,
                  :width => 100)
    locationlinethicknessslider.range = (0..5)
    locationlinethicknessslider.value = 2
    locationlinethicknessslider.tipText = BOX_SVG_LOCTHICKNESS_TOOLTIP
    map.options['room_line_width'] = 2

    locationlinethicknessslider.connect(SEL_COMMAND) {
      if locationlinethicknessslider.value == 0
        locationlinethicknessslider.value = 1
      end
      map.options['room_line_width'] = (locationlinethicknessslider.value)
    }


    # Connection line thickness (conn_line_width, door_line_width, draw_connections):
    # ===============================================================================

    # Horizontal frame to hold label and slider
    connectionlinethicknessframe = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

    # Connection line thickness label
    connectionlinethicknesslabel = FXLabel.new(connectionlinethicknessframe, BOX_SVG_CONNTHICKNESS, nil, 0, LAYOUT_LEFT)
    connectionlinethicknesslabel.tipText = BOX_SVG_CONNTHICKNESS_TOOLTIP

    # Connection line thickness slider
    connectionlinethicknessslider = FXSlider.new(connectionlinethicknessframe, nil, 0,
                  SLIDER_HORIZONTAL|LAYOUT_FIX_WIDTH|
                  SLIDER_TICKS_TOP|LAYOUT_RIGHT,
                  :width => 100)
    connectionlinethicknessslider.range = (0..5)
    connectionlinethicknessslider.value = 2
    connectionlinethicknessslider.tipText = BOX_SVG_CONNTHICKNESS_TOOLTIP
    map.options['conn_line_width'] = 2
    map.options['door_line_width'] = 2
    map.options['draw_connections'] = true

    connectionlinethicknessslider.connect(SEL_COMMAND) {
      map.options['conn_line_width'] = (connectionlinethicknessslider.value)
      map.options['door_line_width'] = (connectionlinethicknessslider.value)
      map.options['draw_connections'] = (connectionlinethicknessslider.value > 0)
    }


    # Colour scheme (objs_fill_colour, corner_fill_colour, num_fill_colour, door_line_colour):
    # ========================================================================================

    # Horizontal frame to hold label and popup menu
    colourschemeframe = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

    # Colour scheme label
    colourschemelabel = FXLabel.new(colourschemeframe, BOX_SVG_COLOURSCHEME, nil, 0, LAYOUT_LEFT)
    colourschemelabel.tipText = BOX_SVG_COLOURSCHEME_TOOLTIP

    # Colour scheme popup
    colourschemepopup = FXPopup.new(self)
    BOX_SVG_COLOURSCHEME_OPTIONS.each { |colourschemeoption|
      FXOption.new(colourschemepopup, colourschemeoption, nil, nil, 0, JUSTIFY_HZ_APART|ICON_AFTER_TEXT)
    }

    # Colour scheme options menu
    colourschemeoptionsmenu = FXOptionMenu.new(colourschemeframe, colourschemepopup, FRAME_RAISED|FRAME_THICK|
                JUSTIFY_HZ_APART|ICON_AFTER_TEXT|LAYOUT_RIGHT|LAYOUT_FIX_WIDTH, :width => 100)
    colourschemeoptionsmenu.currentNo = 1
    colourschemeoptionsmenu.tipText = BOX_SVG_COLOURSCHEME_TOOLTIP
    map.options['objs_fill_colour'] = "lightgreen"
    map.options['corner_fill_colour'] = "lightgreen"
    map.options['num_fill_colour'] = "lightgreen"
    map.options['door_line_colour'] = "forestgreen"

    colourschemeoptionsmenu.connect(SEL_COMMAND) {
      case colourschemeoptionsmenu.currentNo
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


    # Export options radio buttons (split_sections, current_section_only, selected_elements_only):
    # ============================================================================================

    # Horiz line to separate this section
    FXHorizontalSeparator.new(mainFrame)

    # Vertical frame to hold the label and radio buttons
    exportoptionsframe = FXVerticalFrame.new(mainFrame, LAYOUT_FILL_X)

    # Data target - handles selection/deselection of radio buttons
    exportoptionsdatatarget = FXDataTarget.new(0)

    # Export label
    FXLabel.new(exportoptionsframe, "Export:")

    # Export - All combined radio button
    exportoptionsallcombined = FXRadioButton.new(exportoptionsframe, BOX_SVG_EXPORTALLCOMBINED, exportoptionsdatatarget, FXDataTarget::ID_OPTION)
    exportoptionsallcombined.tipText = BOX_SVG_EXPORTALLCOMBINED_TOOLTIP

    # Export - All individual files radio button
    exportoptionsallindividual = FXRadioButton.new(exportoptionsframe, BOX_SVG_EXPORTALLINDIV, exportoptionsdatatarget, FXDataTarget::ID_OPTION+1)
    exportoptionsallindividual.tipText = BOX_SVG_EXPORTALLINDIV_TOOLTIP

    # Export - Current individual file radio button
    exportoptionscurrentindividual = FXRadioButton.new(exportoptionsframe, BOX_SVG_EXPORTCURRENTINDIV, exportoptionsdatatarget, FXDataTarget::ID_OPTION+2)
    exportoptionscurrentindividual.tipText = BOX_SVG_EXPORTCURRENTINDIV_TOOLTIP

    map.options['split_sections'] = false
    map.options['current_section_only'] = false
    map.options['selected_elements_only'] = false

    # Draw selected elements only checkbox
    exportoptionsselectedonly = FXCheckButton.new(mainFrame, BOX_SVG_EXPORTSELONLY, nil, 0,
            ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|JUSTIFY_LEFT|
            LAYOUT_SIDE_RIGHT)
    exportoptionsselectedonly.setCheck(false)
    exportoptionsselectedonly.disable
    exportoptionsselectedonly.tipText = BOX_SVG_EXPORTSELONLY_TOOLTIP
    map.options['selected_elements_only'] = false

    # Draw location text for selected only checkbox
    drawlocationforselectedonly = FXCheckButton.new(mainFrame, BOX_SVG_EXPORTALLLOCSSELTXT, nil, 0,
      ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|JUSTIFY_LEFT|LAYOUT_SIDE_RIGHT)
    drawlocationforselectedonly.setCheck(false)
    drawlocationforselectedonly.disable
    drawlocationforselectedonly.tipText = BOX_SVG_EXPORTALLLOCSSELTXT_TOOLTIP
    map.options['text_for_selected_only'] = false

    exportoptionsdatatarget.connect(SEL_COMMAND) {
      case exportoptionsdatatarget.value
        when 0
          exportoptionsselectedonly.disable
          # exportoptionsselectedonly.setCheck(false)
          drawlocationforselectedonly.disable
          # drawlocationforselectedonly.setCheck(false)
          map.options['split_sections'] = false
          map.options['current_section_only'] = false
          # map.options['selected_elements_only'] = false
          # map.options['location_text_for_selected_only'] = false
          showlocationtext.enable
          map.options['draw_roomnames'] = showlocationtext.check
        when 1
          exportoptionsselectedonly.disable
          # exportoptionsselectedonly.setCheck(false)
          drawlocationforselectedonly.disable
          # drawlocationforselectedonly.setCheck(false)
          map.options['split_sections'] = true
          map.options['current_section_only'] = false
          # map.options['selected_elements_only'] = false
          # map.options['location_text_for_selected_only'] = false
          showlocationtext.enable
          map.options['draw_roomnames'] = showlocationtext.check
        when 2
          exportoptionsselectedonly.enable
          drawlocationforselectedonly.enable
          map.options['split_sections'] = true
          map.options['current_section_only'] = true
          if drawlocationforselectedonly.check
            showlocationtext.disable
            map.options['draw_roomnames'] = false
          end
        end
    }

    exportoptionsselectedonly.connect(SEL_COMMAND) {
      map.options['selected_elements_only'] = (exportoptionsselectedonly.check == true)
      if exportoptionsselectedonly.check
        drawlocationforselectedonly.disable
        drawlocationforselectedonly.setCheck(false)
      else
        drawlocationforselectedonly.enable
      end
    }

    drawlocationforselectedonly.connect(SEL_COMMAND) {
      map.options['text_for_selected_only'] = (drawlocationforselectedonly.check == true)
      if drawlocationforselectedonly.check
        showlocationtext.disable
        map.options['draw_roomnames'] = false
        exportoptionsselectedonly.disable
        exportoptionsselectedonly.setCheck(false)
      else
        showlocationtext.enable
        map.options['draw_roomnames'] = showlocationtext.check
        exportoptionsselectedonly.enable
      end
    }



    # Dialog button(s):
    # =================

    # Horizontal frame to hold button
    dialogbuttonsframe = FXHorizontalFrame.new(mainFrame,
                    LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|
                    PACK_UNIFORM_WIDTH)

    # OK button
    FXButton.new(dialogbuttonsframe, "&OK", nil, self, FXDialogBox::ID_ACCEPT,
         FRAME_RAISED|LAYOUT_FILL_X|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)



    create

  end
end
