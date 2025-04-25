Readme for HWGUI Designer
~~~~~~~~~~~~~~~~~~~~~~~~~

  $Id$

Additional information by DF7BE:

The HWGUI designer is not completely ported to LINUX.
So the designer works only at the best on Windows platform.
We will deliver the port to LINUX as soon as possible
(Sorry).

Open an XML form file created on Windows, so most
elements are not visible. This severe bug must be fixed at first.

A special comment by A. Kressin:
Support of prg sources in the Designer is outdated. I recommend to use Designer's xml forms only.
Reference: See closed bug ticket #23:
"designer crashes at writing prg, containg a CHECKBOX element"



=== The following text translated from spanish to english (from file readme_es.txt) ===

Contents:

1. Main characteristics.
2. The files in the \hwgui\utils\designer folder
3. Some notes for HwGUI applications



1. Main characteristics.

  1.1 The set of controls is fully configurable.
     The list of controls (widgets) is placed in the file
     Special configuration with XML format. The name of
     that file is in the ini file "Designer.iml" of the
     Designer, it is currently the resource/widgets.xml.
     To add a new control or even a set of
     controls, or add the new properties/methods
     for a control is easy now - just edit the
     widgets.xml. This allows you to use the Designer not only
     for HwGUI it was based, but for any others
     applications - you can create completely new
     set of controls for your purposes.

  1.2 The Designer can be constructed not only as the
     standalone program, it can be part of another application where
     it is needed to edit 'forms' at runtime.

  1.3 Output formats are configurable due to usage
     of external ‘scripts’ (writes). The native support of the
     HwGUI format is included in the Designer code, all
     the others are included as plugins. There are currently two
     plugins.
     - to read the old .frm files
       (resource/F_text.prg) and to write the prgs
     - F_hwgprg.prg (not fully functional yet).

  1.4 The designer allows describing not only properties, the
     methods, too - so the shape description is a
     full dialogue procedure. You can read it from a
     file or string (if you previously uploaded it to the
     string from any source) the method and displays it in a
     screen:

     oForm := HFormTmpl (): Read ("testget1.xml")
     oForm:Show()

     Thus, it allows you to actually create applications managed by
     the data.

2. The files in the \hwgui\utils\ designer folder

    - designer.prg - Designer source code
    - designer.rc
    - editor.prg
    - hctrl.prg
    - hformgen.prg
    - inspect.prg

    - designer.iml - Main configuration file
      from the Designer

    - blddesig.bat - BAT to compile the Designer

    - samples\example.prg - sample source, use
        testget1.xml and testget2.xml
    - samples\bldexam.bat - BAT to compile example

    - samples\testget1.xml - example forms, created
        with Designer
    - samples\testget2.xml
    - samples\testdbf1.xml
    - samples\example.xml

    - resource/f_hwgprg.prg - script for prg output
    - resource/f_text.prg - script for old frm input

    - resource/widgets.xml - Configuration file with
      the set of 'widgets'

  There are three examples of 'forms' included - testget1.xml,
  testget2.xml and testdbf1.xml, which implements the
  functionality of the examples in
  samples/testget1.prg, samples / demoget2.prg and
  samples/demodbf. prg.

3. Some notes for HwGUI applications

  3.1 There is a 'common' line in the events of a form, it is
     think for functions, what is needed for form and what is
     you can call from any other event handler of the
     shape. Each function must be terminated with the declaration
     'ENDFUNC'. The 'Return' is not required, but can be
     used if the function should return some value.

  3.2 The shape has a 'Variables' property - you can
     add there variables, which will be declared as 'Private' when
     principle of HFormTmpl():Show() and can be used in
     all event handlers of the form.

  3.3.Each 'widget' has a 'Name' property - this is a
     object name, which will also be declared as 'Private' in
     the beginning of HFormTmpl (): Show ().

  3.4 The 'widgets', which have to correspond to items
     'GET', have a 'Varname' property - the name of the
     corresponding variable, which will also be declared as
     'Private' at the beginning of HFormTmpl():Show().

================ EOF of Readme.txt =================

