

class FXWarningBox < FXDialogBox
  def initialize(parent, text)
      super( parent, "Warning", DECOR_ALL, 0, 0, 400, 130)
      # Frame
      s = FXVerticalFrame.new(self,
			      LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

      f = FXHorizontalFrame.new(s, LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)

      font = FXFont.new(app, "Helvetica", 30)
      oops = FXLabel.new(f, "!", nil, 0, LAYOUT_SIDE_LEFT|LAYOUT_FILL_X|
			 LAYOUT_CENTER_Y)
      oops.frameStyle = FRAME_RAISED|FRAME_THICK
      oops.baseColor = 'dark grey'
      oops.textColor = 'red'
      oops.padLeft = oops.padRight = 15
      oops.shadowColor = 'black'
      oops.borderColor = 'white'
      oops.font = font

      t = FXText.new(f)
      t.text = text
      t.visibleRows = 4
      t.visibleColumns = 80
      t.backColor = f.backColor
      t.disable

      # Separator
      FXHorizontalSeparator.new(s,
				LAYOUT_SIDE_TOP|LAYOUT_FILL_X|SEPARATOR_GROOVE)

      # Bottom buttons
      buttons = FXHorizontalFrame.new(s,
				      LAYOUT_SIDE_BOTTOM|FRAME_NONE|
				      LAYOUT_FILL_X|PACK_UNIFORM_WIDTH)
      # Accept
      FXButton.new(buttons, "&Yes", nil, self, FXDialogBox::ID_ACCEPT,
                   FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_X|
                   LAYOUT_RIGHT|LAYOUT_CENTER_Y)

      # Cancel
      no = FXButton.new(buttons, "&No", nil, self, FXDialogBox::ID_CANCEL,
			FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_X|
			LAYOUT_RIGHT|LAYOUT_CENTER_Y)
      no.setDefault
      no.setFocus
  end
end

