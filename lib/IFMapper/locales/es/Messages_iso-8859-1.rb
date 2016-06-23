
TITLE  = '#{PROGRAM_NAME} v#{VERSION} - Programado por #{AUTHOR}'

################ Errores
ERR_NO_FOX   = 'Por favor instale la librer�a FXRuby (FOX) version 1.2 o posterior.'
ERR_HAS_GEMS = 'Puede hacerlo si corre \'gem install -r fxruby\''
ERR_NO_YAML  =<<'EOF'
Por favor instale la librer�a 'yaml'.
Sin ella, las preferencias no pueden ser cargadas ni grabadas.
EOF
ERR_COULD_NOT_SAVE = 'No pude grabar'
ERR_COULD_NOT_LOAD = 'No pude cargar'
ERR_NO_ICON        = 'No pude cargar el �cono: '
ERR_NO_PRINTING    = <<'EOF'
Lo siento, pero la impresi�n no est� implementada
en esta versi�n.
EOF
ERR_NO_FREE_ROOM   = 'Lo siento.  No hay espacio en el mapa para pegar las localidades.'
ERR_NO_MATCHES     = 'No hay coincidencias para la expresi�n'
ERR_CANNOT_AUTOMAP = 'No puedo mapear autom�ticamente.'
ERR_READ_ONLY_MAP  = "Mapa est� en Modo de Lectura Solamente.  Vaya a Datos del Mapa para cambiar esto."
ERR_CANNOT_MOVE_SELECTION = 'No puedo mover la selecci�n hacia el '
ERR_CANNOT_OPEN_TRANSCRIPT = 'No puedo abrir la transcripci�n'
ERR_PARSE_TRANSCRIPT = "Error interno interpretando transcripci�n\nPor favor rep�rtelo como un fallo del software"
ERR_COULD_NOT_OPEN_WEB_BROWSER = 'No pude abrir ning�n web browser'
ERR_PATH_FOR_CONNECTION = 'El camino de la conexi�n'
ERR_IS_BLOCKED = 'est� bloqueado'

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
MSG_MATCHES_IN_SECTION = 'en la secci�n'
MSG_FIND_LOCATION_IN_MAP = 'Buscar Localidad en el Mapa'
MSG_FIND_LOCATION_IN_SECTION = 'Buscar Localidad en esta Secci�n'
MSG_FIND_OBJECT_IN_MAP = 'Buscar Objeto en el Mapa'
MSG_FIND_TASK_IN_MAP = 'Buscar Tarea en el Mapa'
MSG_FIND_DESCRIPTION_IN_MAP = 'Buscar en las Descripciones del Mapa'
MSG_ABOUT_SOFTWARE = 'Sobre este Programa...'
MSG_ABOUT = <<'EOF'
#{PROGRAM_NAME} - #{VERSION}
Escrito por #{AUTHOR}.

Versi�n de FXRuby: #{Fox::fxrubyversion}

Una herramienta de mapeado para ficci�n interactiva.

ggarra@advancedsl.com.ar
EOF

MSG_SAVE_MAP = 'Grabar Mapa'
MSG_WAS_MODIFIED = "fue modificado.\n"
MSG_SHOULD_I_SAVE_CHANGES = '�Grabo los cambios?'

MSG_SAVE_MAP_AS_IFM = 'Grabar Mapa como Archivo IFM'
FMT_IFM             = 'Mapa IFM (*.ifm)'

MSG_SAVE_MAP_AS_INFORM = 'Grabar Mapa como Archivo Inform'
FMT_INFORM             = 'Codigo Fuente de Inform (*.inf,*.inform)'

MSG_SAVE_MAP_AS_TADS   = 'Grabar Mapa como Archivo TADS3'
FMT_TADS               = 'Codigo Fuente de TADS (*.t)'

MSG_SAVE_MAP_AS_PDF    = 'Grabar Mapa como Archivo Acrobat PDF'
FMT_PDF                = 'Acrobat PDF (*.pdf)'

MSG_HOTKEYS = <<'EOF'

BIR - Bot�n Izquierdo del Rat�n
BMR - Bot�n Medio del Rat�n
BDR - Bot�n Derecho del Rat�n

Controles del Rat�n
-------------------

Use el BIR para agregar localidades o conexiones entre ellas.

Cliqu�e con el BIR en una localidad o conexi�n para seleccionarla.

Cliqu�e Dos Veces en una localidad o conexi�n para acceder a 
sus propiedades.

Cliqu�e Varias Veces en una conexi�n existente para establecer una
conexi�n unidireccional.

Mantenga apretado el BMR o ALT + BIR y mueva el rat�n para
moverse por la p�gina.

Use la rueda del rat�n para acercarse o alejarse.

Use el BDR tras seleccionar una conexi�n y as� acceder a un menu para
invertir su direcci�n o para conectarla a otra salida de una de
las localidades.

Controles del Teclado
---------------------

Use 'x' para comenzar una conexi�n compleja (es decir, una conexi�n entre
localidades que no son vecinas), luego cliqu�e en cada salida de cada
localidad.

Use 'Supr' (Delete) or '<-' (Backspace) para borrar una conexi�n 
o localidad seleccionada.

Use las teclas de flechas del cursor o el teclado num�rico para mover 
las habitaciones seleccionadas alrededor de la p�gina, una unidad a la vez.

Use CTRL + BIR cuando agregue una conexi�n para crear una conexi�n
sin salida (una conexi�n que vuelve sobre s� misma)

EOF

MSG_LOAD_TRANSCRIPT = 'Cargar Transcripci�n'
MSG_NEW_LOCATION = 'Nueva Localidad'

MSG_OPENING_WEB_PAGE = 'Abriendo p�gina web'

TRANSCRIPT_EXPLANATION_TEXT = [
"Modo Cl�sico espera un encabezado para todas las localidades,
donde todas las palabras de 5 o m�s letras aparecen en
may�sculas y donde no hay ning�n punto.  
Los comandos siempre comienzan tras un >.",
"Modo May�sculas espera un encabezado para todas las localidades,
donde s�lo la primera palabra necesita estar en may�sculas y
donde no hay ning�n punto.  
Los comandos siempre comienzan tras un >.",
"Modo Moonmist describe las localidades en parentesis, con un 'You
are...' como prefijo y un punto al final de la oraci�n, dentro de
los parentesis.
Los comandos siempre comienzan tras un >.",
"Modo Witness espera las localidades descriptas como prosa normal
usando 'You are...' como p�rrafo introductorio.  En modo simple, 
las localidades se describen en par�ntesis.
Los comandos siempre comienzan tras un >.",
"Modo ADRIFT espera las localidades como en el modo Cl�sico
(encabezados de palabras de 5 o m�s letras en may�sculas).
Los comandos comienzan s�lo con una palabra en min�scula sin margen.",
]


TRANSCRIPT_LOCATION_TEXT = [
"
> mira
Al Oeste de la Casa
Est�s parado en un campo abierto al oeste de una casa blanca, con una
puerta clausurada.
",
"
> mira
Vestidor de mujeres
Tus tacos resuenan fuertemente en las baldosas, y su eco rebota en las
filas de casilleros alineados a los lados de la habitaci�n.
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
    Aunque veh�culos de cuatro ruedas pasan por aqu�, este lugar aut�nomo 
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
  'Cl�sico',
  'May�sculas',
  'Moonmist',
  'Witness',
  'ADRIFT',
]

############ T�tulos de Ventanas
TITLE_READ_ONLY = '[S�lo Lectura]'
TITLE_AUTOMAP   = '[Mapeado Autom�tico]'
TITLE_ZOOM      = 'Acercamiento:'
TITLE_SECTION   = 'Secci�n'
TITLE_OF        = 'de'

############ Extensions
EXT_TRANSCRIPT = 'Archivo de Transcripci�n (*.log,*.scr,*.txt)'
EXT_ALL_FILES  = 'Todos los Archivos (*)'
EXT_MAP_FILES  = 'Archivos de Mapas'

############ Status messages
MSG_COMPLEX_CONNECTION = "Cliqu�e en la salida de la primera localidad de la conexi�n compleja."
MSG_COMPLEX_CONNECTION_OTHER_EXIT = "Cliqu�e en la otra salida de la conexi�n compleja."
MSG_COMPLEX_CONNECTION_STOPPED = 'Creaci�n de la conexi�n compleja interrumpida.'
MSG_COMPLEX_CONNECTION_DONE = 'Conexi�n compleja completada.'

MSG_CLICK_TO_SELECT_AND_MOVE = 'Cliqu�e para seleccionar y mover.  Cliqu�e dos veces para editar.'
MSG_CLICK_CHANGE_DIR  = 'Cliqu�e para cambiar direcci�n de la conexi�n.'
MSG_CLICK_CREATE_ROOM = 'Cliqu�e para crear una nueva localidad.'
MSG_CLICK_CREATE_LINK = 'Cliqu�e para crear una nueva conexi�n.'

############ Warnings
WARN_DELETE_SECTION = 'Est� seguro que quiere borrar esta secci�n?'
WARN_OVERWRITE_MAP  = 'ya existe.  �Est� seguro que quiere sobreescribirlo?'
WARN_MAP_SMALL = "Al cambiar el tama�o del mapa,\nalgunas localidades quedar�n afuera del mismo.\nEstas localidades ser�n borradas.\n�Est� seguro que quiere hacer esto?"

############ Menus
MENU_FILE    = '&Archivo'
MENU_NEW     = "&Nuevo...\tCtl-N\tCrear un nuevo mapa."
MENU_OPEN    = "&Abrir...\tCtl-A\tAbrir un mapa."
MENU_SAVE    = "&Grabar\tCtl-G\tGrabar un mapa."
MENU_SAVE_AS = "Grabar &Como...\t\tGrabar mapa en otro archivo."

MENU_EXPORT  = 'Exportar'
MENU_EXPORT_PDF    = "&Exportar como PDF...\t\tExportar mapa como documento Acrobat PDF."
MENU_EXPORT_IFM    = "&Exportar como IFM...\t\tExportar mapa como un archivo IFM."
MENU_EXPORT_INFORM = "&Exportar como C�digo Fuente de Inform...\t\tExportar mapa como un c�digo fuente de Inform."
MENU_EXPORT_TADS = "&Exportar como C�digo Fuente de TADS3...\t\tExportar mapa como un c�digo fuente de TADS3."

MENU_PRINT = 'Imprimir'
MENU_PRINT_MAP = "&Mapa...\t\tImprimir mapa (como gr�fico)."
MENU_PRINT_LOCATIONS = "&Localidades...\t\tImprimir las localidades del mapa como una lista."

MENU_QUIT = "&Salir\tCtl-S\tSalir de la aplicaci�n."


MENU_EDIT  = '&Editar'
MENU_COPY  = "&Copiar\tCtl-C\tCopiar Localidad"
MENU_CUT   = "Cor&tar\tCtl-X\tCortar Localidad"
MENU_PASTE = "&Pegar\tCtl-V\tPegar Localidad"

MENU_MAP   = '&Mapa'
MENU_SELECT = 'Seleccionar'
MENU_SELECT_ALL  = "&Todo\tAlt-A\tSeleccionar todas las localidades y conexiones en la secci�n"
MENU_SELECT_NONE = "&Nada\tAlt-N\tDeseleccionar todo en la secci�n actual."

MENU_SEARCH = 'Buscar'
MENU_SEARCH_MAP = "&Localidad en el Mapa\tCtl-B\tBuscar una Localidad en el Mapa"
MENU_SEARCH_SECTION = "Localidad en la &Secci�n\tAlt-B\tBuscar una Localidad en la Secci�n Actual"
MENU_SEARCH_OBJECT = "&Objeto en el Map\tAlt-O\tBuscar Localidad con un Objeto en el Mapa"
MENU_SEARCH_TASK = "&Tarea en el Mapa\tAlt-T\tBuscar Localidad con una Tarea en el Mapa"
MENU_SEARCH_DESCRIPTION = "&Palabra en las Descripciones\tAlt-D\tBuscar Localidad en el Mapa con una Palabra en la Descripci�n"

MENU_COMPLEX_CONNECTION = "Cone&xiones Complejas\tx\tCrear una conexi�n compleja."
MENU_DELETE = "Borrar\tDel\tBorrar las localidades seleccionadas o las conexiones."

MENU_MAP_INFO  = "Datos del Mapa\t\tCambiar los datos del mapa."
MENU_ROOM_LIST = "Lista de Localidades\t\tLista de todas las localidades en el mapa."


MENU_AUTOMAP = 'Mapeado Autom�tico'
MENU_AUTOMAP_START = "&Comenzar...\tCtl-T\tComenzar a crear el mapa de un archivo de transcripci�n de juego."
MENU_AUTOMAP_STOP = "D&etener...\tCtl-P\tDetener creaci�n autom�tica del mapa."
MENU_AUTOMAP_PROPERTIES = "&Propiedades...\tCtl-H\tPropiedades de la Transcripci�n del Juego."


MENU_SECTIONS = 'Secciones'
MENU_NEXT_SECTION = "Secci�n Pr�xima\t\tIr a la Secci�n Pr�xima del Mapa."
MENU_PREVIOUS_SECTION = "Secci�n Previa\t\tIr a la Secci�n Previa del Mapa."
MENU_ADD_SECTION = "Agregar Secci�n\t\tAgregar una Nueva Secci�n al Mapa."
MENU_RENAME_SECTION = "Renombrar Secci�n\t\tRenombrar Secci�n Actual."
MENU_DELETE_SECTION = "Borrar Secci�n\t\tBorrar Secci�n Actual del Mapa."


MENU_ZOOM_PERCENT = '#{v}%\t\tAcercamiento de la p�gina al #{v}%.'
MENU_ZOOM = 'Acercamiento'


MENU_OPTIONS = 'Opciones'
MENU_EDIT_ON_CREATION = "Editar al Crear\t\tEditar localidades al crearlas."
MENU_AUTOMATIC_CONNECTION = "Conexi�n Autom�tica\t\tConectar nueva localidad a la anterior adjacente."
MENU_CREATE_ON_CONNECTION = "Crear al Conectar\t\tCrear localidades faltantes al crear una conexion."


MENU_DISPLAY = 'Representaci�n Visual'
MENU_USE_ROOM_CURSOR = "Usar Cursor de Localidades\t\tHace que tu flecha del rat�n muestre la direcci�n de una salida."
MENU_PATHS_AS_CURVES = "Caminos como Curvas\t\tDibuja caminos complejos como curvas."
MENU_LOCATION_NUMBERS = "Numeraci�n de Localidades\t\tMostrar la Numeraci�n de las Localidades."
MENU_LOCATION_TASKS   = "Tareas en la Localidad\t\tMostrar Tareas al editar las Localidades."
MENU_LOCATION_DESC    = "Descripci�n de la Localidad\t\tMostrar Descripci�n de la Localidad al Editarla."
MENU_BOXES = "Rect�ngulos\t\tDibuja gu�as punteadas de localidades."
MENU_STRAIGHT_CONN    = "Conexiones Rectas\t\tDibuja gu�as punteadas para conexiones N/S/E/O"
MENU_DIAGONAL_CONN    = "Conexiones Diagonales\t\tDibuja gu�as punteadas para conexiones NO/NE/SO/SE"

MENU_PREFS = 'Preferencias'
MENU_LANGUAGE = "Lenguaje\t\tCambiar el lenguaje de la aplicaci�n."
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
MENU_RESOURCE = "&Releer C�digo Fuente"

############ Cajas de Edici�n

BOX_INSTRUCTIONS = 'Instrucciones'
BOX_HOTKEYS = 'Teclas'

BOX_ROOM_INFORMATION = 'Datos de la Localidad'
BOX_LOCATION = 'Localidad: '
BOX_OBJECTS  = 'Objetos: '
BOX_DARKNESS = 'Oscuridad'
BOX_TASKS    = 'Tareas: '
BOX_DESCRIPTION = 'Descripci�n: '

BOX_CONNECTION_TYPE = 'Tipo de Conexi�n: '
BOX_CONNECTION_TYPE_TEXT = [
  'Libre',
  'Puerta',
  'Con Llave',
  'Especial',
]
BOX_DIRECTION = 'Direcci�n: '
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
BOX_SECTION = 'Secci�n'
BOX_NAME = 'Nombre'

BOX_MAP_INFORMATION = 'Datos del Mapa'
BOX_MAP_READ_ONLY = 'S�lo Lectura'
BOX_MAP_CREATOR = 'Creador:'
BOX_MAP_WIDTH = 'Ancho'
BOX_MAP_HEIGHT = 'Alto'

BOX_TRANSCRIPT = 'Opciones de la Transcripci�n'
BOX_TRANSCRIPT_STYLE = 'Estilo de Transcripci�n: '
BOX_TRANSCRIPT_IDENTIFY = 'Identificar Localidades: '
BOX_TRANSCRIPT_EXPLANATION = 'Explicaci�n: '
BOX_TRANSCRIPT_VERBOSE = 'Ejemplo en Modo Verborr�gico: '
BOX_TRANSCRIPT_BRIEF   = 'Ejemplo en Modo Corto: '

BOX_COLOR = 'Preferencias de Color'
BOX_BG_COLOR = '&Color del Fondo'
BOX_ARROWS_COLOR = 'Color de las &Flechas'
BOX_BOX_BG_COLOR = 'Color de Fondo de las &Localidades'
BOX_BOX_DARK_COLOR = 'Color de Localidades &Oscuras'
BOX_BOX_BORDER_COLOR = 'Color del &Borde de Localidades'
BOX_BOX_NUMBER_COLOR = 'Color de Fondo de los &N�meros'

BOX_PDF_PAGE_SIZE = 'Tama�o de p�gina: '
BOX_PDF_PAGE_SIZE_TEXT = [
  'A0',
  'A4',
  'LETTER',
]
BOX_PDF_PAGE_ORIENTATION = 'Orientaci�n de las P�ginas: '
BOX_PDF_PAGE_ORIENTATION_TEXT = [
  'Landscape',
  'Portrait',
]
BOX_PDF_LOCATIONNOS = 'Incluya n�meros de ubicaci�n'

########### Botones
BUTTON_YES = '&S�'
BUTTON_NO  = '&No'
BUTTON_CANCEL = '&Cancelar'
BUTTON_ACCEPT = '&Aceptar'

########### �conos
ICON_NEW     = "\tNuevo\tCrear nuevo mapa."
ICON_OPEN    = "\tAbrir\tAbrir archivo de mapa."
ICON_SAVE    = "\tGrabar\tGrabar mapa."
ICON_SAVE_AS = "\tGrabar Como\tGrabar mapa a otro archivo."
ICON_PRINT   = "\tImprimir Mapa\tImprimir mapa (como gr�fico)."
ICON_CUT     = "\tCortar"
ICON_COPY    = "\tCopiar"
ICON_PASTE   = "\tPegar"
ICON_ZOOM_IN  = "+\tAcercar"
ICON_ZOOM_OUT = "-\tAlejar"
ICON_PREV_SECTION = "\tSecci�n Previa"
ICON_NEXT_SECTION = "\tSecci�n Pr�xima"

########### Drawings

# Texto cerca de conexi�n (para indicar otra direcci�n)
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
end