**
** First of all, run setup...
**

The file obj-XX.rcp (replace XX by your country abbreviation)
generated in this directory contains all the textual language
dependent resources for Ma Tirelire 2.

The contents of this file is in english by default. So you have to
translate each string in your language without alterate the structure
of the file.

You can find 3 kinds of line:

1. "$Trans-Clear"       = "Clear."

   Simple string: translate "Clear." in your language. Don't alter
   "$Trans-Clear" string nor erase the = char.

   If a comment like /* 24 chars max */ is present, don't store more
   characters than 24 in the string otherwise Ma Tirelire 2 will crash
   when this string will be used.

2. [$Trans-DebitCredit]	= ["Debit"
                           "Credit"]

   Strings list: translate "Debit and "Credit" in your language. Like
   previous one, don't alter anything else. So don't remove or add a
   line in a list or the behavior of Ma Tirelire 2 will be
   unpredicable...

3. [$Strings-New-Width]	= 27	/* Width of "New" button in pixels */

   Position or width in pixels: change the number to adjust the
   position or the size of graphic object on the screen. In /* ... */
   you can find a small description of the function of this number,
   like here. Change only the number and nothing else... Probably you
   have to make some tests to set the good value.


To test your translation, launch compile.bat:

C:\XXX> compile

or double-click on windows explorer, it's same and easier...


Don't forget to send me your language (in your language: français for
french, italiano for italian for example), your name and if you want
your email address. So I can add your name in the translators popup in
the About dialog...

PLEASE, DON'T DISTRIBUTE THE COMPILED PROGRAM. Let me reassemble all
the foreign languages to make some verifications and make a new
release...

Send me an email at info@Ma-Tirelire.net if you encounter any problem
to understand this file or use this kit...

Thank's a lot...

Max.
