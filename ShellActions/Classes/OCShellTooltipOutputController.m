//
//  OCShellTooltipOutputController.m
//  ShellActions
//
//  Created by Ian Beck on 04/10/12.
//  Copyright 2012 One Crayon. All rights reserved.
//

#import "OCShellTooltipOutputController.h"


// HACK: these are not exposed in the public Espresso API, but we need them to properly locate the root project directory
// DON'T TRY THIS AT HOME! YOUR SUGAR WILL LIKELY BREAK WITH FUTURE ESPRESSO UPDATES
@interface NSObject (OCShellTooltipExtraInfo)
@property(readonly) id tab;
@end

@implementation OCShellTooltipOutputController

@synthesize labelText;


static OCShellTooltipOutputController *sharedObject = nil;

+ (OCShellTooltipOutputController *)sharedController {
	if (sharedObject == nil) {
		sharedObject = [[self alloc] init];
		[NSBundle loadNibNamed:@"OCShellTooltipOutputView" owner:sharedObject];
	}
	return sharedObject;
}

- (void)dealloc {
	MRRelease(sharedObject);
	MRRelease(labelText);
	MRRelease(tooltipWindow);
	MRRelease(rootWindow);
	[super dealloc];
}

- (void)displayString:(NSString *)outputString inContext:(id)context {
	NSLog(@"Trying to display string: %@", outputString);
	// Grab the active text view, and verify it is indeed a text view
	rootWindow = [context windowForSheet];
	id activeView = [[rootWindow tab] initialFirstResponder];
	if ([[activeView className] isEqualToString:@"EKTextView"]) {
		NSLog(@"Starting tooltip...");
		[self clearTooltip];
		/*
		Many thanks to Bavarious for this code:
		http://stackoverflow.com/questions/7554472/gettting-window-coordinates-of-the-insertion-point-cocoa
		*/
		// We've got the text view! Grab the point for our cursor
		NSRange range = [[[context selectedRanges] objectAtIndex:0] rangeValue];
		NSRect screenRect = [activeView firstRectForCharacterRange:range actualRange:NULL];
		// The origin is the lower left corner of the frame rectangle
		// containing the insertion point
		NSPoint insertionPoint = screenRect.origin;
		// Set our string
		[labelText setStringValue:outputString];
		// Initialize our tooltip
		tooltipWindow = [[MAAttachedWindow alloc] initWithView:[self view] attachedToPoint:insertionPoint];
		[labelText setTextColor:[tooltipWindow borderColor]];
		// TODO: resize the window based on the size of the text, and truncate if necessary
		// Display
		[rootWindow addChildWindow:tooltipWindow ordered:NSWindowAbove];
		[tooltipWindow orderFront:self];
		// TODO: How the hell do I dismiss this window? Nothing I've tried remotely works
	}
}

-(void)clearTooltip {
	NSLog(@"Trying to clear tooltip...");
	if (tooltipWindow) {
		[rootWindow removeChildWindow:tooltipWindow];
		[tooltipWindow orderOut:self];
		[tooltipWindow release];
		tooltipWindow = nil;
	}
}

@end
