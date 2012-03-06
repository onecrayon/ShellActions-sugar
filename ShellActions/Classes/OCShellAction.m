//
//  OCShellAction.m
//  ShellActions.sugar
//
//  Created by Ian Beck on 2/23/12.
//  Copyright 2012 Ian Beck. MIT license.
//

#import "OCShellAction.h"
#import "NSObject+OCTextActionContextAdditions.h"
#import "NSMutableDictionary+OCSettingAdditions.h"
#import "OCShellHTMLOutputController.h"
#import "OCShellConsoleOutputController.h"

#import <EspressoTextActions.h>
#import <EspressoTextCore.h>
#import <EspressoSyntaxCore.h>
#import <NSString+MRFoundation.h>
#import <MRRangeSet.h>

#import <pthread.h>


// HACK: these are not exposed in the public Espresso API, but we need them to properly locate the root project directory
// DON'T TRY THIS AT HOME! YOUR SUGAR WILL LIKELY BREAK WITH FUTURE ESPRESSO UPDATES
@interface NSObject (OCShellActionPathInfo)
@property(readonly) NSURL *contextDirectoryURL;
@property(readonly) id document;
@end

/*
 This stuff is related to the thread-based STDIN handling necessary to pass arbitrary amounts of data through the pipe without breaking
 
 Code derived from an un-attributed post on http://www.cocoadev.com/index.pl?NSPipe
 
 References:
 
 - "NSPipe (NSFileHandle) writedata limit?"  (April 09, 2010),
 http://www.cocoabuilder.com/archive/cocoa/284765-nspipe-nsfilehandle-writedata-limit.html,
 http://pastie.org/911738 (by Dave Keck)
 
 - "64KB limit in passed in text for a service using NSTask" (August 20, 2010),
 http://www.cocoabuilder.com/archive/cocoa/292247-64kb-limit-in-passed-in-text-for-service-using-nstask.html
 
 Original sample code based on a code snippet by Dave Keck, http://pastie.org/911738
 */
// Using static variables for these to allow access from within the threadFunction as well as the main action logic
// FIXME: There HAS to be a better way to do this
static NSMutableString *outString = nil;
static NSMutableString *errString = nil;
static NSMutableDictionary *env = nil;
static NSString *file = nil;
// threadFunction handles piping in the full contents to STDIN regardless of their size
static void *threadFunction(NSPipe *pipe) {
	// This is automatically drained when the thread exits
	[[NSAutoreleasePool alloc] init];
	
	NSPipe *outPipe = [[NSPipe alloc] init];
	NSPipe *errPipe = [[NSPipe alloc] init];
	NSTask *task = [[NSTask alloc] init];  
	
	NSData *outputData = nil;
	NSData *errData = nil;
	NSString *str = nil;
	
	[task setLaunchPath:file];
	[task setStandardInput:pipe];
	[task setStandardOutput:outPipe];
	[task setStandardError:errPipe];
	[task setEnvironment:env];
	
	[task launch];
	
	while (((outputData = [[outPipe fileHandleForReading] availableData]) && [outputData length]) || ((errData = [[errPipe fileHandleForReading] availableData]) && [errData length])) {
		if ([outputData length]) {
			str = [[NSString alloc] initWithFormat:@"%.*s", [outputData length], [outputData bytes]];
			[outString appendString:str];
			[str release];
		}
		if ([errData length]) {
			str = [[NSString alloc] initWithFormat:@"%.*s", [errData length], [errData bytes]];
			[errString appendString:str];
			[str release];
		}
	}
	
	[task release];
	[outPipe release];
	[errPipe release];
	
	pthread_exit(outString);
}


@implementation OCShellAction

- (id)initWithDictionary:(NSDictionary *)dictionary bundlePath:(NSString *)myBundlePath {
    self = [super init];
    if (self) {
		// Grab our <setup> variables
		script = [[dictionary objectForKey:@"script"]retain];
		if ([dictionary objectForKey:@"input"]) {
			input = [[[dictionary objectForKey:@"input"] lowercaseString] retain];
		} else {
			input = [@"selection" retain];
		}
		alternate = [[dictionary objectForKey:@"alternate"]retain];
		if ([dictionary objectForKey:@"output"]) {
			output = [[[dictionary objectForKey:@"output"] lowercaseString] retain];
		} else {
			output = [@"input" retain];
		}
		if ([dictionary objectForKey:@"output-format"]) {
			outputFormat = [[[dictionary objectForKey:@"output-format"] lowercaseString] retain];
		} else {
			outputFormat = [@"text" retain];
		}
		bundlePath = [myBundlePath retain];
		
		if ([dictionary objectForKey:@"multiple-selections"]) {
			allowMultipleSelections = ([[dictionary objectForKey:@"multiple-selections"] caseInsensitiveCompare:@"true"] == NSOrderedSame) ? YES : NO;
		} else {
			allowMultipleSelections = YES;
		}
		if ([dictionary objectForKey:@"single-selection"]) {
			allowSingleSelection = ([[dictionary objectForKey:@"single-selection"] caseInsensitiveCompare:@"true"] == NSOrderedSame) ? YES : NO;
		} else {
			allowSingleSelection = YES;
		}
		if ([dictionary objectForKey:@"empty-selection"]) {
			allowNoSelection = ([[dictionary objectForKey:@"empty-selection"] caseInsensitiveCompare:@"true"] == NSOrderedSame) ? YES : NO;
		} else {
			allowNoSelection = YES;
		}
		if ([dictionary objectForKey:@"suppress-errors"]) {
			suppressErrors = ([[dictionary objectForKey:@"suppress-errors"] caseInsensitiveCompare:@"true"] == NSOrderedSame) ? YES : NO;
		} else {
			suppressErrors = YES;
		}
    }
    
    return self;
}

- (void)dealloc {
	MRRelease(script);
	MRRelease(input);
	MRRelease(alternate);
	MRRelease(output);
	MRRelease(bundlePath);
    [super dealloc];
}

- (BOOL)canPerformActionWithContext:(id)context {
	// Possible for context to be empty if it's partially initialized
	if ([context respondsToSelector:@selector(string)] && [context string] == nil) {
		return NO;
	}
	
	// Check for the proper number of selections; logic varies depending on type of context, because for a TextAction no selections is the same as a single range with no length
	NSArray *selections;
	if ([context respondsToSelector:@selector(selectedRanges)]) {
		selections = [context selectedRanges];
		return script != nil && ((allowMultipleSelections && [selections count] > 1) || ([selections count] == 1 && ((allowSingleSelection && [[selections objectAtIndex:0] rangeValue].length > 0) || (allowNoSelection && [[selections objectAtIndex:0] rangeValue].length == 0))));
	} else {
		selections = [context URLs];
		return script != nil && ((allowMultipleSelections && [selections count] > 1) || (allowSingleSelection && [selections count] == 1) || (allowNoSelection && [selections count] == 0));
	}
}

- (BOOL)performActionWithContext:(id)context error:(NSError **)outError {
	// Set up the base static variables (they're allocated and released every time the action is initiated)
	file = [self findScript:script];
	if (file == nil) {
		NSLog(@"Error: OCShellAction could not find script file");
		return NO;
	}
	env = [[NSMutableDictionary alloc] init];
	outString = [[NSMutableString alloc] init];
	errString = [[NSMutableString alloc] init];
	
	// Make sure the script is executable
	if (![[NSFileManager defaultManager] isExecutableFileAtPath:file]) {
		// FIXME: Handle error; it might not be possible to set executable bit for whatever reason and we should exit if that is the case
		NSArray *chmodArguments = [NSArray arrayWithObjects:@"775", file, nil];
		NSTask *chmod = [NSTask launchedTaskWithLaunchPath:@"/bin/chmod" arguments:chmodArguments];
		[chmod waitUntilExit];
	}
	
	// Figure out what type of action we're dealing with
	BOOL isTextAction = ([context respondsToSelector:@selector(string)]) ? YES : NO;
	
	// Define our universal environment attributes
	NSString *eDirectoryPath = nil;
	NSString *eProjectPath = nil;
	NSString *ePath = nil;
	
	// Setup eDirectoryPath and ePath
	if (isTextAction) {
		NSURL *fileURL = [[context documentContext] fileURL];
		if ([fileURL isFileURL]) {
			eDirectoryPath = [[fileURL path] stringByDeletingLastPathComponent];
			ePath = [fileURL path];
		}
	} else {
		eDirectoryPath = [[context contextDirectoryURL] path];
		if ([[context URLs] count] == 1) {
			ePath = [[[context URLs] objectAtIndex:0] path];
			if (!eDirectoryPath) {
				NSLog(@"no contextDirectoryURL");
				BOOL isDir;
				BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[[[context URLs] objectAtIndex:0] path] isDirectory:&isDir];
				if (exists && !isDir) {
					eDirectoryPath = [[[[context URLs] objectAtIndex:0] path] stringByDeletingLastPathComponent];
				} else if (isDir) {
					eDirectoryPath = [[[context URLs] objectAtIndex:0] path];
				}
			}
		}
	}
	
	// Setup eProjectPath
	id doc = [[context windowForSheet] document];
	if ([[doc className] isEqualToString:@"ESProjectDocument"]) {
		eProjectPath = [[doc directoryURL] path];
	}
	
	// Assign our universal variables to the dictionary
	[env addObjectOrEmptyString:bundlePath forKey:@"EDITOR_SUGAR_PATH"];
	[env addObjectOrEmptyString:eDirectoryPath forKey:@"EDITOR_DIRECTORY_PATH"];
	[env addObjectOrEmptyString:eProjectPath forKey:@"EDITOR_PROJECT_PATH"];
	[env addObjectOrEmptyString:ePath forKey:@"EDITOR_PATH"];
	[env addObjectOrEmptyString:[ePath lastPathComponent] forKey:@"EDITOR_FILENAME"];
	
	// We'll save our ultimate response and return it at the end
	BOOL response = YES;
	// We might need to display output to the user via GUI at the end of things
	NSString *finalOutput = nil;
	
	// Process our action, depending on if it is a TextAction or a FileAction
	if (isTextAction) {
		// Setup our other universal environment variables
		NSString *eRootZone = nil;
		if ([[[context syntaxTree] rootZone] typeIdentifier] != nil) {
			eRootZone = [[[[context syntaxTree] rootZone] typeIdentifier] stringValue];
		}
		[env addObjectOrEmptyString:eRootZone forKey:@"EDITOR_ROOT_ZONE"];
		[env addObjectOrEmptyString:[[context textPreferences] tabString] forKey:@"EDITOR_TAB_STRING"];
		[env addObjectOrEmptyString:[[context textPreferences] lineEndingString] forKey:@"EDITOR_LINE_ENDING_STRING"];
		[env addObjectOrEmptyString:[NSString stringWithFormat:@"%lu", (unsigned long)[[context selectedRanges] count]] forKey:@"EDITOR_SELECTIONS_TOTAL"];
		
		// Initialize our common variables
		CETextRecipe *recipe = [CETextRecipe textRecipe];
		NSArray *ranges = [context selectedRanges];
		
		// Loop over the ranges and perform the script's action on each
		// Looping allows us to handle single ranges or multiple discontiguous selections
		NSRange range;
		NSRange wordRange;
		NSArray *targetRanges = nil;
		NSString *eCurrentWord;
		NSUInteger eLineNumber;
		NSUInteger eLineIndex;
		NSUInteger rangeNumber = 0;
		NSString *source;
		NSString *inputStr;
		NSString *outputStr;
		NSMutableString *aggregateOutput = [NSMutableString string];
		NSRange aggregateRange = NSMakeRange(0, 0);
		BOOL multipleSelectionsToSnippet = NO;
		NSMutableString *interimText;
		for (NSValue *rangeValue in ranges) {
			range = [rangeValue rangeValue];
			// Setup our per-loop environment variables
			NSString *eCurrentWord = [context getWordAtIndex:range.location range:&wordRange];
			[env addObjectOrEmptyString:eCurrentWord forKey:@"EDITOR_CURRENT_WORD"];
			[env addObjectOrEmptyString:[[context string] substringWithRange:[[context lineStorage] lineRangeForRange:NSMakeRange(range.location, 0)]] forKey:@"EDITOR_CURRENT_LINE"];
			eLineNumber = [[context lineStorage] lineNumberForIndex:range.location];
			[env addObjectOrEmptyString:[NSString stringWithFormat:@"%lu", (unsigned long)eLineNumber] forKey:@"EDITOR_LINE_NUMBER"];
			eLineIndex = range.location - [[context lineStorage] lineRangeForLineNumber:eLineNumber].location - 1;
			[env addObjectOrEmptyString:[NSString stringWithFormat:@"%lu", (unsigned long)eLineIndex] forKey:@"EDITOR_LINE_INDEX"];
			NSString *eActiveZone = nil;
			if ([[context syntaxTree] zoneAtCharacterIndex:range.location] != nil) {
				if ([[[context syntaxTree] zoneAtCharacterIndex:range.location] typeIdentifier] != nil) {
					eActiveZone = [[[[context syntaxTree] zoneAtCharacterIndex:range.location] typeIdentifier] stringValue];
				}
			}
			[env addObjectOrEmptyString:eActiveZone forKey:@"EDITOR_ACTIVE_ZONE"];
			[env addObjectOrEmptyString:[NSString stringWithFormat:@"%lu", (unsigned long)++rangeNumber] forKey:@"EDITOR_SELECTION_NUMBER"];
			[env addObjectOrEmptyString:[NSString stringWithFormat:@"%lu,%lu", (unsigned long)range.location, (unsigned long)range.length] forKey:@"EDITOR_SELECTION_RANGE"];
			
			// Grab the contents for our STDIN
			source = input;
			if ([input isEqualToString:@"selection"]) {
				inputStr = [[context string] substringWithRange:range];
				if ([inputStr isEqualToString:@""]) {
					if ([alternate isEqualToString:@"document"]) {
						// Use the document's context as the input
						inputStr = [context string];
					} else if ([alternate isEqualToString:@"line"]) {
						// Use the current line's content as the input
						inputStr = [[context string] substringWithRange:[[context lineStorage] lineRangeForLineNumber:eLineNumber]];
					} else if ([alternate isEqualToString:@"word"]) {
						// Use the current word as the input
						range = wordRange;
						inputStr = eCurrentWord;
					} else if ([alternate isEqualToString:@"character"]) {
						// Use the current character as the input if possible
						if (range.location > 0) {
							range = NSMakeRange(range.location - 1, 1);
							inputStr = [[context string] substringWithRange:range];
						}
					}
					// Set our source appropriately
					source = alternate;
				}
			} else if ([input isEqualToString:@"document"]) {
				inputStr = [context string];
			} else {
				inputStr = @"";
			}
			
			outputStr = [self runScriptWithInput:inputStr];
			
			// Handle the error output, if there is any
			[self processErrors];
			
			// Insert the output
			if ([output isEqualToString:@"document"] || ([source isEqualToString:@"document"] && [output isEqualToString:@"input"])) {
				// Replace the document
				[recipe replaceRange:NSMakeRange(0, [[context string] length]) withString:outputStr];
				// Since we replaced the document, jump out of the loop (makes no sense to replace the document multiple times)
				break;
			} else if ([output isEqualToString:@"input"] && [outputFormat isEqualToString:@"text"]) {
				[recipe replaceRange:range withString:outputStr];
			} else if ([output isEqualToString:@"input"] && [outputFormat isEqualToString:@"snippet"]) {
				// We are composing a snippet, so we need to grab any missing text between this and the last snippet, and compose our aggregate range and output
				if (rangeNumber == 1) {
					// This is the first range, so setup our range and initial output
					aggregateRange = range;
				} else {
					multipleSelectionsToSnippet = YES;
					// Not the first range, so look for intervening text
					if (aggregateRange.location + aggregateRange.length < range.location) {
						interimText = [[[context string] substringWithRange:NSMakeRange(aggregateRange.location + aggregateRange.length, range.location - (aggregateRange.location + aggregateRange.length))] mutableCopy];
						// Protect special snippet characters
						[interimText replaceOccurrencesOfString:@"$" withString:@"\\$"];
						[interimText replaceOccurrencesOfString:@"`" withString:@"\\`"];
						[aggregateOutput appendString:interimText];
						[interimText release];
					}
					aggregateRange = NSMakeRange(aggregateRange.location, range.location + range.length - aggregateRange.location);
				}
				[aggregateOutput appendString:outputStr];
			} else if ([output isEqualToString:@"range"]) {
				// Output is one or more ranges to be selected in the document
				targetRanges = [self parseRangesFromString:outputStr combineWithRangeValues:targetRanges maxIndex:[[context string] length]];
			} else if ([output isEqualToString:@"log"]) {
				NSLog(@"OCShellAction: Processing selection #%lu", (unsigned long)rangeNumber);
				NSLog(@"%@", outputStr);
			} else if ([output isEqualToString:@"console"] || [output isEqualToString:@"html"]) {
				// If we are outputting to a console or HTML window, then just aggregate everything
				[aggregateOutput appendString:outputStr];
			}
			
			// Before we loop again, reset our output
			[outString setString:@""];
		}
		
		// Apply our text recipe, if necessary
		[recipe prepare];
		
		if ([recipe numberOfChanges] > 0) {
			response = [context applyTextRecipe:recipe];
		} else if ([output isEqualToString:@"input"] && [outputFormat isEqualToString:@"snippet"]) {
			// We are working with a (potentially) aggregate snippet; first select the range
			[context setSelectedRanges:[NSArray arrayWithObject:[NSValue valueWithRange:aggregateRange]]];
			// Now we can insert our snippet
			CETextSnippet *snippet = [CETextSnippet snippetWithString:aggregateOutput];
			if (multipleSelectionsToSnippet) {
				response = [context insertTextSnippet:snippet options:CETextOptionVerbatim];
			} else {
				response = [context insertTextSnippet:snippet];
			}
		} else if ([output isEqualToString:@"range"]) {
			// We need to select one or more ranges, specified by the script
			if ([targetRanges count]) {
				[context setSelectedRanges:targetRanges];
			}
			response = YES;
		} else if ([output isEqualToString:@"console"] || [output isEqualToString:@"html"]) {
			// Save our aggregateOutput into the finalOutput variable (process this outside of the conditional, since it's identical for both types of actions
			finalOutput = aggregateOutput;
		}
	} else {
		// Prep our list of selected URLs
		NSMutableString *fileList = [NSMutableString string];
		for (NSURL *url in [context URLs]) {
			[fileList appendString:[NSString stringWithFormat:@"%@\n", [url path]]];
		}
		// Remove the trailing linebreak
		[fileList trimWhitespaceAndNewlines];
		
		// Run our action!
		finalOutput = [self runScriptWithInput:fileList];
		
		// Handle the error output, if there is any
		[self processErrors];
		
		// If we are outputting to the log, do so
		if ([output isEqualToString:@"log"]) {
			NSLog(@"%@", finalOutput);
		}
	}
	
	// Handle HTML and console output types
	if ([output isEqualToString:@"html"] && [finalOutput length] > 0) {
		[[OCShellHTMLOutputController sharedController] loadSource:finalOutput withBaseURL:bundlePath];
	} else if ([output isEqualToString:@"console"] && [finalOutput length] > 0) {
		[[OCShellConsoleOutputController sharedController] displayString:finalOutput];
	}
	
	// Release our static variables
	[env release];
	[outString release];
	[errString release];
	
	// All done!
	return response;
}

- (NSString *)findScript:(NSString *)fileName {
	NSString *targetPath = [[bundlePath stringByAppendingPathComponent:@"Scripts"] stringByAppendingPathComponent:fileName];
	if ([[NSFileManager defaultManager] fileExistsAtPath:targetPath]) {
		return targetPath;
	}
	return nil;
}

- (NSString *)runScriptWithInput:(NSString *)inputStr {
	// Initiate our pipe, and send the data to the script using the threading functionality
	NSPipe *inPipe = [[NSPipe alloc] init];
	void *outputString = nil;
	
	pthread_t thread = nil;
	if (pthread_create(&thread, nil, (void *(*)(void *))threadFunction, inPipe) != 0) {
		perror("pthread_create failed");
		return nil;
	}
	
	[[inPipe fileHandleForWriting] writeData:[inputStr dataUsingEncoding:NSUTF8StringEncoding]];
	[[inPipe fileHandleForWriting] closeFile];
	
	// Wait until thread has finished execution
	if (pthread_join(thread, &outputString) != 0) {
		perror("pthread_join failed");
		return NO;
	}
	
	// Reset our thread variables
	[inPipe release];
	
	return [[[NSString alloc] initWithString:outputString] autorelease];
}

- (void)processErrors {
	if ([errString length]) {
		if (suppressErrors) {
			NSLog(@"%@ (%@): %@", script, [bundlePath lastPathComponent], errString);
		} else {
			[NSException raise:@"OCShellAction error" format:@"%@ (%@): %@", script, [bundlePath lastPathComponent], errString];
		}
		// Reset our error string
		[errString setString:@""];
	}
}

- (NSArray *)parseRangesFromString:(NSString *)rangeString combineWithRangeValues:(NSArray *)rangeValues maxIndex:(NSUInteger)maxIndex {
	// Setup our rangeSet (which ensures no ranges overlap automatically)
	MRRangeSet *rangeSet = [MRRangeSet rangeSet];
	[rangeSet setAllowsZeroLengthRanges:YES];
	if (rangeValues != nil && [rangeValues count]) {
		[rangeSet unionRanges:rangeValues];
	}
	
	// Parse the ranges from the string
	NSArray *rangeStrings;
	if ([rangeString containsString:@"\n"]) {
		rangeStrings = [rangeString componentsSeparatedByString:@"\n"];
	} else if ([rangeString containsString:@"&"]) {
		rangeStrings = [rangeString componentsSeparatedByString:@"&"];
	} else {
		rangeStrings = [NSArray arrayWithObject:rangeString];
	}
	
	// Loop through our rangeStrings and parse each one into an actual range, then add to rangeSet
	NSRange range;
	NSArray *rangeComponents;
	for (NSString *str in rangeStrings) {
		rangeComponents = [str componentsSeparatedByString:@","];
		// Only proceed if we actually have two portions of the range
		if ([rangeComponents count] == 2) {
			range = NSMakeRange((NSUInteger)[[[rangeComponents objectAtIndex:0] stringByTrimmingWhitespaceAndNewlines] integerValue], (NSUInteger)[[[rangeComponents objectAtIndex:1] stringByTrimmingWhitespaceAndNewlines] integerValue]);
			// Make sure our range doesn't exceed the document bounds
			if (range.location > 0 && (range.location + range.length) <= maxIndex && !(range.location == 0 && range.length == 0)) {
				[rangeSet unionRange:range];
			}
		}
	}
	
	// Return our range array
	return [rangeSet ranges];
}

@end
