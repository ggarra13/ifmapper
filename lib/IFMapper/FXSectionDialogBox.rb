

class FXSectionDialogBox < FXDialogBox

  def copy_to()
    @section.name  = @name.text
    @section.comments = @comments.text
    @map.update_title
  end

  def copy_from(section)
    @name.text   = section.name.to_s
    @section = section
    @comments.text = section.comments
  end

  def initialize(map)
    decor = DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE

    super( map.window, "Section Information", decor, 40, 40, 0, 0 )
    mainFrame = FXVerticalFrame.new(self,
				    FRAME_SUNKEN|FRAME_THICK|
				    LAYOUT_FILL_X|LAYOUT_FILL_Y)

    frame = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

    FXLabel.new(frame, "Name: ", nil, 0, LAYOUT_FILL_X)
    @name = FXTextField.new(frame, 40, nil, 0, LAYOUT_FILL_ROW)

    commentsframe = FXVerticalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)


    FXLabel.new(commentsframe, "Section Comments:", nil, 0, LAYOUT_FILL_X)
    @comments = FXText.new(commentsframe, nil, 0, LAYOUT_FILL_X)
    @comments.visibleRows = 4;
    @comments.visibleColumns = 32;

    frame = FXVerticalFrame.new(mainFrame, 
				LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)


    @name.connect(SEL_CHANGED) { copy_to() }
    @comments.connect(SEL_CHANGED) { copy_to() }
    @map = map

    # We need to create the dialog box first, so we can use select text.
    create
  end
end
