require 'tmpdir'

begin
  require 'IFMapper/PDFMapExporter_prawn'
rescue LoadError => e
  raise LoadError, e
end
