# ShellActions.sugar

ShellActions.sugar enables you to add custom text and file actions to Espresso written in any language that can run as a shell script (bash, sh, ruby, python, etc.). Note that ShellActions.sugar does not add any new actions when you install it; it merely enables you to create custom actions in your language of choice. Some third-party Sugars (known examples listed below) may require it to run.

## Installation

**Requires Espresso 2**

1. [Download ShellActions.sugar](http://onecrayon.com/downloads/ShellActions.sugar.zip)
2. Unzip the downloaded file (if your browser doesn't do it for you)
3. Double click the ShellActions.sugar file to install it

### Known Sugars that require ShellActions.sugar

* [HTMLBundle.sugar](https://github.com/onecrayon/HTMLBundle.sugar)
* [Prefixr.sugar](https://github.com/onecrayon/Prefixr.sugar)

## Writing your own shell actions

There are two parts to writing a custom shell script to add functionality to Espresso:

1. The XML action definition
2. The shell script itself

### XML action definition

You can, of course, use any of the elements available in [Action XML definitions](http://wiki.macrabbit.com/index/ActionXML/), but these are the ones that are specific to shell actions:

    <action name="action.id" category="category.id">
        <!--REQUIRED-->
        <class>OCShellAction</class>
        
        <setup>
            <!--REQUIRED-->
            <script>my_script.py</script>
            
            <!--Available for all types of actions; default values shown-->
            <!--These say if your script can handle these scenarios or not-->
            <multiple-selections>true</multiple-selections>
            <single-selection>true</single-selection>
            <empty-selection>true</empty-selection>
            <!--Only set this to `false` if you want to be slapped in the face with errors-->
            <suppress-errors>true</suppress-errors>
            
            <!--Applicable mainly for TextActions; default values shown-->
            <input>selection</input>
            <alternate>document</alternate>
            <output>input</output>
            <output-format>text</output-format>
        </setup>
    </action>

* `<script>`: your script's filename. Scripts must be stored in your Sugar's root-level Scripts folder
* selection elements: these all default to true. Set one to `false` to disable this action in that scenario. For instance, if you include `<empty-selection>false</empty-selection>` your action will be disabled unless there is at least one selection.
* `<suppress-errors>`: if you set this as `false`, any errors that occur will open a dialog in Espresso. Only useful for debugging, typically.
* `<input>`: what will be passed to STDIN. Accepts:
    * _selection_ (default)
    * _document_
    * _nothing_
* `<alternate>`: if your input is `selection`, this will be used as the fallback if there is no selection. Accepts:
    * _document_
    * _line_ (the line around the cursor)
    * _word_ (the word around the cursor)
    * _character_ (the character immediately to the left of the cursor)
* `<output>`: what your script will output. Accepts:
    * _input_ (default): STDOUT will replace the input
    * _document_: STDOUT will replace the document
    * _range_: STDOUT will represent one or more ranges to select. Formatting for ranges is `index,length`. So if you wanted to select the first ten characters of the document you would output `0,10`. You can select multiple ranges by separating them with a linebreak or `&` character: `0,10&12,5`
    * _log_: STDOUT will be output straight to Console.app
    * _html_: STDOUT will be rendered as HTML in a new window. Any relative URLs will resolve using EDITOR\_SUGAR\_PATH as the base URL (so you can store shared CSS or images in your Sugar). Any links clicked will open in the user's default browser, although unadorned anchor links will work to navigate within the page (for instance, `<a href="#top">To top</a>` will not open a browser).
    * _console_: STDOUT will be displayed as plain text in a new window
    * _nothing_: STDOUT will be ignored
* `<output-format>`: only necessary if using `input` or `document` for your output. Specifies the format you are outputting:
    * _text_ (default): contents of STDOUT will be inserted as plain text
    * _snippet_: contents of STDOUT will be inserte as a CETextSnippet. **Note:** if the user has multiple selections, your output will be automatically aggregated into a single snippet and overwrite the whole range (leaving text between the existing selections alone). Make good use of the EDITOR\_SELECTIONS\_TOTAL and EDITOR\_SELECTION\_NUMBER environment variables to manage your tab stops!

Note that FileActions ignore `<input>`, `<alternate>`, and `<output-format>`, and they only accept "nothing" (default), "log", "html", or "console" for `<output>`.

### The shell script

You may write your shell script in whatever language you prefer. Regardless of language:

* You _must_ use a shebang to specify to the system how to execute the file
* STDIN will be whatever you requested as input
* STDOUT will be whatever your script needs to output
* Anything written to STDERR will result in an error (by default just logged to Console.app)
* TextActions will be executed once for every selection
* FileActions will be executed a single time, and receive a linebreak-delimited list of selected files via STDIN
* Neither STDIN nor any environment variable is ever escaped for use on the shell! So be careful if you are working with bash/sh/etc. as anything in STDIN could potentially have a space, quotation mark, or other character with special meaning
* Environment variables that for whatever reason do not have any contents for this particular action will be empty strings, but they will still exist

#### Environment variables

The following environment variables are available to all scripts:

* _EDITOR\_SUGAR\_PATH_: the path to the root of the action's Sugar
* _EDITOR\_DIRECTORY\_PATH_: the path to the most specific possible context directory
* _EDITOR\_PROJECT\_PATH_: the path to the root project folder
* _EDITOR\_PATH_: the path to the active file (only available in FileActions if there is only a single file)
* _EDITOR\_FILENAME_: the filename of the active file (only available if EDITOR\_PATH is set)

Path variables pointing to directories will _not_ include a trailing slash.

The following variables are only available in TextActions:

* _EDITOR\_CURRENT\_WORD_: the word around the cursor (or first index of the selection)
* _EDITOR\_CURRENT\_LINE_: the line around the cursor (or first index of the selection)
* _EDITOR\_LINE\_INDEX_: the zero-based index where the cursor falls in the line (or first index of the selection)
* _EDITOR\_LINE\_NUMBER_: the number of the line around the cursor (or first index of the selection)
* _EDITOR\_TAB\_STRING_: the string inserted when the user hits tab
* _EDITOR\_LINE\_ENDING\_STRING_: the string inserted when the user hits enter
* _EDITOR\_ROOT\_ZONE_: textual ID of the root syntax zone
* _EDITOR\_ACTIVE\_ZONE_: textual ID of the active syntax zone
* _EDITOR\_SELECTIONS\_TOTAL_: the total number of selections in the document
* _EDITOR\_SELECTION\_NUMBER_: the number of the selection currently being processed
* _EDITOR\_SELECTION\_RANGE_: the range of the selected text in the document; uses the same formatting as the "range" output (index,length). So if the first ten characters are selected, this will be "0,10" (without the quotes, of course)

How to access environment variables and standard input/output will vary depending on the language you are using. Here's two crowd favorites:

**Python**

    #!/usr/bin/env python
    import sys, os
    sugarPath = os.environ['EDITOR_SUGAR_PATH']
    input = sys.stdin.read()
    # Could alternately use print, but it appends a linebreak
    sys.stdout.write('custom output')

**Ruby**

    #!/usr/bin/env ruby
    sugarPath = ENV['EDITOR_SUGAR_PATH']
    input = STDIN.read
    print 'custom output'

Have fun!

## Changelog

**1.0**:

* Initial release
* OCShellAction class supports both TextActions and FileActions
* Output text or snippets, select text, log output directly to the Console, or output rendered HTML or plain text
* Process anything from the selection up to the whole document via STDIN
* Access extra information in special environment variables

## MIT License

Copyright (c) 2012 Ian Beck

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
