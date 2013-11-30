
class TranscriptDialogBox < FXDialogBox



  def copy_from(transcript)
    @transcript = transcript
    @type.currentNo  = transcript.identify
    @short.currentNo = transcript.shortName
    @exp.text  = TRANSCRIPT_EXPLANATION_TEXT[@short.currentNo]
    @show.text = TRANSCRIPT_LOCATION_TEXT[@short.currentNo]
    @show2.text = TRANSCRIPT_LOCATION2_TEXT[@short.currentNo]
    parent = transcript.map.window
  end

  def copy_to()
    @transcript.identify  = @type.currentNo
    @transcript.shortName = @short.currentNo
    @exp.text  = TRANSCRIPT_EXPLANATION_TEXT[@short.currentNo]
    @show.text  = TRANSCRIPT_LOCATION_TEXT[@short.currentNo]
    @show2.text = TRANSCRIPT_LOCATION2_TEXT[@short.currentNo]
  end

  def initialize(transcript)
    map = transcript.map
    pos = [40, 40]
    maxW = map.window.width  - 390
    maxH = map.window.height - 300
    pos[0] = maxW if pos[0] > maxW
    pos[1] = maxH if pos[1] > maxH

    decor = DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE
    super( map.window, BOX_TRANSCRIPT, decor, pos[0], pos[1], 0, 0 )

    mainFrame = FXVerticalFrame.new(self,
				    FRAME_SUNKEN|FRAME_THICK|
				    LAYOUT_FILL_X|LAYOUT_FILL_Y)

    frame = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
    FXLabel.new(frame, BOX_TRANSCRIPT_STYLE, nil, 0, LAYOUT_FILL_X)
    pane = FXPopup.new(self)
    TRANSCRIPT_SHORTNAME_TYPE.each { |t|
      FXOption.new(pane, t, nil, nil, 0, JUSTIFY_HZ_APART|ICON_AFTER_TEXT)
    }
    @short = FXOptionMenu.new(frame, pane, FRAME_RAISED|FRAME_THICK|
			      JUSTIFY_HZ_APART|ICON_AFTER_TEXT|
			      LAYOUT_CENTER_X|LAYOUT_CENTER_Y)


    frame = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
    FXLabel.new(frame, BOX_TRANSCRIPT_IDENTIFY, nil, 0, LAYOUT_FILL_X)
    pane = FXPopup.new(self)
    TRANSCRIPT_IDENTIFY_TYPE.each { |t|
      FXOption.new(pane, t, nil, nil, 0, JUSTIFY_HZ_APART|ICON_AFTER_TEXT)
    }
    @type = FXOptionMenu.new(frame, pane, FRAME_RAISED|FRAME_THICK|
			     JUSTIFY_HZ_APART|ICON_AFTER_TEXT|
			     LAYOUT_CENTER_X|LAYOUT_CENTER_Y)



    frame = FXVerticalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
    FXLabel.new(frame, BOX_TRANSCRIPT_EXPLANATION, nil, 0, LAYOUT_FILL_X)
    @exp  = FXText.new(frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @exp.visibleRows = 4
    @exp.visibleColumns = 60
    @exp.backColor = mainFrame.backColor
    @exp.disable

    frame = FXVerticalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
    FXLabel.new(frame, BOX_TRANSCRIPT_VERBOSE, nil, 0, LAYOUT_FILL_X)
    @show  = FXText.new(frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @show.visibleRows = 9
    @show.visibleColumns = 60
    @show.disable
    FXLabel.new(frame, BOX_TRANSCRIPT_BRIEF, nil, 0, LAYOUT_FILL_X)
    @show2  = FXText.new(frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @show2.visibleRows = 3
    @show2.visibleColumns = 60
    @show2.disable

    @type.connect(SEL_COMMAND)  { copy_to }
    @short.connect(SEL_COMMAND) { copy_to }

    copy_from(transcript)
  end
end
