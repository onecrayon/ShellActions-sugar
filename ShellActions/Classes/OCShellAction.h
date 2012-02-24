//
//  OCShellAction.h
//  ShellActions.sugar
//
//  Created by Ian Beck on 2/23/12.
//  Copyright 2012 Ian Beck. MIT license.
//

#import <Foundation/Foundation.h>


/**
 * OCShellAction
 * 
 * OCShellAction allows users to hook shell scripts into the Espresso API,
 * similar to Textmate bundles. It can be used for both TextActions and
 * FileActions, although the environment variables and STDIN will vary
 * based on the type of action.
 * 
 * If OCShellAction is invoked as a TextAction and there are multiple
 * selections, it will iterate over all selections and invoke the script
 * once per selection (assuming the input is set to "selection"). This is
 * the ONLY time the script will be invoked multiple times for the same
 * action. FileActions with multiple selected files will simply have the
 * entire list of selected files passed in as a newline delimited list to
 * STDIN.
 * 
 * SETUP OPTIONS
 * 
 * Universal <setup> options:
 * - <script> (REQUIRED): you must specify the name of your script here. E.g.:
 * 
 *     <script>process_text.rb</script>
 * 
 *   Your script file will need to be saved in your Sugars's Scripts folder.
 * - <multiple-selections>: whether your script can handle multiple selections:
 *   - true (default)
 *   - false
 * - <single-selection>: whether your script can handle a single selection:
 *   - true (default)
 *   - false
 * - <empty-selection>: whether your script can handle an empty selection:
 *   - true (default)
 *   - false
 * - <suppress-errors>: whether script errors will be output or suppressed and logged
 *   - true (default)
 *   - false
 * 
 * TextAction <setup> options:
 * - <input>: the contents of STDIN. Accepts:
 *   - selection (default)
 *   - document
 *   - nothing
 * - <alternate>: if your input is "selection", this is the fallback. Accepts:
 *   - document
 *   - line
 *   - word
 *   - character
 * - <output>: what your script will output. Accepts:
 *   - input (default): STDOUT will replace the input
 *   - document: STDOUT will replace the document
 *   - range: STDOUT represents one or more ranges to select
 *       * Ranges are formatted as 'location,length'. So first ten characters
 *         would be 0,10
 *       * Multiple ranges can be separated by linebreaks or &:
 *         0,10&12,5
 *   - log: STDOUT will be output straight to the Console (using NSLog)
 *   - nothing: STDOUT will be ignored
 * - <output-format>: the format that your script will output if overwriting text
 *   in the document. Accepts:
 *   - text (default): contents of STDOUT will be inserted as plain text.
 *   - snippet: contents of STDOUT will be inserted as a CETextSnippet.
 *     NOTE: if the user has multiple selections, your output
 *     will be automatically aggregated into a single snippet and overwrite the
 *     whole range. Make good use of the EDITOR_SELECTIONS_TOTAL and
 *     EDITOR_SELECTION_NUMBER environment variables to manage your tab stops!
 * 
 * ENVIRONMENT VARIABLES
 * 
 * Universal environment variables:
 * - EDITOR_SUGAR_PATH: the path to the root of the action's Sugar
 * - EDITOR_DIRECTORY_PATH: the path to the most specific possible context directory
 * - EDITOR_PROJECT_PATH: the path to the root project folder
 * - EDITOR_PATH: the path to the active file (only available in FileActions if
 *   there is only a single file)
 * 
 * TextAction environment variables:
 * - EDITOR_CURRENT_WORD: the word around the cursor
 * - EDITOR_CURRENT_LINE: the line around the cursor
 * - EDITOR_LINE_INDEX: the zero-based index where the cursor falls in the line
 * - EDITOR_LINE_NUMBER: the number of the line around the cursor
 * - EDITOR_TAB_STRING: the string inserted when the user hits tab
 * - EDITOR_LINE_ENDING_STRING: the string inserted when the user hits enter
 * - EDITOR_ROOT_ZONE: textual ID of the root syntax zone
 * - EDITOR_ACTIVE_ZONE: textual ID of the active syntax zone
 * - EDITOR_SELECTIONS_TOTAL: the total number of selections in the document
 * - EDITOR_SELECTION_NUMBER: the number of the selection currently being processed
 * - EDITOR_SELECTION_RANGE: the range of the selected text in the document; uses
 *   the same formatting as the "range" output (index,length). So if the first ten
 *   characters are selected, this will be "0,10" (without the quotes)
 * 
 * TODO:
 * - Add support for "console" output style (requires UI). Idea for docs:
 *   - console: STDOUT will be displayed as plain text in a new window
 * - Add support for "html" output style (requires UI). Idea for docs:
 *   - html: STDOUT will be rendered as HTML in a new window
 * - Add better error handling. If an error is detected/thrown, the action needs
 *   to ensure that it exits cleanly
 */

@interface OCShellAction : NSObject {
@private
    NSString *script;
	NSString *input;
	NSString *alternate;
	NSString *output;
	NSString *outputFormat;
	NSString *bundlePath;
	BOOL allowMultipleSelections;
	BOOL allowSingleSelection;
	BOOL allowNoSelection;
	BOOL suppressErrors;
}

- (NSString *)findScript:(NSString *)fileName;
- (NSString *)runScriptWithInput:(NSString *)input;
- (void)processErrors;
- (NSArray *)parseRangesFromString:(NSString *)rangeString combineWithRangeValues:(NSArray *)rangeValues maxIndex:(NSUInteger)maxIndex;

@end
