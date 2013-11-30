
#
# Class used to display a connection dialog box
#
class FXSearchDialogBox < FXDialogBox
  attr_accessor :index

  def text=(x)
    @search.text = x
    @index = 0
  end

  def text
    return @search.text
  end

  def proc=(p)
    @search.connect(SEL_CHANGED, p)
    @proc = p
  end

  def initialize(parent)
    decor = DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE
    super( parent, '', decor, 40, 200, 0, 0 )
    @index = 0
    mainFrame = FXVerticalFrame.new(self,
				    FRAME_SUNKEN|FRAME_THICK|
				    LAYOUT_FILL_X|LAYOUT_FILL_Y)

    frame = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

    FXLabel.new(frame, "Search String: ", nil, 0, LAYOUT_FILL_X)
    @search = FXTextField.new(frame, 40, nil, 0, LAYOUT_FILL_ROW)

    frame = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X)
    @previous = FXButton.new(frame, "Previous Match")
    @previous.connect(SEL_COMMAND) { |sender, sel, e |
      @index -= 1 if @index > 0
      sender.handle(self, MKUINT(message, SEL_CHANGED), nil)
      @proc.call @search, nil, nil if @proc
    }
    @next     = FXButton.new(frame, "Next Match") 
    @next.connect(SEL_COMMAND) { |sender, sel, e |
      @index += 1
      @proc.call @search, nil, nil if @proc
    }

    # We need to create the dialog box first, so we can use select text.
    create
  end
end
