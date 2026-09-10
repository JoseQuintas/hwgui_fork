#include "hwgui.ch"

PROCEDURE Main()
   LOCAL oRtf, cPathImg := ""
   LOCAL aFonts := { "Arial", "Courier New" }
   LOCAL aTblMerge := {}
   LOCAL aHeadersA, aHeadersB

   HB_SYMBOL_UNUSED( aTblMerge )
   HB_SYMBOL_UNUSED( cPathImg )

   oRtf := RichText():New( "All_Features_Combined.rtf", aFonts )
   IF oRtf:hFile < 0
      ? "Error: Unable to create output file."
      RETURN
   ENDIF

   // PageSetup( nLeft, nRight, nTop, nBottom,  → margins in INCHES
   //            nWidth, nHeight,                → paper size in INCHES
   //            nTabWidth,                      → tab in INCHES
   //            ... )
   oRtf:PageSetup( 1, 1, 1, 1, 8.5, 11, 0.5, .F., .T., "", 0, .F. )
   oRtf:BeginStly()
   oRtf:IncStyle( "Report Title",   "PARAGRAPH", 1, 16, 0, "B", "CENTER" )
   oRtf:IncStyle( "Section Header", "PARAGRAPH", 1, 12, 0, "B", "LEFT"   )
   oRtf:WriteStly()

   // =======================================================================
   // PART 1: ADVANCED TABLE CELL MERGING SCHEMES
   // =======================================================================
   oRtf:ParaStyle( 2 )
   oRtf:Write( "Complex Matrix Generation and Advanced Column Merging" )
   oRtf:NewLine()

   oRtf:ParaStyle( 3 )
   oRtf:Write( "Scenario A: Multi-Tiered Header with Fractional Cell Joins" )
   oRtf:NewLine()

   aTblMerge := { ;
      { {1, 2}, {3, 4} }, ;
      {}                  ;
   }

   aHeadersA := { ;
      { "Product Meta Diagnostics", "", "Financial Metrics Control", "" }, ;
      { "SKU ID", "Item Description Data", "Cost (USD)", "Retail (USD)" } ;
   }

   oRtf:DefNewTable( "CENTER", 1, 10, "", "CENTER", 4, 4, 350, ;
                     {1.5, 2.5, 1.5, 1.5}, "SINGLE", "SINGLE",, ;
                     0, 2, aHeadersA, 350, 1500, 1, 10, "B", "CENTER", ;
                     0, 0, aTblMerge )

   oRtf:TableCell( "001" )
   oRtf:TableCell( "Mechanical Backlit RGB Keyboard" )
   oRtf:TableCell( "45.00" )
   oRtf:TableCell( "119.99" )

   oRtf:TableCell( "002" )
   oRtf:TableCell( "Wireless Ergonomic Precision Mouse" )
   oRtf:TableCell( "18.50" )
   oRtf:TableCell( "49.95" )
   oRtf:EndTable()
   oRtf:NewLine()
   oRtf:NewLine()

   oRtf:ParaStyle( 3 )
   oRtf:Write( "Scenario B: Absolute Merging (Full-Width Span Banner Cell)" )
   oRtf:NewLine()

   aTblMerge := { ;
      { {1, 2, 3} } ;
   }
   aHeadersB := { ;
      { "RESTRICTED INTERNAL INVENTORY LOGISTICS CONTROL BANNER", "", "" } ;
   }

   oRtf:DefNewTable( "CENTER", 1, 10, "", "CENTER", 3, 3, 350, ;
                     {2.0, 3.0, 2.0}, "SINGLE", "SINGLE",, ;
                     0, 1, aHeadersB, 400, 2000, 1, 11, "B", "CENTER", ;
                     0, 0, aTblMerge )

   oRtf:TableCell( "ASSET-882" )
   oRtf:TableCell( "High-Density Data Center Rack Enclosure" )
   oRtf:TableCell( "Active Deployment" )
   oRtf:EndTable()

   oRtf:NewPage()

   // =======================================================================
   // PART 2: GRAPHICAL ASSET EMBEDDING (IMAGE)
   // =======================================================================
   oRtf:ParaStyle( 2 )
   oRtf:Write( "Graphical Image Rendering Stream Integration Options" )
   oRtf:NewLine()

   oRtf:ParaStyle( 3 )
   oRtf:Write( "1. Embedded Native Stream Asset Inline (3.0in x 2.0in):" )
   oRtf:NewLine()

   cPathImg := StrTran( hb_dirBase() + "image/hwgui.png", "/", "\" )
   IF ! File( cPathImg )
      hwg_msginfo( "ERRO CRITICO: Arquivo nao encontrado em: " + cPathImg )
      RETURN
   ENDIF

   // 5th parameter: .F. means "no absolute framing", so the image flows
   // naturally inside the paragraph.
   oRtf:Image( cPathImg, {3.0, 2.0}, 1, .F., .T., .F. )
   oRtf:NewLine()

   // -----------------------------------------------------------------------
   // Note on linked pictures:
   // \field INCLUDEPICTURE is a Word-only feature. WordPad and most other
   // RTF readers will NOT render linked images, and they introduce security
   // prompts. Keep inline (\pict) embedding for maximum compatibility.
   // -----------------------------------------------------------------------

   oRtf:End()
   ? "RTF generation complete."

RETURN
