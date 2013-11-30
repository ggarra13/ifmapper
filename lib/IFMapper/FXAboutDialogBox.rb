

class FXAboutDialogBox < FXDialogBox

  def initialize(parent, title, text)
    decor = DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE

    super( parent, title, decor, 40, 40, 0, 0 )
    mainFrame = FXVerticalFrame.new(self,
				    FRAME_SUNKEN|FRAME_THICK|
				    LAYOUT_FILL_X|LAYOUT_FILL_Y)

    frame = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

    FXLabel.new(frame, text, nil, 0, LAYOUT_FILL_ROW)

#     c = FXText.new(frame, nil, 0, LAYOUT_FILL_ROW)
#     c.visibleRows    = 10
#     c.visibleColumns = 80
#     c.editable = false
#     c.text = text

    buttons = FXHorizontalFrame.new(mainFrame, 
				    LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|
				    PACK_UNIFORM_WIDTH)
    # Accept
    FXButton.new(buttons, "&Super!", nil, self, FXDialogBox::ID_ACCEPT,
		 FRAME_RAISED|LAYOUT_FILL_X|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)

    create
  end
end
