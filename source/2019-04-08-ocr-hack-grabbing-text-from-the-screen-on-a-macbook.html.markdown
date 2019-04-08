---

title: OCR Hack - grabbing text from the screen on a Macbook
date: 2019-04-08 10:51 GMT
tags: tech

---

(File under: obscure hacks that I'm blogging mostly so I can re-create them in the future when
I've forgotten what I did to make this work)

This is a neat hack I worked out a couple of months ago, while I was scanning in some recipes -
I wanted a way to easily grab some text from a photo, repeatedly - and more, I wanted to grab
a section of a page, because often recipes are laid out in strange ways, tables
of contents, big titles, and the rest.

Since then, it's turned out to be handy for other things.  Got a locked PDF you want to
grab a paragraph from?  Or a Kindle book that you want to quote?  (I have no idea how on
earth people justify locking users out of copying bits of their purchased books!  It's fair
use, folks - all I want is to quote your book, and I'm sure the real pirates can
bypass your DRM)

Anyway, I now have a nifty `scrn2txt` button on my Mac's touch bar - this is how it works:

* First, install [Tesseract](https://github.com/tesseract-ocr/tesseract/wiki) - it's as simple as `brew install tesseract`

* Next, I wrote a simple commandline wrapper script, `ocr_screenshot.sh` in my standard scripts directory:

~~~bash
#!/bin/bash -e
tesseract $1 /tmp/out -l eng
cat /tmp/out.txt | pbcopy
~~~

* I run [Better Touch Tool](https://folivora.ai/) - a very nice tool for scripting the touch bar, as well as lots of
other nice hacks (like window tiling, special hotkeys and lots of other things).  It's quite easy to set up
a hotkey to run the above script:

    1. Create a new button set up as "capture screenshot - configurable"
![better touch tool screenshot"](2019-04-08-ocr-hack-grabbing-text-from-the-screen-on-a-macbook/image1.png)

    1. Capture the screenshot to a fixed file - `/tmp/tmp_screenshot` in my example
![better touch tool screenshot"](2019-04-08-ocr-hack-grabbing-text-from-the-screen-on-a-macbook/image2.png)

    1. Run the script above as `ocr_screenshot.sh {filepath}` - this will pass the filename to the script
![better touch tool screenshot"](2019-04-08-ocr-hack-grabbing-text-from-the-screen-on-a-macbook/image3.png)

    1. Save the button!

The result is a nice little button on my touchbar - when I press it, it prompts me to select a rectangle of the screen, saves it as a bitmap to `/tmp/tmp_screenshot.png`, calls `tesseract` to OCR it to text, and then `pbcopy` to put it on my clipboard.

Tesseract seems pretty powerful too - it happily grabs text from slightly skewed image files, and any minor mistakes are easy to fix.

I hope this is useful to someone!
