# coding: iso-8859-1

PROGRAM_NAME = "Interactive Fiction Mapper"
TITLE        = '#{PROGRAM_NAME} v#{VERSION} - Programado por #{AUTHOR}'

################ Errores
ERR_NO_FOX   = 'Por favor instale la librería FXRuby (FOX) version 1.2 o posterior.'
ERR_HAS_GEMS = 'Puede hacerlo si corre \'gem install -r fxruby\''
ERR_NO_YAML  =<<'EOF'
Por favor instale la librería 'yaml'.
Sin ella, las preferencias no pueden ser cargadas ni grabadas.
EOF
ERR_COULD_NOT_SAVE = 'No pude grabar'
ERR_COULD_NOT_LOAD = 'No pude cargar'
ERR_NO_ICON        = 'No pude cargar el ícono: '
ERR_NO_PRINTING    = <<'EOF'
Lo siento, pero la impresión no está implementada
en esta versión.
EOF
ERR_NO_FREE_ROOM   = 'Lo siento.  No hay espacio en el mapa para pegar las localidades.'
ERR_NO_MATCHES     = 'No hay coincidencias para la expresión'
ERR_CANNOT_AUTOMAP = 'No puedo mapear automáticamente.'
ERR_READ_ONLY_MAP  = "Mapa está en Modo de Lectura Solamente.  Vaya a Datos del Mapa para cambiar esto."
ERR_CANNOT_MOVE_SELECTION = 'No puedo mover la selección hacia el '
ERR_CANNOT_OPEN_TRANSCRIPT = 'No puedo abrir la transcripción'
ERR_PARSE_TRANSCRIPT = "Error interno interpretando transcripción\nPor favor repórtelo como un fallo del software"
ERR_COULD_NOT_OPEN_WEB_BROWSER = 'No pude abrir ningún web browser'
ERR_PATH_FOR_CONNECTION = 'El camino de la conexión'
ERR_IS_BLOCKED = 'está bloqueado'

################ Messages
MSG_LOAD_MAP  = 'Cargar Nuevo Mapa'
MSG_SAVING    = 'Grabando'
MSG_SAVED     = 'Grabado'
MSG_LOADING   = 'Cargando'
MSG_LOADED    = 'Cargado'
MSG_EMPTY_MAP = 'Nuevo Mapa'
MSG_PRINT_MAP = 'Imprimir Mapa'
MSG_PRINT_LOC = 'Imprimir Localidades'
MSG_MATCHES   = 'coincide'
MSG_MATCHES_IN_MAP = 'coincidencias en el mapa'
MSG_MATCHES_IN_SECTION = 'en la sección'
MSG_FIND_LOCATION_IN_MAP = 'Buscar Localidad en el Mapa'
MSG_FIND_LOCATION_IN_SECTION = 'Buscar Localidad en esta Sección'
MSG_FIND_OBJECT_IN_MAP = 'Buscar Objeto en el Mapa'
MSG_FIND_TASK_IN_MAP = 'Buscar Tarea en el Mapa'
MSG_FIND_DESCRIPTION_IN_MAP = 'Buscar en las Descripciones del Mapa'
MSG_ABOUT_SOFTWARE = 'Sobre este Programa...'
MSG_ABOUT = <<'EOF'
#{PROGRAM_NAME} - #{VERSION}
Escrito por #{AUTHOR}.

Versión de FXRuby: #{Fox::fxrubyversion}

Versión de Ruby: #{RUBY_VERSION}

Una herramienta de mapeado para ficción interactiva.

#{EMAIL}
EOF

MSG_SAVE_MAP = 'Grabar Mapa'
MSG_WAS_MODIFIED = "fue modificado.\n"
MSG_SHOULD_I_SAVE_CHANGES = '¿Grabo los cambios?'

MSG_SAVE_MAP_AS_TRIZBORT = 'Grabar Mapa como archivo Trizbort'
FMT_TRIZBORT             = 'Mapa Trizbort (*.trizbort)'

MSG_SAVE_MAP_AS_IFM = 'Grabar Mapa como Archivo IFM'
FMT_IFM             = 'Mapa IFM (*.ifm)'

MSG_SAVE_MAP_AS_INFORM6 = 'Grabar Mapa como Archivos Inform 6'
MSG_SAVE_MAP_AS_INFORM7 = 'Grabar Mapa como Archivos Inform 7'
FMT_INFORM6            = 'Código Fuente Inform6 (*.inf)'
FMT_INFORM7            = 'Código Fuente Inform7 (*.inform)'

MSG_SAVE_MAP_AS_TADS   = 'Grabar Mapa como Archivo TADS3'
FMT_TADS               = 'Codigo Fuente de TADS (*.t)'

MSG_SAVE_MAP_AS_PDF    = 'Grabar Mapa como Archivo Acrobat PDF'
FMT_PDF                = 'Acrobat PDF (*.pdf)'

MSG_HOTKEYS = <<'EOF'

BIR - Botón Izquierdo del Ratón
BMR - Botón Medio del Ratón
BDR - Botón Derecho del Ratón

Controles del Ratón
-------------------

Use el BIR para agregar localidades o conexiones entre ellas.

Cliquée con el BIR en una localidad o conexión para seleccionarla.

Cliquée Dos Veces en una localidad o conexión para acceder a 
sus propiedades.

Cliquée Varias Veces en una conexión existente para establecer una
conexión unidireccional.

Mantenga apretado el BMR o ALT + BIR y mueva el ratón para
moverse por la página.

Use la rueda del ratón para acercarse o alejarse.

Use el BDR tras seleccionar una conexión y así acceder a un menu para
invertir su dirección o para conectarla a otra salida de una de
las localidades.

Controles del Teclado
---------------------

Use 'x' para comenzar una conexión compleja (es decir, una conexión entre
localidades que no son vecinas), luego cliquée en cada salida de cada
localidad.

Use 'Supr' (Delete) or '<-' (Backspace) para borrar una conexión 
o localidad seleccionada.

Use las teclas de flechas del cursor o el teclado numérico para mover 
las habitaciones seleccionadas alrededor de la página, una unidad a la vez.

Use CTRL + BIR cuando agregue una conexión para crear una conexión
sin salida (una conexión que vuelve sobre sí misma)

EOF

MSG_LOAD_TRANSCRIPT = 'Cargar Transcripción'
MSG_NEW_LOCATION = 'Nueva Localidad'

MSG_OPENING_WEB_PAGE = 'Abriendo página web'

TRANSCRIPT_EXPLANATION_TEXT = [
"Modo Clásico espera un encabezado para todas las localidades,
donde todas las palabras de 5 o más letras aparecen en
mayúsculas y donde no hay ningún punto.  
Los comandos siempre comienzan tras un >.",
"Modo Mayúsculas espera un encabezado para todas las localidades,
donde sólo la primera palabra necesita estar en mayúsculas y
donde no hay ningún punto.  
Los comandos siempre comienzan tras un >.",
"Modo Moonmist describe las localidades en parentesis, con un 'You
are...' como prefijo y un punto al final de la oración, dentro de
los parentesis.
Los comandos siempre comienzan tras un >.",
"Modo Witness espera las localidades descriptas como prosa normal
usando 'You are...' como párrafo introductorio.  En modo simple, 
las localidades se describen en paréntesis.
Los comandos siempre comienzan tras un >.",
"Modo ADRIFT espera las localidades como en el modo Clásico
(encabezados de palabras de 5 o más letras en mayúsculas).
Los comandos comienzan sólo con una palabra en minúscula sin margen.",
]


TRANSCRIPT_LOCATION_TEXT = [
"
> mira
Al Oeste de la Casa
Estás parado en un campo abierto al oeste de una casa blanca, con una
puerta clausurada.
",
"
> mira
Vestidor de mujeres
Tus tacos resuenan fuertemente en las baldosas, y su eco rebota en las
filas de casilleros alineados a los lados de la habitación.
",
"
> mira
(You are now in the driveway.)
(You're sitting in the sports car.)
You are by the front gate of the Tresyllian Castle. You can hear the ocean
beating urgently against the rocks far below.
",
"
> mira
You are now in the driveway entrance.
You are standing at the foot of the driveway, the entrance to the
Linder property. The entire lot is screened from the street and the 
neighbors by a wooden fence, except on the east side, which fronts on 
dense bamboo woods.
",
"
mira
Entrada del Shopping
    Aunque vehículos de cuatro ruedas pasan por aquí, este lugar autónomo 
del pavimento es demasiado angosto para que estacionen.  Es apenas 
apropiado para bicicletas y motocicletas como la tuya.
",
  ]

TRANSCRIPT_LOCATION2_TEXT = [
"
Oeste de la Casa
",
"
Vestidor de mujeres
",
"
(You are in the driveway.)
",
"
(driveway entrance)
",
"
Entrada del Shopping
",
]


TRANSCRIPT_IDENTIFY_TYPE = [
  'Por las Descripciones',
  'Por los Encabezados',
]

TRANSCRIPT_SHORTNAME_TYPE = [
  'Clásico',
  'Mayúsculas',
  'Moonmist',
  'Witness',
  'ADRIFT',
  'ALL CAPS'
]

############ Títulos de Ventanas
TITLE_READ_ONLY = '[Sólo Lectura]'
TITLE_AUTOMAP   = '[Mapeado Automático]'
TITLE_ZOOM      = 'Acercamiento:'
TITLE_SECTION   = 'Sección'
TITLE_OF        = 'de'

############ Extensions
EXT_TRANSCRIPT = 'Archivo de Transcripción (*.log,*.scr,*.txt)'
EXT_ALL_FILES  = 'Todos los Archivos (*)'
EXT_MAP_FILES  = 'Archivos de Mapas'

############ Status messages
MSG_COMPLEX_CONNECTION = "Cliquée en la salida de la primera localidad de la conexión compleja."
MSG_COMPLEX_CONNECTION_OTHER_EXIT = "Cliquée en la otra salida de la conexión compleja."
MSG_COMPLEX_CONNECTION_STOPPED = 'Creación de la conexión compleja interrumpida.'
MSG_COMPLEX_CONNECTION_DONE = 'Conexión compleja completada.'

MSG_CLICK_TO_SELECT_AND_MOVE = 'Cliquée para seleccionar y mover.  Cliquée dos veces para editar.'
MSG_CLICK_TOGGLE_ONE_WAY_CONNECTION  = 'Cliquée para intercambiar la conexión de una sola dirección.'
MSG_CLICK_CHANGE_DIR  = 'Cliquée para cambiar dirección de la conexión.'
MSG_CLICK_CREATE_ROOM = 'Cliquée para crear una nueva localidad.'
MSG_CLICK_CREATE_LINK = 'Cliquée para crear una nueva conexión.'

############ Warnings
WARN_DELETE_SECTION = 'Está seguro que quiere borrar esta sección?'
WARN_OVERWRITE_MAP  = 'ya existe.  ¿Está seguro que quiere sobreescribirlo?'
WARN_MAP_SMALL = "Al cambiar el tamaño del mapa,\nalgunas localidades quedarán afuera del mismo.\nEstas localidades serán borradas.\n¿Está seguro que quiere hacer esto?"

############ Menus
MENU_FILE    = '&Archivo'
MENU_NEW     = "&Nuevo...\tCtl-N\tCrear un nuevo mapa."
MENU_OPEN    = "&Abrir...\tCtl-A\tAbrir un mapa."
MENU_SAVE    = "&Grabar\tCtl-G\tGrabar un mapa."
MENU_SAVE_AS = "Grabar &Como...\t\tGrabar mapa en otro archivo."

MENU_EXPORT  = 'Exportar'
MENU_EXPORT_PDF    = "&Exportar como PDF...\t\tExportar mapa como documento Acrobat PDF."
MENU_EXPORT_TRIZBORT = "Exportar como Triz&bort...\t\tExportar mapa como un mapa de Trizbort."
MENU_EXPORT_IFM    = "&Exportar como IFM...\t\tExportar mapa como un archivo IFM."
MENU_EXPORT_INFORM6 = "Exportar como Codigo de Inform 6...\t\tExportar mapa como un archivo de codigo fuente de Inform 6."
MENU_EXPORT_INFORM7 = "Exportar como Codigo de Inform 7...\t\tExportar mapa como un archivo de codigo fuente de Inform 7."
MENU_EXPORT_TADS = "&Exportar como Código Fuente de TADS3...\t\tExportar mapa como un código fuente de TADS3."

MENU_PRINT = 'Imprimir'
MENU_PRINT_MAP = "&Mapa...\t\tImprimir mapa (como gráfico)."
MENU_PRINT_LOCATIONS = "&Localidades...\t\tImprimir las localidades del mapa como una lista."

MENU_QUIT = "&Salir\tCtl-S\tSalir de la aplicación."


MENU_EDIT  = '&Editar'
MENU_COPY  = "&Copiar\tCtl-C\tCopiar Localidad"
MENU_CUT   = "Cor&tar\tCtl-X\tCortar Localidad"
MENU_PASTE = "&Pegar\tCtl-V\tPegar Localidad"
MENU_UNDO  = "&Deshacer\tCtl-U\tDeshacer Última Eliminación"

MENU_MAP   = '&Mapa'
MENU_SELECT = 'Seleccionar'
MENU_SELECT_ALL  = "&Todo\tAlt-A\tSeleccionar todas las localidades y conexiones en la sección"
MENU_SELECT_NONE = "&Nada\tAlt-N\tDeseleccionar todo en la sección actual."

MENU_SEARCH = 'Buscar'
MENU_SEARCH_MAP = "&Localidad en el Mapa\tCtl-B\tBuscar una Localidad en el Mapa"
MENU_SEARCH_SECTION = "Localidad en la &Sección\tAlt-B\tBuscar una Localidad en la Sección Actual"
MENU_SEARCH_OBJECT = "&Objeto en el Map\tAlt-O\tBuscar Localidad con un Objeto en el Mapa"
MENU_SEARCH_TASK = "&Tarea en el Mapa\tAlt-T\tBuscar Localidad con una Tarea en el Mapa"
MENU_SEARCH_DESCRIPTION = "&Palabra en las Descripciones\tAlt-D\tBuscar Localidad en el Mapa con una Palabra en la Descripción"

MENU_COMPLEX_CONNECTION = "Cone&xiones Complejas\tx\tCrear una conexión compleja."
MENU_DELETE = "Borrar\tDel\tBorrar las localidades seleccionadas o las conexiones."

MENU_MAP_INFO  = "Datos del Mapa\t\tCambiar los datos del mapa."
MENU_ROOM_LIST = "Lista de Localidades\t\tLista de todas las localidades en el mapa."
MENU_ITEM_LIST = "Lista de Items\t\tLista de todos los items en los lugares del mapa."


MENU_AUTOMAP = 'Mapeado Automático'
MENU_AUTOMAP_START = "&Comenzar...\tCtl-T\tComenzar a crear el mapa de un archivo de transcripción de juego."
MENU_AUTOMAP_STOP = "D&etener...\tCtl-P\tDetener creación automática del mapa."
MENU_AUTOMAP_PROPERTIES = "&Propiedades...\tCtl-H\tPropiedades de la Transcripción del Juego."


MENU_SECTIONS = 'Secciones'
MENU_NEXT_SECTION = "Sección Próxima\t\tIr a la Sección Próxima del Mapa."
MENU_PREVIOUS_SECTION = "Sección Previa\t\tIr a la Sección Previa del Mapa."
MENU_ADD_SECTION = "Agregar Sección\t\tAgregar una Nueva Sección al Mapa."
MENU_SECTION_INFO = "Información de la Sección Actual\t\tCambie la información de la sección actual."
MENU_RENAME_SECTION = "Renombrar Sección\t\tRenombrar Sección Actual."
MENU_DELETE_SECTION = "Borrar Sección\t\tBorrar Sección Actual del Mapa."

MENU_FLIP_DIRECTION = "Cambiar Dirección de la Selección"
MENU_MOVE_LINK = 'Mover la Unión a la Salida'
MENU_SWITCH_WITH_LINK = 'Intercambiar con Unión'

MENU_ZOOM_PERCENT = '#{v}%\t\tAcercamiento de la página al #{v}%.'
MENU_ZOOM = 'Acercamiento'


MENU_OPTIONS = 'Opciones'
MENU_EDIT_ON_CREATION = "Editar al Crear\t\tEditar localidades al crearlas."
MENU_AUTOMATIC_CONNECTION = "Conexión Automática\t\tConectar nueva localidad a la anterior adjacente."
MENU_CREATE_ON_CONNECTION = "Crear al Conectar\t\tCrear localidades faltantes al crear una conexion."


MENU_DISPLAY = 'Representación Visual'
MENU_USE_ROOM_CURSOR = "Usar Cursor de Localidades\t\tHace que tu flecha del ratón muestre la dirección de una salida."
MENU_PATHS_AS_CURVES = "Caminos como Curvas\t\tDibuja caminos complejos como curvas."
MENU_LOCATION_NUMBERS = "Numeración de Localidades\t\tMostrar la Numeración de las Localidades."
MENU_LOCATION_TASKS   = "Tareas en la Localidad\t\tMostrar Tareas al editar las Localidades."
MENU_LOCATION_DESC    = "Descripción de la Localidad\t\tMostrar Descripción de la Localidad al Editarla."
MENU_BOXES = "Rectángulos\t\tDibuja guías punteadas de localidades."
MENU_STRAIGHT_CONN    = "Conexiones Rectas\t\tDibuja guías punteadas para conexiones N/S/E/O"
MENU_DIAGONAL_CONN    = "Conexiones Diagonales\t\tDibuja guías punteadas para conexiones NO/NE/SO/SE"

MENU_PREFS = 'Preferencias'
MENU_LANGUAGE = "Lenguaje\t\tCambiar el lenguaje de la aplicación."
MENU_COLORS = "Colores\t\tCambiar los colores del mapa."
MENU_SAVE_PREFS = "Guardar Preferencias\t\tGuardar Preferencias para el Arranque"

MENU_WINDOW  = '&Ventana'
MENU_TILE_HORIZONTALLY = "Apilar &Horizontalmente"
MENU_TILE_VERTICALLY = "Apilar &Verticalmente"
MENU_CASCADE = 'En C&ascada'
MENU_CLOSE   = '&Cerrar'
MENU_OTHERS  = '&Otras...'

MENU_HELP = '&Ayuda'
MENU_HOTKEYS = '&Teclas'
MENU_INSTRUCTIONS = '&Instrucciones'
MENU_ABOUT = '&Acerca'
MENU_RESOURCE = "&Releer Código Fuente"

############ Cajas de Edición

BOX_INSTRUCTIONS = 'Instrucciones'
BOX_HOTKEYS = 'Teclas'

BOX_ROOM_INFORMATION = 'Datos de la Localidad'
BOX_LOCATION = 'Localidad: '
BOX_OBJECTS  = 'Objetos: '
BOX_DARKNESS = 'Oscuridad'
BOX_TASKS    = 'Tareas: '
BOX_DESCRIPTION = 'Descripción: '
BOX_COMMENTS = 'Comentarios: '

BOX_CONNECTION_TYPE = 'Tipo de Conexión: '
BOX_CONNECTION_TYPE_TEXT = [
  'Libre',
  'Puerta',
  'Con Llave',
  'Especial',
]
BOX_DIRECTION = 'Dirección: '
BOX_DIR_TEXT = [
  'Ambas',
  'Una',
]
BOX_EXIT_A_TEXT = 'Texto Salida A:'
BOX_EXIT_B_TEXT = 'Texto Salida B:'
BOX_EXIT_TEXT = [ 
  'Ninguno',
  'Subir',
  'Bajar',
  'Entrar',
  'Salir',
]

BOX_LOCATIONS = 'Localidades'
BOX_SECTION = 'Sección'
BOX_NAME = 'Nombre'

BOX_MAP_INFORMATION = 'Datos del Mapa'
BOX_MAP_READ_ONLY = 'Sólo Lectura'
BOX_MAP_CREATOR = 'Creador:'
BOX_MAP_WIDTH = 'Ancho'
BOX_MAP_HEIGHT = 'Alto'

BOX_TRANSCRIPT = 'Opciones de la Transcripción'
BOX_TRANSCRIPT_STYLE = 'Estilo de Transcripción: '
BOX_TRANSCRIPT_IDENTIFY = 'Identificar Localidades: '
BOX_TRANSCRIPT_EXPLANATION = 'Explicación: '
BOX_TRANSCRIPT_VERBOSE = 'Ejemplo en Modo Verborrágico: '
BOX_TRANSCRIPT_BRIEF   = 'Ejemplo en Modo Corto: '

BOX_COLOR = 'Preferencias de Color'
BOX_BG_COLOR = '&Color del Fondo'
BOX_ARROWS_COLOR = 'Color de las &Flechas'
BOX_BOX_BG_COLOR = 'Color de Fondo de las &Localidades'
BOX_BOX_DARK_COLOR = 'Color de Localidades &Oscuras'
BOX_BOX_BORDER_COLOR = 'Color del &Borde de Localidades'
BOX_BOX_NUMBER_COLOR = 'Color de Fondo de los &Números'

BOX_PDF_PAGE_SIZE = 'Tamaño de página: '
BOX_PDF_PAGE_SIZE_TEXT = [
  'A0',
  'A4',
  'LETTER',
]
BOX_PDF_PAGE_ORIENTATION = 'Orientación de las Páginas: '
BOX_PDF_PAGE_ORIENTATION_TEXT = [
  'Landscape',
  'Portrait',
]
BOX_PDF_LOCATIONNOS = 'Incluya números de ubicación'

MSG_SAVE_MAP_AS_SVG                        = 'Grabar Mapa como (SVG)'
FMT_SVG                                    = 'Gráfico de Vector Estructurado (*.svg)'
MENU_EXPORT_SVG                            = "Exportar como &SVG...\t\tExportar mapa como documento de Gráfico de Vector Estructurado (SVG)."
MSG_SVG_EXPORTING                          = 'Exporting SVG file'
MSG_SVG_GENERATOR                          = "Generator: #{PROGRAM_NAME} v#{VERSION} by #{AUTHOR}"
MSG_SVG_GENERATION_DATE                    = "Generation Date:"
MSG_SVG_CREATOR_PREFIX                     = 'Creator: '
MSG_SVG_SHORTCUT_TO                        = 'Shortcut to'
MSG_SVG_BGROUND_IMAGE_SECT_BEGINS          = 'BACKGROUND IMAGE SECTION BEGINS'
MSG_SVG_BGROUND_IMAGE_SECT_ENDS            = 'BACKGROUND IMAGE SECTION ENDS'
MSG_SVG_BGROUND_IMAGE_ENABLE_COMMENT_START = 'UNCOMMENT LINE BELOW TO ENABLE'
MSG_SVG_BGROUND_IMAGE_ENABLE_COMMENT_END   = 'BACKGROUND IMAGE'
MSG_SVG_MAP_SECT_BEGINS                    = 'MAP SECTION BEGINS'
MSG_SVG_MAP_SECT_ENDS                      = 'MAP SECTION ENDS'
MSG_SVG_EXPORT_COMPLETED                   = 'Exporting SVG Completed'
BOX_SVG_SHOWLOCNUMS                        = "Mostar números de ubicación"
BOX_SVG_SHOWLOCNUMS_TOOLTIP                = "Include each Room's Location Number in exported map"
BOX_SVG_SHOWINTERTITLE                     = "Mostrar Información Interactiva del Lugar:"
BOX_SVG_SHOWINTEROBJECTS                   = "Objects"
BOX_SVG_SHOWINTEROBJECTS_TOOLTIP           = "Include the Objects at each Room's Location as drop-down in exported map"
BOX_SVG_SHOWINTERTASKS                     = "Tasks"
BOX_SVG_SHOWINTERTASKS_TOOLTIP             = "Include the Tasks at each Room's Location as drop-down in exported map"
BOX_SVG_SHOWINTERCOMMENTS                  = "Comments"
BOX_SVG_SHOWINTERCOMMENTS_TOOLTIP          = "Include the Comments at each Room's Location as drop-down in exported map"
BOX_SVG_SHOWINTERDESCRIPTION               = "Description"
BOX_SVG_SHOWINTERDESCRIPTION_TOOLTIP       = "Include the Description at each Room's Location as drop-down in exported map"

BOX_SVG_EXPORTALLCOMBINED                  = "All Sections to Combined SVG file"
BOX_SVG_EXPORTALLCOMBINED_TOOLTIP          = "All Sections exported to a single SVG file, in order"
BOX_SVG_EXPORTALLINDIV                     = "All Sections to Individual SVG files"
BOX_SVG_EXPORTALLINDIV_TOOLTIP             = "All Sections exported to separate SVG files"
BOX_SVG_EXPORTCURRENTINDIV                 = "Current Section to Individual SVG file"
BOX_SVG_EXPORTCURRENTINDIV_TOOLTIP         = "Current Section exported to a single SVG file"

BOX_SVG_EXPORTSELONLY                      = "Only Include Currently Selected Elements"
BOX_SVG_EXPORTSELONLY_TOOLTIP              = "Select some Locations and/or Connections in the Current Section,\nthen use this option to ensure that only these elements, along\nwith Location no. 1 are included in the exported map"
BOX_SVG_EXPORTALLLOCSSELTXT                = "Include All Locations, Only Show Location\nText For Currently Selected Locations"
BOX_SVG_EXPORTALLLOCSSELTXT_TOOLTIP        = "The exported map will contain all Locations in the Current Section.\nLocation no. 1 and any Locations currently selected will have their Location Text included.\nOnly Connections that are currently selected will be included in the map"

BOX_SVG_SHOWLOCTEXT                        = "Mostrar el Texto del Lugar"
BOX_SVG_SHOWLOCTEXT_TOOLTIP                = "Include each Room's Location text in exported map"
BOX_SVG_SHOWSECTCOMMENTS                   = "Mostrar los Comentarios de la Sección"
BOX_SVG_SHOWSECTCOMMENTS_TOOLTIP           = "Include each Section Comments under corresponding Section Name in exported map"
BOX_SVG_COMPASSSIZE                        = "Tamaño de Brújula: "
BOX_SVG_COMPASSSIZE_TOOLTIP                = "Size of Compass graphic, from non-existent to huge, in exported map"
BOX_SVG_CONNTHICKNESS                      = "Grosor de las Líneas: "
BOX_SVG_CONNTHICKNESS_TOOLTIP              = "Thickness of Connection lines, from non-existent to heavy, in exported map"
BOX_SVG_COLOURSCHEME                       = "Esquema de Color: "
BOX_SVG_COLOURSCHEME_TOOLTIP               = "A basic Colour Scheme used for the location number, interactive\nlocation information and doors in exported map"
BOX_SVG_LOCTHICKNESS                       = "Location Thickness:"
BOX_SVG_LOCTHICKNESS_TOOLTIP               = "Thickness of Location lines, from thin to heavy, in exported map"
BOX_SVG_COLOURSCHEME_OPTIONS = [
  'Red',
  'Green',
  'Yellow',
  'Blue',
]

########### Botones
BUTTON_YES = '&Sí'
BUTTON_NO  = '&No'
BUTTON_CANCEL = '&Cancelar'
BUTTON_ACCEPT = '&Aceptar'

########### Íconos
ICON_NEW     = "\tNuevo\tCrear nuevo mapa."
ICON_OPEN    = "\tAbrir\tAbrir archivo de mapa."
ICON_SAVE    = "\tGrabar\tGrabar mapa."
ICON_SAVE_AS = "\tGrabar Como\tGrabar mapa a otro archivo."
ICON_PRINT   = "\tImprimir Mapa\tImprimir mapa (como gráfico)."
ICON_CUT     = "\tCortar"
ICON_COPY    = "\tCopiar"
ICON_PASTE   = "\tPegar"
ICON_ZOOM_IN  = "+\tAcercar"
ICON_ZOOM_OUT = "-\tAlejar"
ICON_PREV_SECTION = "\tSección Previa"
ICON_NEXT_SECTION = "\tSección Próxima"

########### Drawings

# Texto cerca de conexión (para indicar otra dirección)
DRAW_EXIT_TEXT = [
  '',
  'A',
  'B',
  'E',
  'S'
]

class Room
  DIRECTIONS = [
    'n',
    'ne',
    'e',
    'se',
    's',
    'so',
    'o',
    'no',
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

AUTOMAP_IS_WAITING_FOR_MORE_TEXT = "Automap está esperando más texto."
