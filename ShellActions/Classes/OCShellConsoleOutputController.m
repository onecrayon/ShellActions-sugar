//
//  OCShellConsoleOutputController.m
//  ShellActions
//
//  Created by Ian Beck on 3/2/12.
//  Copyright 2012 Ian Beck. MIT license.
//

#import "OCShellConsoleOutputController.h"


@implementation OCShellConsoleOutputController

@synthesize outputText;

static OCShellConsoleOutputController *sharedObject = nil;

+ (OCShellConsoleOutputController *)sharedController {
	if (sharedObject == nil) {
		sharedObject = [[self alloc] init];
		[NSBundle loadNibNamed:@"OCShellConsoleOutputWindow" owner:sharedObject];
	}
	return sharedObject;
}

- (void)dealloc {
	MRRelease(sharedObject);
	MRRelease(outputText);
    [super dealloc];
}

- (void)displayString:(NSString *)outputString {
	[outputText appendString:outputString];
	[self showWindow:self];
}

- (IBAction)clearConsole:(id)sender {
	[outputText clearContents];
}

#pragma mark Window delegate methods

- (void)windowWillClose:(NSNotification *)theNotification {
	// Clear out our console when the window closes
	[outputText clearContents];
}

@end
