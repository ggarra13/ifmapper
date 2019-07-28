# coding: utf-8
################ 
TITLE = '#{PROGRAM_NAME} v#{VERSION} - Written by #{AUTHOR}'

################ Errors
ERR_NO_FOX   = 'Please install the FXRuby (FOX) library version 1.6 o later.'
ERR_HAS_GEMS = 'You can do it if you run \'gem install -r fxruby\''
ERR_NO_YAML  =<<'EOF'
Please install the 'yaml' library.  
Without it preferences cannot be loaded or saved.
EOF
ERR_COULD_NOT_SAVE = 'Could not save'
ERR_COULD_NOT_LOAD = 'Could not load'
ERR_NO_ICON        = 'Could not load icon: '
ERR_NO_PRINTING    = <<'EOF'
Sorry, but printing is not yet implemented
in this version.
EOF
ERR_NO_FREE_ROOM   = 'Sorry. No free room in map to paste the nodes.'
ERR_NO_MATCHES     = 'No matches for regex'
ERR_CANNOT_AUTOMAP = 'Cannot automap.'
ERR_READ_ONLY_MAP = "Map is in Read Only Mode.\nGo to Map Information to change this."
ERR_CANNOT_MOVE_SELECTION = 'Cannot move selection'
ERR_CANNOT_OPEN_TRANSCRIPT = 'Cannot open transcript'
ERR_PARSE_TRANSCRIPT = "Internal error parsing transcript\nPlease report as a bug"
ERR_COULD_NOT_OPEN_WEB_BROWSER = 'Could not open any web browser'
ERR_PATH_FOR_CONNECTION = 'Path for connection'
ERR_IS_BLOCKED = 'is blocked'

################ Messages
MSG_LOAD_MAP  = 'Load New Map'
MSG_SAVING    = 'Saving'
MSG_SAVED     = 'Saved'
MSG_LOADING   = 'Loading'
MSG_LOADED    = 'Loaded'
MSG_EMPTY_MAP = 'Empty Map'
MSG_PRINT_MAP = 'Print Map'
MSG_PRINT_LOC = 'Print Locations'
MSG_MATCHES   = 'matches'
MSG_MATCHES_IN_MAP = 'matches in map'
MSG_MATCHES_IN_SECTION = 'in section'
MSG_FIND_LOCATION_IN_MAP = 'Find Location in Map'
MSG_FIND_LOCATION_IN_SECTION = 'Find Location in this Section'
MSG_FIND_OBJECT_IN_MAP = 'Find Object in Map'
MSG_FIND_TASK_IN_MAP = 'Find Task in Map'
MSG_FIND_DESCRIPTION_IN_MAP = 'Find in Description in Map'
MSG_ABOUT_SOFTWARE = 'About This Software...'
MSG_ABOUT = <<'EOF'
#{PROGRAM_NAME} - #{VERSION}
Written by #{AUTHOR}.

FXRuby Version: #{Fox::fxrubyversion}

Ruby Version: #{RUBY_VERSION}

A WYSIWYG mapping tool for interactive fiction.

ggarra13@gmail.com
EOF

MSG_SAVE_MAP = 'Save Map'
MSG_WAS_MODIFIED = "was modified.\n"
MSG_SHOULD_I_SAVE_CHANGES = 'Should I save the changes?'

MSG_SAVE_MAP_AS_TRIZBORT = 'Save Map as Trizbort File'
FMT_TRIZBORT             = 'Trizbort Map (*.trizbort)'

MSG_SAVE_MAP_AS_IFM = 'Save Map as IFM File'
FMT_IFM             = 'IFM Map (*.ifm)'

MSG_SAVE_MAP_AS_INFORM6 = 'Save Map as Inform 6 Files'
MSG_SAVE_MAP_AS_INFORM7 = 'Save Map as Inform 7 Files'
FMT_INFORM6            = 'Inform6 Source Code (*.inf)'
FMT_INFORM7            = 'Inform7 Source Code (*.inform)'

MSG_SAVE_MAP_AS_TADS   = 'Save Map as TADS Files'
FMT_TADS               = 'TADS Source Code (*.t)'

MSG_SAVE_MAP_AS_PDF    = 'Save Map as Acrobat PDF'
FMT_PDF                = 'Acrobat PDF (*.pdf)'

MSG_HOTKEYS = <<'EOF'

LMB - Left   Mouse Button
MMB - Middle Mouse Button
RMB - Right  Mouse Button

Mouse controls
--------------

Use  LMB to add new locations or connections among rooms.

Click with LMB on any room or connection to select it.

Double click on rooms or connections to access their properties.

Click several times on an existing connecion to establish a one-way 
connection.

Drag with MMB or ALT + LMB to scroll around the page.

Use mousewheel to zoom in and out.

Use RMB after selecting a connection to bring a menu to allow you
to flip its direction or to attach it to some other exit in one 
of the rooms.

Keyboard controls
-----------------

Use 'x' to start a new complex connection (ie. a connection across
rooms that are not neighbors), then click on each exit of each room.

Use 'Delete' or 'Backspace' to remove any selected connection or room.

Use arrow keys or numeric keypad to move selected rooms around 
the page, one unit at a time.

Use CTRL + LMB when adding a connection to create a dead-end 
connection (one that loops onto itself)

EOF

MSG_LOAD_TRANSCRIPT = 'Load Transcript'
MSG_NEW_LOCATION = 'New Location'
MSG_OPENING_WEB_PAGE = 'Opening web page'

TRANSCRIPT_EXPLANATION_TEXT = [
"Classic Mode expects a short name description for all
locations, where all words of 5 or more characters to are
capitalized and where there is no period.  
Commands always begin with a > prompt.",
"Capitalized Mode expects a short name description for all
locations, where only the first word needs to be capitalized
and there is no period.  
Commands always begin with a > prompt.",
"Moonmist mode describes locations in parenthesis, with 'You
are...' prefixed and a period at the end, inside the parenthesis.
Commands always begin with a > prompt.",
"Witness mode expects locations described as normal prose, using
'You are...' as an introductory paragraph.  When in brief mode, 
locations are expected to be in parenthesis.
Commands always begin with a > prompt.",
"ADRIFT mode expects locations to be like in Classic Mode (short
names where all words of 5 or more characters are capitalized).
However, commands do not begin with any type of prompt but start
with a lowercase word without any margin.",
"ALL CAPS mode is like Classic Mode but expects locations to be
spelled all in caps."
]


TRANSCRIPT_LOCATION_TEXT = [
"
> look
West of House
You are standing in an open field west of a white house, with a boarded
front door.
",
"
> look
Women's change room
Your heels click loudly on the tiles, echoing down the banks of lockers
that line the sides of the room.
",
"
> look
(You are now in the driveway.)
(You're sitting in the sports car.)
You are by the front gate of the Tresyllian Castle. You can hear the ocean
beating urgently against the rocks far below.
",
"
> look
You are now in the driveway entrance.
You are standing at the foot of the driveway, the entrance to the
Linder property. The entire lot is screened from the street and the 
neighbors by a wooden fence, except on the east side, which fronts on 
dense bamboo woods.
",
"
look
Front of Mall
    Although four-wheeled vehicles do pass through, this autonomous 
spot of pavement is too narrow a place for them to stall.  It is just 
right for bicycles and motorbikes such as yours.
",
"
> look
WEST OF HOUSE
You are standing in an open field west of a white house, with a boarded
front door.
"
  ]

TRANSCRIPT_LOCATION2_TEXT = [
"
West of House
",
"
Women's change room
",
"
(You are in the driveway.)
",
"
(driveway entrance)
",
"
Front of Mall
",
"
WEST OF HALL
"
]


TRANSCRIPT_IDENTIFY_TYPE = [
  'By Descriptions',
  'By Short Name',
]

TRANSCRIPT_SHORTNAME_TYPE = [
  'Classic',
  'Capitalized',
  'Moonmist',
  'Witness',
  'ADRIFT',
  'ALL CAPS'
]

############ Window Titles
TITLE_READ_ONLY = '[Read Only]'
TITLE_AUTOMAP   = '[Automap]'
TITLE_ZOOM      = 'Zoom:'
TITLE_SECTION   = 'Section'
TITLE_OF        = 'of'


############ Extensions
EXT_TRANSCRIPT = 'Transcript File (*.log,*.scr,*.txt)'
EXT_ALL_FILES  = 'All Files (*)'
EXT_MAP_FILES  = 'Archivos de Mapas'



############ Status messages
MSG_COMPLEX_CONNECTION = 'Click on first room exit in complex connection.'
MSG_COMPLEX_CONNECTION_OTHER_EXIT = 'Click on other room exit in complex connection.'
MSG_COMPLEX_CONNECTION_STOPPED = 'Complex connection interrupted.'
MSG_COMPLEX_CONNECTION_DONE = 'Complex connection done.'

MSG_CLICK_TO_SELECT_AND_MOVE = 'Click to select and move.  Double click to edit.'
MSG_CLICK_TOGGLE_ONE_WAY_CONNECTION  = 'Click to toggle one way connection.'
MSG_CLICK_CHANGE_DIR  = 'Click to change the direction of the connection.'
MSG_CLICK_CREATE_ROOM = 'Click to create new room.'
MSG_CLICK_CREATE_LINK = 'Click to create new connection.'

############ Warnings
WARN_DELETE_SECTION = 'Are you sure you want to delete this section?'
WARN_OVERWRITE_MAP  = 'already exists.  Are you sure you want to overwrite it?'
WARN_MAP_SMALL = "When changing map size,\nsome rooms will be left outside of map.\nThese rooms will be deleted.\nAre you sure you want to do this?"

############ Menus
MENU_FILE    = "&File"
MENU_NEW     = "&New...\tCtl-N\tCreate new document."
MENU_OPEN    = "&Open...\tCtl-O\tOpen document file."
MENU_SAVE    = "&Save\tCtl-S\tSave document."
MENU_SAVE_AS = "Save &As...\t\tSave document to another file."

MENU_EXPORT  = 'Export'
MENU_EXPORT_PDF    = "Export as &PDF...\t\tExport map as Acrobat PDF document."
MENU_EXPORT_TRIZBORT = "Export as Triz&bort...\t\tExport map as a Trizbort map."
MENU_EXPORT_IFM    = "Export as &IFM...\t\tExport map as an IFM map."
MENU_EXPORT_INFORM6 = "Export as &Inform 6 Source...\t\tExport map as an Inform 6 source code file."
MENU_EXPORT_INFORM7 = "Export as &Inform 7 Source...\t\tExport map as an Inform 7 source code file."
MENU_EXPORT_TADS = "Export as &TADS3 Source...\t\tExport map as a TADS3 source code file."

MENU_PRINT = 'Print'
MENU_PRINT_MAP = "&Map...\t\tPrint map (as graph)."
MENU_PRINT_LOCATIONS = "&Locations...\t\tPrint map locations as text list."

MENU_QUIT = "&Quit\tCtl-Q\tQuit the application."


MENU_EDIT  = '&Edit'
MENU_COPY  = "&Copy\tCtl-C\tCopy Location Data"
MENU_CUT   = "Cu&t\tCtl-X\tCut Location"
MENU_PASTE = "&Paste\tCtl-V\tPaste Location Data"
MENU_UNDO  = "&Undo\tCtl-U\tUndo Last Deletion"

MENU_MAP   = '&Map'
MENU_SELECT = 'Select'
MENU_SELECT_ALL  = "&All Locations\tAlt-A\tSelect all locations in section"
MENU_SELECT_NONE = "&None\tAlt-N\tClear selection in section."

MENU_SEARCH = 'Search'
MENU_SEARCH_MAP = "&Location in Map\tCtl-F\tFind a Location Name in Map"
MENU_SEARCH_SECTION = "Location in &Section\tAlt-F\tFind a Location Name in Current Section"
MENU_SEARCH_OBJECT = "&Object in Map\tAlt-O\tFind Location with an Object in the Map"
MENU_SEARCH_TASK = "&Task in Map\tAlt-T\tFind Location with a Task in the Map"
MENU_SEARCH_DESCRIPTION = "&Keyword in Descriptions\tAlt-D\tFind Location with Description Keyword in the Map"

MENU_COMPLEX_CONNECTION = "Comple&x Connection\tx\tCreate a complex connection."
MENU_DELETE = "Delete\tDel\tDelete selected locations or connections."

MENU_MAP_INFO  = "Map Information\t\tChange map information."
MENU_ROOM_LIST = "Room List\t\tList all rooms in map."
MENU_ITEM_LIST = "Items List\t\tList all items in rooms of map."


MENU_AUTOMAP = 'Automap'
MENU_AUTOMAP_START = "&Start...\tCtl-T\tStart creating map from transcript file."
MENU_AUTOMAP_STOP = "S&top...\tCtl-P\tStop autocreating map."
MENU_AUTOMAP_PROPERTIES = "&Properties...\tCtl-H\tTranscript properties."


MENU_SECTIONS = 'Sections'
MENU_NEXT_SECTION = "Next Section\t\tGo to Next Map Section."
MENU_PREVIOUS_SECTION = "Previous Section\t\tGo to Previous Map Section."
MENU_ADD_SECTION = "Add Section\t\tAdd a New Section to Map."
MENU_SECTION_INFO = "Current Section Information\t\tChange current section information."
MENU_RENAME_SECTION = "Rename Section\t\tRename Current Section."
MENU_DELETE_SECTION = "Delete Section\t\tDelete Current Section from Map."

MENU_FLIP_DIRECTION = "Flip Direction of Selection"
MENU_MOVE_LINK = 'Move link to Exit'
MENU_SWITCH_WITH_LINK = 'Switch with link'

MENU_ZOOM_PERCENT = '#{v}%\t\tZoom page to #{v}%.'
MENU_ZOOM = 'Zoom'


MENU_OPTIONS = 'Options'
MENU_EDIT_ON_CREATION = "Edit on Creation\t\tEdit locations on creation."
MENU_AUTOMATIC_CONNECTION = "Automatic Connection\t\tConnect new location to adjacent one."
MENU_CREATE_ON_CONNECTION = "Create on Connectionn\t\tCreate missing locations when creating a connection."


MENU_DISPLAY = 'Display'
MENU_USE_ROOM_CURSOR = "Use Room Cursor\t\tMake your mouse cursor a room showing the direction of exit."
MENU_PATHS_AS_CURVES = "Paths as Curves\t\tDraw complex paths as curves."
MENU_LOCATION_NUMBERS = "Location Numbers\t\tShow Location Numbers."
MENU_LOCATION_TASKS   = "Location Tasks\t\tShow Tasks in Location Edit Box."
MENU_LOCATION_DESC    = "Location Description\t\tShow Description in Location Edit Box."
MENU_BOXES = "Boxes\t\tDraw dashed box guidelines."
MENU_STRAIGHT_CONN    = "Straight Connections\t\tDraw dashed N/S/E/W guidelines"
MENU_DIAGONAL_CONN    = "Diagonal Connections\t\tDraw dashed NW/NE/SW/SE guidelines"

MENU_PREFS = 'Preferences'
MENU_LANGUAGE = "Language\t\tChange the default lenguage of the application."
MENU_COLORS = "Colors\t\tChange map colors."
MENU_SAVE_PREFS = "Save Preferences\t\tSave Preferences for Startup"

MENU_WINDOW  = '&Window'
MENU_TILE_HORIZONTALLY = "Tile &Horizontally"
MENU_TILE_VERTICALLY = "Tile &Vertically"
MENU_CASCADE = 'C&ascade'
MENU_CLOSE   = '&Close'
MENU_OTHERS  = '&Others...'

MENU_HELP = '&Help'
MENU_HOTKEYS = '&Hotkeys'
MENU_INSTRUCTIONS = '&Instructions'
MENU_ABOUT = '&About'
MENU_RESOURCE = "&Resource Code"

############ Edit Boxes

BOX_INSTRUCTIONS = 'Instructions'
BOX_HOTKEYS      = 'Hotkeys'

BOX_ROOM_INFORMATION = 'Room Information'
BOX_LOCATION = 'Location: '
BOX_OBJECTS  = 'Objects: '
BOX_DARKNESS = 'Darkness'
BOX_TASKS    = 'Tasks: '
BOX_DESCRIPTION = 'Description: '
BOX_COMMENTS = 'Comments: '

BOX_CONNECTION_TYPE = 'Connection Type: '
BOX_CONNECTION_TYPE_TEXT = [
  'Free',
  'Door',
  'Locked',
  'Special',
]
BOX_DIRECTION = 'Direction: '
BOX_DIR_TEXT = [
  'Both',
  'One Way',
]
BOX_EXIT_A_TEXT = 'Exit A Text:'
BOX_EXIT_B_TEXT = 'Exit B Text:'
BOX_EXIT_TEXT = [ 
  'None',
  'Up',
  'Down',
  'In',
  'Out',
]

BOX_LOCATIONS = 'Locations'
BOX_SECTION = 'Section'
BOX_NAME = 'Name'

BOX_MAP_INFORMATION = 'Map Information'
BOX_MAP_READ_ONLY = 'Read Only Map'
BOX_MAP_CREATOR = 'Creator:'
BOX_MAP_WIDTH = 'Map Width'
BOX_MAP_HEIGHT = 'Map Height'

BOX_TRANSCRIPT = 'Transcript Options'
BOX_TRANSCRIPT_STYLE = 'Transcript Style: '
BOX_TRANSCRIPT_IDENTIFY = 'Identify Locations: '
BOX_TRANSCRIPT_EXPLANATION = 'Explanation: '
BOX_TRANSCRIPT_VERBOSE = 'Sample Verbose Mode: '
BOX_TRANSCRIPT_BRIEF   = 'Sample Brief Mode: '

BOX_COLOR = 'Color Preferences'
BOX_BG_COLOR = '&Background Color'
BOX_ARROWS_COLOR = '&Arrows Color'
BOX_BOX_BG_COLOR = '&Box Background Color'
BOX_BOX_DARK_COLOR = '&Box Darkness Color'
BOX_BOX_BORDER_COLOR = '&Box Border Color'
BOX_BOX_NUMBER_COLOR = '&Box Number Color'

BOX_PDF_PAGE_SIZE = 'Page Size: '
BOX_PDF_PAGE_SIZE_TEXT = [
  'LETTER',
  'A0',
  'A4',
]
BOX_PDF_LOCATIONNOS = 'Include Location Numbers'

MSG_SAVE_MAP_AS_SVG                 = 'Save Map as SVG'
FMT_SVG                             = 'Structured Vector Graphic (*.svg)'
MENU_EXPORT_SVG                     = "Export as &SVG...\t\tExport map as Structured Vector Graphics (SVG) document."
BOX_SVG_SHOWLOCNUMS                 = "Show Location Numbers"
BOX_SVG_SHOWLOCNUMS_TOOLTIP         = "Include each Room's Location Number in exported map"
BOX_SVG_SHOWINTERTITLE              = "Show Interactive Location Information:"
BOX_SVG_SHOWINTEROBJECTS            = "Objects"
BOX_SVG_SHOWINTEROBJECTS_TOOLTIP    = "Include the Objects at each Room's Location as drop-down in exported map"
BOX_SVG_SHOWINTERTASKS              = "Tasks"
BOX_SVG_SHOWINTERTASKS_TOOLTIP      = "Include the Tasks at each Room's Location as drop-down in exported map"
BOX_SVG_SHOWINTERCOMMENTS           = "Comments"
BOX_SVG_SHOWINTERCOMMENTS_TOOLTIP   = "Include the Comments at each Room's Location as drop-down in exported map"
BOX_SVG_SHOWINTERDESCRIPTION        = "Description"
BOX_SVG_SHOWINTERDESCRIPTION_TOOLTIP= "Include the Description at each Room's Location as drop-down in exported map"

BOX_SVG_EXPORTALLCOMBINED           = "All Sections to Combined SVG file"
BOX_SVG_EXPORTALLCOMBINED_TOOLTIP   = "All Sections exported to a single SVG file, in order"
BOX_SVG_EXPORTALLINDIV              = "All Sections to Individual SVG files"
BOX_SVG_EXPORTALLINDIV_TOOLTIP      = "All Sections exported to separate SVG files"
BOX_SVG_EXPORTCURRENTINDIV          = "Current Section to Individual SVG file"
BOX_SVG_EXPORTCURRENTINDIV_TOOLTIP  = "Current Section exported to a single SVG file"

BOX_SVG_EXPORTSELONLY               = "Only Include Currently Selected Elements"
BOX_SVG_EXPORTSELONLY_TOOLTIP       = "Select some Locations and/or Connections in the Current Section,\nthen use this option to ensure that only these elements, along\nwith Location no. 1 are included in the exported map"
BOX_SVG_EXPORTALLLOCSSELTXT         = "Include All Locations, Only Show Location\nText For Currently Selected Locations"
BOX_SVG_EXPORTALLLOCSSELTXT_TOOLTIP = "The exported map will contain all Locations in the Current Section.\nLocation no. 1 and any Locations currently selected will have their Location Text included.\nOnly Connections that are currently selected will be included in the map"

BOX_SVG_SHOWLOCTEXT                 = "Show Location Text"
BOX_SVG_SHOWLOCTEXT_TOOLTIP         = "Include each Room's Location text in exported map"
BOX_SVG_SHOWSECTCOMMENTS            = "Show Section Comments"
BOX_SVG_SHOWSECTCOMMENTS_TOOLTIP    = "Include each Section Comments under corresponding Section Name in exported map"
BOX_SVG_COMPASSSIZE                 = "Compass Size: "
BOX_SVG_COMPASSSIZE_TOOLTIP         = "Size of Compass graphic, from non-existent to huge, in exported map"
BOX_SVG_CONNTHICKNESS               = "Connection Thickness:"
BOX_SVG_CONNTHICKNESS_TOOLTIP       = "Thickness of Connection lines, from non-existent to heavy, in exported map"
BOX_SVG_COLOURSCHEME                = "Colour Scheme:"
BOX_SVG_COLOURSCHEME_TOOLTIP        = "A basic Colour Scheme used for the location number, interactive\nlocation information and doors in exported map"
BOX_SVG_LOCTHICKNESS                = "Location Thickness:"
BOX_SVG_LOCTHICKNESS_TOOLTIP        = "Thickness of Location lines, from thin to heavy, in exported map"
BOX_SVG_COLOURSCHEME_OPTIONS = [
  'Red',
  'Green',
  'Yellow',
  'Blue',
]

########### Buttons
BUTTON_YES = '&Yes'
BUTTON_NO  = '&No'
BUTTON_CANCEL = '&Cancel'
BUTTON_ACCEPT = '&Accept'

########### Icons
ICON_NEW     = "\tNew\tCreate new document."
ICON_OPEN    = "\tOpen\tOpen document file."
ICON_SAVE    = "\tSave\tSave document."
ICON_SAVE_AS = "\tSaveAs\tSave document to another file."
ICON_PRINT   = "\tPrint Map\tPrint map (as graph)."
ICON_CUT     = "\tCut"
ICON_COPY    = "\tCopy"
ICON_PASTE   = "\tPaste"
ICON_ZOOM_IN  = "+\tZoom In"
ICON_ZOOM_OUT = "-\tZoom Out"
ICON_PREV_SECTION = "\tPrevious Section"
ICON_NEXT_SECTION = "\tNext Section"


########### Drawings

# Text near connection (to indicate other dir)
DRAW_EXIT_TEXT = [
  '',
  'U',
  'D',
  'I',
  'O'
]

class Room
  DIRECTIONS = [
    'n',
    'ne',
    'e',
    'se',
    's',
    'sw',
    'w',
    'nw',
  ]
  DIRECTIONS_ENGLISH = [
    'n',
    'ne',
    'e',
    'se',
    's',
    'sw',
    'w',
    'nw',
  ]
end

AUTOMAP_IS_WAITING_FOR_MORE_TEXT = "Automap is waiting for more text."
