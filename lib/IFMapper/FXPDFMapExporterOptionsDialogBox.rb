class FXPDFMapExporterOptionsDialogBox < FXDialogBox

  attr_accessor :pdfpapersize     # Map options

  def initialize(parent, title, map)
        
    decor = DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE

    super( parent, title, decor, 40, 40, 0, 0 )
    mainFrame = FXVerticalFrame.new(self,
				    FRAME_SUNKEN|FRAME_THICK|
				    LAYOUT_FILL_X|LAYOUT_FILL_Y)

    frame = FXHorizontalFrame.new(mainFrame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

    FXLabel.new(frame, BOX_PDF_PAGE_SIZE, nil, 0, LAYOUT_FILL_X)
    pane = FXPopup.new(self)
    BOX_PDF_PAGE_SIZE_TEXT.each { |t|
      FXOption.new(pane, t, nil, nil, 0, JUSTIFY_HZ_APART|ICON_AFTER_TEXT)
    }
    @pagesize = FXOptionMenu.new(frame, pane, FRAME_RAISED|FRAME_THICK|
			     JUSTIFY_HZ_APART|ICON_AFTER_TEXT|
			     LAYOUT_CENTER_X|LAYOUT_CENTER_Y)

    @locationnos = FXCheckButton.new(mainFrame, BOX_PDF_LOCATIONNOS, nil, 0,
			      ICON_BEFORE_TEXT|LAYOUT_CENTER_X|LAYOUT_SIDE_TOP|
			      LAYOUT_SIDE_RIGHT)
    @locationnos.setCheck(true)
			    
    buttons = FXHorizontalFrame.new(mainFrame, 
				    LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|
				    PACK_UNIFORM_WIDTH)

    require 'IFMapper/PDFMapExporter'
    @pagesize.connect(SEL_COMMAND) { map.pdfpapersize = @pagesize.currentNo }
    @locationnos.connect(SEL_COMMAND) { map.pdflocationnos = @locationnos.checkState }
    
    # Accept
    FXButton.new(buttons, "&OK", nil, self, FXDialogBox::ID_ACCEPT,
		 FRAME_RAISED|LAYOUT_FILL_X|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
 

    create
    
  end
end
