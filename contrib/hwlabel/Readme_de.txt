Readme-Datei für den Ausdruck von Adressen-Aufklebern "labels" mit "hwlabel".
  Von Wilfried Brunken, DF7BE
  Erstellt Juli 2022.

English description in file "Readme.txt" !

  $Id$

Inhalt
------

1.  Vorwort
1.1 Voraussetzungen
2.  Der Label Editor
2.1 Design-Regeln
3.  Beispielprogramm
4.  Programme übersetzen
5.  Zusätzliche Informationen
6.  Referenzen
7.  Anhang


1. Vorwort
----------
"Label" ist ein wichtiges Leistungsmerkmal für
geschäftliche Anwendungen. Es wird häufig dafür
genutzt, um Adressaufkleber für Briefe an Kunden
auszudrucken.
Im Programm CLLOG [1] wird es für den Ausdruck von Aufklebern für
QSL-Karten verwendet.
Das "label feature" ist Bestandteil von Harbour für
Console-Anwendungen und benötigt einen direkten Zugriff
auf die Drucker-Schnittstelle.
Demzufolge müssen Printer-Steuersequenzen erstellt werden,
die zum jeweils angeschlossenen Drucker passen müssen.
Diese müssen daher in die Label-Datei geschrieben werden.
Alternativ kann man Drucker-Steuersequenzen auch in einer
Drucker-Datenbank hinterlegen, was bei einigen
Programmen der Fall ist, so auch in CLLOG [1].
Somit ist diese Methode veraltet.

Der Label-Editor ist grundsätzlich implemementiert in Clipper
im Utility RL.EXE, in S'87 als LABEL.EXE.

Eine Open Source Implementierung für eine Harbour
Console Application finden bei "CLLOG" [1],
Datei "lbledit.prg" im Verzeichnis "src".
Link zu CLLOG siehe Kapitel "Internet-Links".

"hwlabel" ist die Portierung dieses Leistungsmerkmales zu HWGUI
unter Nutzung der "HWinPrn" Klasse,
damit ist es bereit für eine "Multi Platform" Anwendung und
unabhängig vom verwendeten Drucker-Modell.


1.1 Voraussetzungen
-------------------

Um dieses Modul verwenden zu können, wird die Harbour-Version,
die die Codepage "CP858" für die Unterstützung
des Euro-Währungszeichens beinhaltet, benötigt.
Diese Codepage unterstützt die Zeichensätze "Latin" für die meisten
westlichen Sprachen wie frühere Codepages CP 437 und CP850.

Es ist sehr leicht, dieses zu überprüfen:
Übersetzen Sie das folgende  HWGUI-Besipielprogramm und führen es aus:
hwgui\samples\demofunc.prg

Betätigen Sie den Knopf "hwg_Has_Win_Euro_Support":
Wenn "True" angezeigt wird, ist die eingesetzte Harbour-Version in Ordnung.
Andernfalls müssen Sie die aktuelle Harbour-Version installieren.

Unter LINUX muss das auch der Fall sein, da in der Label-Datei dieser
Zeichensatz abgespeichert wird.


2. Der Label Editor
-------------------

Der "Label Editor" wird benötigt um Label-Dateien zu erstellen und zu bearbeiten.
Es ist somit ein "Designer" für Labels.
Label-Dateien haben die Erweiterung ".lbl" und eine feste Größe von 1034 Bytes.
Den Label-Editor finden Sie in der Quelltextdatei "hwlbledt.prg".

Für eine Kompatibilität zu Clipper, ist die Codepage für Label-Dateien festgelegt zu CP858DE.
Es die selbe wie CP850 mit einer Ausnahme:
Das Euro-Währungszeichen ist 0xD5 oder CHR(213).
Dieses passt bestens für die meisten Sprachen der westlichen Welt.
Weitere Codepage-Unterstützungen sind in Planung für zukünftige Versionen von HWLABEL.
CP850/CP858 ist besser kompatibel mit den früher verwendeten Codepages CP437 für
mehrfache Sprachunterstützung.

Die Grundversion von "hwlabel" unterstützt Englisch (Default) und Deutsch.
Erlauben Sie sich, den Quellcode von "hwlabel" um (eine) weitere Sprache(n) zu erweitern.
Schicken Sie uns den erweiterten Quellcode über ein neues Support-Ticket oder per E-Mail.

Der Label-Editor enthält auch eine Hilfe-Funktion mit der
Beschreibung von Parametern und Inhalten.

Sie können den Label-Editor auch in Ihr eigenes HWGUI-Programm integrieren.
Die Anweisungen dazu (in englischer Sprache) finden Sie in den
Kommentarzeilen von "hwlbledt.prg".

Dazu noch ein wichtiger Hinweis:
Die verwendeten Codepages und Spracheinstellung  werden dem Hauptprogramm des Label-Editors übergeben:
FUNCTION hwlabel_lbledit(clangf,cCpLocWin,cCpLocLINUX,cCpLabel)
Die Beschreibung dieser Parameter und deren Default-Werte finden Sie in den Inline-Kommentaren zur
Funktion "hwlabel_translcp()".



Eine Console Version des Label-Editors ist als "lbledit.prg" zusätzlich verfügbar.
Übersetzen mit:
hbmk2 lbledit.prg.


2.1 Design-Regeln
-----------------


1.) In der aktuellen Version von  HWLABEL wird die Länge der einzelnen
    Zeilen im Inhalt noch nicht korrekt ermittelt.
    In diesem Falle wird die Breite (spaces beetween labels across) falsch dargestellt.
    Diesen Fehler werden wir so schnell wie möglich beheben.
    Wir empfehlen derzeit, vorerst nur Etiketten mit 1 Bahn (Number of labels across = 1 )
    zu verwenden.


2.) Das Ergebnis einer Inhalts-Zeile darf die Breite des Labels (width of label)
    keinesfalls überschreiten.
    Das Ergebnis von Funktions- und Macro-Aufrufen kann oft kürzer als
    die tatsächliche Länge sein.
    Wenn der Ausdruck oder das Bild in der Druckvorschau Ihren Wünschen enstpricht,
    können Sie die folgende Warnung beim Verlassen des Dialoges für die
    Bearbeitung der Inhalte getrost ignorieren:

Warnung!
Länge der Zeile nn
überschreitet möglicherweise die
Breite des Aufklebers.
Aktuelle Länge ist : nn



3. Beispielprogramm
-------------------

The Beispiel-Datenbank "customer.dbf" enthält 4 Datensätze mit erfundenen Daten
für Kunden-Kontakt:
Anrede, Name, Straße, Postleitzahl, Ort/Stadt , Bundesland , Staat, Konto-Stand.

Vollständige Struktur siehe Anhang, Tabelle 2.


Die Beispiel Label-Datei "sample.lbl" wird für einen Ausdruck aus der
Datenbank "customer.dbf" benötigt.

Das folgende Beispiel zeigt auf, wie ein Ausdruck eines Aufklebers des aktuellen Datensatz,
umgeleitet in eine Datei, zu erfolgen hat:

   LABEL FORM (l_lbl);
      TO FILE (ctempoutfile) ;    && .txt
      RECORD RECNO()




Funktionen fuer den Label-Ausdruck:
Siehe Anhang, Tabelle 3.

Druck-Vorschau dieses Beispiel-Programms sie Bild-Datei:
contrib\hwlabel\image\Hwlabel_Win PrView.png

4. Programme übersetzen
-----------------------

Sie benötigen 2 Aufrufe, jeweils für den Label-Editor und das Beispiel-Programm:

MinGW32:
  hwmk.bat hwlbledt.prg
  hwmk.bat hwlblsample.prg

Mit dem Programm "hbmk2" (LINUX und Windows):
 hbmk2 hwlbledt.hbp
 hbmk2 hwlblsample.hbp


5. Zusätzliche Informationen
----------------------------

Sie können den Label-Funktion und den Label-Editor in ihre eigene
HWGUI-Anwendung integrieren.
Lesen Sie dazu die entsprechenden Hinweise in den Kommentarzeilen der
Quelltextdateien.

Für die nächste Version von hwlabel

- Mehr als eine Bahn (Number of labels across > 2)


6. Referenzen
-------------

  [1] Projekt "CLLOG":
     https://sourceforge.net/projects/cllog/

  [2] Spence, Rick (Co-Developer of Clipper):
       Clipper Programming Guide, Second Edition Version 5.
       Microtrend Books, Slawson Communication Inc., San Marcos, CA, 1991
       ISBN 0-915391-41-4


7. Anhang
---------

Tabelle 1:
----------
Amerikanische Standardetikettenformate

 Bahnen  Zoll            mm       Breite Hoehe  l.Rand        horz.A vert.A.
         size in inch   in mm     width  height left margin

 1      3 1/2 x 15/16  88,9x23,8  35     5       0               1      0
 2      3 1/2 x 15/16  88,9x23,8  35     5       0               1      2
 3      3 1/2 x 15/16  88,9x23,8  35     5       0               1      2
 1      4 x 17/16      101,6x26,9 40     8       0               1      0
 3      3 2/10 x 11/12 81,3x23,3  32     5       0               1      2 (Cheshire)
 !                                                               !      !
 !                                                               !      v
 v                                                               v      spaces between labels
 number of labels across                                         lines between labels


 Tabelle 2: Struktur der Datenbank "customer.dbf"
 ------------------------------------------------

** structure of database customer.dbf ***
Last update 22 06 09

Data offset 290
Record size 156
Number of records 4

Number of fields 8
NAME        TYPE LEN DEC

TITLE       C    10
NAME        C    20
STREET      C    30
POSTCODE    C    10
TOWN        C    25
STATE       C    25
COUNTRY     C    25
ACCOUNT     N    10


Tabelle 3:
----------

 spezielle verkürzte Funktionsaufrufe (damit der Platz in den
 Label-Dateien und in den Filtereinstellungen besser passt)

 FUNCTION   A                 && (C)  ALLTRIM(s)
 FUNCTION   S                 && (C)  SPACE(n)
 FUNCTION   P                 && (C)  PADRIGHT(s,n)
 FUNCTION   C                 && (C)  CHR(n)
 FUNCTION   R                 && (C)  REPLICATE(s,n)
 FUNCTION   T                 && (C)  TRANSFORM(s,p)
 FUNCTION   NOSKIP            && (C)  gibt ein Zeichen 255 aus, wenn leer


FUNCTION NOSKIP(e)

 Gibt das Zeichen 255 (nicht abdruckbar)
 zurueck, wenn e leer ist (String),
 sonst wird der Inhalt von e so
 wie uebergeben, zurueckgegeben.
 Hintergrund: Zeilen die zwar
 in der LBL-Datei definiert sind,
 aber leer sind, werden nicht ausgegeben,
 ( d.h. beim Drucken unterdrueckt )
 so dass die nachfolgenden Zeilen nachruecken
 und somit das Layout nicht mehr stimmt.



Tabelle 4:
----------

Drucker-Zeichensätze:


 0   : ANSI               CP1252, ansi-0, iso8859-{1,15}
 1   : DEFAULT
 2   : SYMBOL
 77  : MAC
 128 : SHIFTJIS           CP932
 129 : HANGEUL            CP949, ksc5601.1987-0
       HANGUL
 130 : JOHAB              korean (johab) CP1361
 134 : GB2312             CP936, gb2312.1980-0
 136 : CHINESEBIG5        CP950, big5.et-0
 161 : GREEK              CP1253
 162 : TURKISH            CP1254, -iso8859-9
 163 : VIETNAMESE         CP1258
 177 : HEBREW             CP1255, -iso8859-8
 178 : ARABIC             CP1256, -iso8859-6
 186 : BALTIC             CP1257, -iso8859-13
 204 : RUSSIAN            CP1251, -iso8859-5
 222 : THAI               CP874,  -iso8859-11
 238 : EAST EUROPE        EE_CHARSET
 255 : OEM

 Die Ziffer in der linken Spalte kennzeichnet den
 numerischen Wert zur Übergabe an die
 Methode SetMode() der Klasse HWinPrn,
 Parameter nCharset.


 Escape-Sequenzen des Macro-Interpreters
 ----------------------------------------

  Die PUBLIC Variable "EC" steht für CHR(27) (Escape),
  spart Platz in der Label-Datei.

  Auf diese Weise wird ein Funktions-Aufruf wie folgt geschrieben:
  EC+"&SMA(); Small"


Tabelle 5:
----------

Referenz für "Set Modus"-Funktionen, die vom Macro-Interpreter aufgerufen werden:

FUNCTION MDE(lElite, lCond, nLineInch, lBold, lItalic, lUnder, nLineMax , nCharset)  Aufruf Methode SetMode()
FUNCTION NCH(nChars)        Zeichensatz festlegen
FUNCTION DEF()              Default
FUNCTION SMA()              Schmal
FUNCTION SML()              Schmaler
FUNCTION VSM()              Sehr schmal
FUNCTION E()                Drucke Euro-Zeichen

 Table 6:
 --------

Referenz für Druckausgaben die vom Macro-Interpreter aufgerufen werden:
(Nur interne Verwendung)

FUNCTION O_NEWLINE()        Neue Zeile
FUNCTION O_PRTTXT(ctext)    PrintText(ctext)
FUNCTION O_NPG()            Neue Seite


 Internet-Links
 --------------

 Siehe "6. Referenzen"



 Änderungsübersicht
 ------------------

  Datum (YYYY-MM-DD) SVN     Beschreibung
  ----------         ------- ----------------------------------------------------------------
  2022-07-04         r3095   Zweite Ausgabe mit Macro-Interpeter
  2022-06-16         r3079   Erste Ausgabe


================================= EOF of Readme_de.txt ================================================

