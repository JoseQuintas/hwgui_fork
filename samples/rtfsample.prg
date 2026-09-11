#include "hwgui.ch"

/*-----------------------------------------------------------------------
   RichText class - complete usage sample
   Demonstrates: document metadata, page setup, paragraph/character
   styles, colors (text + table header background), tables with cell
   merging, and embedded (not just linked) image insertion.

   Color table (fixed, from RichText:SetClrTab() - pass the INDEX,
   1 to 16, wherever a method expects a "color" parameter):
      1  Black          6  Purple         11 Green
      2  Navy           7  Olive          12 Cyan
      3  Dark Green     8  Silver         13 Red
      4  Teal           9  Gray           14 Magenta
      5  Dark Red      10  Blue           15 Yellow
                                          16  White
-----------------------------------------------------------------------*/

PROCEDURE Main()
   LOCAL oRtf, cPathImg := ""
   LOCAL aFonts := { "Arial", "Courier New" }
   LOCAL aTblMerge := {}
   LOCAL aHeadersA, aHeadersB
   LOCAL aColorNames, i

   HB_SYMBOL_UNUSED( aTblMerge )
   HB_SYMBOL_UNUSED( cPathImg )

   oRtf := RichText():New( "All_Features_Combined.rtf", aFonts )
   IF oRtf:hFile < 0
      ? "Error: Unable to create output file."
      RETURN
   ENDIF

   // --- Document metadata (shows up in Word/WordPad "Properties") -----
   oRtf:InfoDoc( "All Features Combined - RichText Sample", ;
                 "Demonstration of the RichText class", ;
                 "HWGUI Team", , "HWGUI", , "Sample", "rtf,demo,hwgui" )

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
   // PART 1: ADVANCED TABLE CELL MERGING SCHEMES  (+ colored header row)
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

   // nTblHdColor (23rd param) = 2  -> Navy background on header cells
   // nTblHdFColor (24th param) = 16 -> White text on header cells
   //
   // NOTE: there is a deliberate empty slot for lTblNoSplit (14th param,
   // between nCellPct and nTblHdRows) below. The original sample omitted
   // it, which silently shifted every following argument one position to
   // the left - aHeadersA (meant for aHeadTit, 16th) landed in nTblHdRows
   // (15th, a number) instead, and aTblMerge (meant for aTblCJoin, 25th)
   // landed in nTblHdFColor's slot - so the table headers and the column
   // merging (the whole point of this demo) were never actually applied.
   oRtf:DefNewTable( "CENTER", 1, 10, "", "CENTER", 4, 4, 350, ;
                     {1.5, 2.5, 1.5, 1.5}, "SINGLE", "SINGLE",, ;
                     0, , 2, aHeadersA, 350, 1500, 1, 10, "B", "CENTER", ;
                     2, 16, aTblMerge )

   oRtf:TableCell( "001" )
   oRtf:TableCell( "Mechanical Backlit RGB Keyboard" )
   oRtf:TableCell( "45.00" )
   oRtf:TableCell( "119.99" )

   oRtf:TableCell( "002" )
   oRtf:TableCell( "Wireless Ergonomic Precision Mouse" )
   oRtf:TableCell( "18.50" )
   // Highlight a single value in red, using its own color, then restore
   oRtf:SetFontColor( 13 )
   oRtf:TableCell( "49.95" )
   oRtf:SetFontColor( 1 )
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

   // nTblHdColor = 5 -> Dark Red background, nTblHdFColor = 16 -> White text
   // (same missing-lTblNoSplit fix as Scenario A above)
   oRtf:DefNewTable( "CENTER", 1, 10, "", "CENTER", 3, 3, 350, ;
                     {2.0, 3.0, 2.0}, "SINGLE", "SINGLE",, ;
                     0, , 1, aHeadersB, 400, 2000, 1, 11, "B", "CENTER", ;
                     5, 16, aTblMerge )

   oRtf:TableCell( "ASSET-882" )
   oRtf:TableCell( "High-Density Data Center Rack Enclosure" )
   oRtf:TableCell( "Active Deployment" )
   oRtf:EndTable()

   oRtf:NewPage()

   // =======================================================================
   // PART 2: TEXT COLORS
   // =======================================================================
   oRtf:ParaStyle( 2 )
   oRtf:Write( "Text Colors" )
   oRtf:NewLine()

   oRtf:ParaStyle( 3 )
   oRtf:Write( "Palette Reference (RichText:SetClrTab index -> name)" )
   oRtf:NewLine()

   aColorNames := { "Black", "Navy", "Dark Green", "Teal", "Dark Red", ;
      "Purple", "Olive", "Silver", "Gray", "Blue", "Green", "Cyan", ;
      "Red", "Magenta", "Yellow", "White" }

   FOR i := 1 TO Len( aColorNames )
      oRtf:SetFontColor( i )
      oRtf:Write( hb_ntos( i ) + "=" + aColorNames[ i ] + "   " )
   NEXT
   oRtf:SetFontColor( 1 )
   oRtf:NewLine()
   oRtf:NewLine()

   oRtf:ParaStyle( 3 )
   oRtf:Write( "Mixing colors and sizes inside the same line: " )
   oRtf:SetFontColor( 13 )
   oRtf:SetFontSize( 16 )
   oRtf:Write( "Warning" )
   oRtf:SetFontSize( 10 )
   oRtf:SetFontColor( 1 )
   oRtf:Write( " (red, larger) - " )
   oRtf:SetFontColor( 3 )
   oRtf:Write( "OK" )
   oRtf:SetFontColor( 1 )
   oRtf:Write( " (dark green) - back to normal black text." )
   oRtf:NewLine()
   oRtf:NewLine()

   // =======================================================================
   // PART 3: GRAPHICAL ASSET EMBEDDING (IMAGE)
   // =======================================================================
   oRtf:ParaStyle( 2 )
   oRtf:Write( "Graphical Image Rendering Stream Integration Options" )
   oRtf:NewLine()

   oRtf:ParaStyle( 3 )
   oRtf:Write( "1. Embedded Native Stream Asset Inline (3.0in x 2.0in):" )
   oRtf:NewLine()

   cPathImg := StrTran( hb_dirBase() + "image/hwgui.png", "/", "\" )
   IF ! File( cPathImg )
      ? "Warning: image not found at " + cPathImg + " - skipping image section."
   ELSE
      // 5th parameter (lInclude): .T. actually EMBEDS the image bytes in
      // the RTF (\pict). Leaving it .F. (the default) only LINKS to the
      // external file path via an INCLUDEPICTURE field, which most RTF
      // readers other than Word will not render - see note below.
      oRtf:Image( cPathImg, {3.0, 2.0}, 1, .F., .T., .F. )
      oRtf:NewLine()
   ENDIF

   // -----------------------------------------------------------------------
   // Note on linked pictures:
   // \field INCLUDEPICTURE is a Word-only feature. WordPad and most other
   // RTF readers will NOT render linked images, and they introduce security
   // prompts. Keep inline (\pict) embedding (lInclude := .T.) for maximum
   // compatibility.
   // -----------------------------------------------------------------------

   oRtf:End()
   ? "RTF generation complete: " + oRtf:cFileName

RETURN
