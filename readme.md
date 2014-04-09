
Spiffy Foldtext
===============

A customizable foldtext function for Vim that properly takes into account the
actual width of the displayable area of your windows. You are thus able to
right-justify a portion of it, usually meta-data like line count and fold
level.

At the center of the plugin is a special format string. By customizing its
value, you can create your own custom foldtext in a single line in your vimrc.

This plugin is meant to be drop-in-able without the need to make any
adjustments--with nice default settings that increase the clarity of your
partially folded windows. There are no functions mapped or in need of mapping.

The official repository for this plugin is located on
[bitbucket](https://bitbucket.org/atimholt/spiffy_foldtext), but a skeleton
git repository (containing just numbered releases) is kept on
[github](https://github.com/atimholt/spiffy_foldtext) for the sake of plugin
managers that don't support Mercurial, like Vundle.

## The Format String

The format string is customizable by setting the g:SpiffyFoldtext_format
variable. The format string contains control triggers and literal text
describing how your folded lines will render. For example, here's the default
(more or less):

        if has('multi_byte')
            let g:SpiffyFoldtext_format = "%c{═}  %<%f{═}╡ %4n lines ╞═%l{╤═}"
        else
            let g:SpiffyFoldtext_format = "%c{=}  %<%f{=}| %4n lines |=%l{/=}"
        endif

Or, more simply (I'll take the ascii-only version for the sake of
explanation):

        let g:SpiffyFoldtext_format = "%c{=}  %<%f{=}| %4n lines |=%l{/=}"

The plugin parses this string upon first run, then 'compiles' it to your
foldtext each time vim needs to determine what to display on a line that
represents a folded region. In a display area 70 characters wide, the above
example would make this sample text:

    Some text with a foldmarker {{{                                       ~
        Some indented text        with a wide whitespace region {{{       ~
                                                                          ~
        }}}                                                               ~
    }}}                                                                   ~

fold to look like this:

    Some text with a foldmarker {{{                                       ~
    === Some indented text ====== with a wide whitespace |    3 lines |=/=~
    }}}                                                                   ~

or this:

    Some text with a foldmarker {{{  ======================|    5 lines |=~


Here's a sampling of what some of the example translates to. See the plugin's
help (`:help spiffy_foldtext`) for more information on the rest:

###"%c{=}"

This trigger places the text of the fold region's first line into your
foldtext. As given here, its indentation and wider whitespace regions will be
filled with the `'='` character. See `:help spiffy_foldtext-%c`.

###"  "

This inserts two literal spaces.

###"%<"

This represents the split between what will be left-aligned in your foldtext
and what will be right aligned. The leftward angle bracket is meant as a
mnemonic to indicate that, should all the contents of the foldtext be too wide
for the display area, the content to the right of this trigger will overwrite
part of the content to the left. See `:help spiffy_foldtext-%<`.

###"%f{=}"

If the content of the foldtext doesn't fill up the entire display region, the
foldtext will be filled with '='s at this point, to the amount needed to
right-align the right-align section. See `:help spiffy_foldtext-%f{}`.

  etc.

## Installation

There are a few supported ways to install this plugin:

### Old style:

If you just don't care, simply copy the files into your run time and run the
command:

    :helptags $VIMRUNTIME/doc

Putting whatever directory the docs for the plugin ended up in.

This is *not* recommended. It's not even the *easiest* way nowadays. Try one of
the methods below.


### Pathogen:

Navigate to your bundle directory. By default, this will be something like
“~/.vim/bundle”.

Then run the command:

    hg clone https://bitbucket.org/atimholt/spiffy_foldtext


### Vundle:

Insert the following line into your vimrc, under the conditions described by the
Vundle documentation:

    Bundle 'atimholt/spiffy_foldtext'


### NeoBundle:

Insert the following line into your vimrc, under the conditions described by the
NeoBundle documentation:

    NeoBundle 'atimholt/spiffy_foldtext'

Or, if you want a slightly better guarantee that you really have the latest
version:

    NeoBundle 'bb:atimholt/spiffy_foldtext', {'type': 'hg'}

This still puts you in the `default` branch, which is kept stable.

### Other Plugin managers:

Other plugin managers are likely easily adapted to installing this plugin, using
instructions similar to one of the above. See your plugin manager's
documentation.

## Other Info

If you feel REALLY enthusiastic about this plugin, try contributing some code
at
[https://bitbucket.org/atimholt/spiffy_foldtext](https://bitbucket.org/atimholt/spiffy_foldtext)
But please contact me first if it's anything outside that list of features "I
feel less strongly about", as described in the file doc/spiffy_foldtext.txt.
Also, please don't be offended if I don't accept, or if I heavily modify, your
contributions. I don't want this thing to get to bloated, or to contradict its
own purpose, or whatever have you.

or even giving me money:
bitcoin:1FGQqbjSGHrQVeUc12LJY6F2g1TEDyJ7Ts
and make sure to let me know who sent it and why!

I'm not a lawyer, but let me try to make a disclaimer: Any money sent to me is
not a charitable donation, it does not guarantee work, and I'll be doing
whatever I want with it. Please don't feel the need to send me any large sums,
this is just a simple little plugin. Doesn't hurt to ask, though, eh?

This plugin is under the MIT license, full text in doc/spiffy_foldtext.txt

