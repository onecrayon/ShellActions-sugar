//
//  OCShellTooltipOutputController.m
//  ShellActions
//
//  Created by Ian Beck on 04/10/12.
//  Copyright 2012 One Crayon. All rights reserved.
//

#import "OCShellTooltipOutputController.h"
#import "NS(Attributed)String+Geometrics.h"


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
	if (eventMonitor) {
		[NSEvent removeMonitor:eventMonitor];
	}
	MRRelease(eventMonitor);
	[super dealloc];
}

- (void)displayString:(NSString *)outputString inContext:(id)context {
	// Grab the active text view, and verify it is indeed a text view
	rootWindow = [context windowForSheet];
	id activeView = [[rootWindow tab] initialFirstResponder];
	if ([[activeView className] isEqualToString:@"EKTextView"]) {
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
		// Make sure our text doesn't exceed 256 characters
		if ([outputString length] > 256) {
			outputString = [NSString stringWithFormat:@"%@ ...", [outputString substringToIndex:257]];
		}
		// Set our string, and resize our text view
		[labelText setString:outputString];
		// Resize the window based on the size of the text, and truncate if necessary
		NSSize textSize = [outputString sizeForWidth:300 height:600 font:[labelText font]];
		// Adjust sizes for padding (10px all sides)
		textSize.width += 20;
		textSize.height += 6;
		[[self view] setFrameSize:textSize];
		// Initialize our tooltip
		tooltipWindow = [[MAAttachedWindow alloc] initWithView:[self view] attachedToPoint:insertionPoint];
		[labelText setTextColor:[tooltipWindow borderColor]];
		// Display
		[rootWindow addChildWindow:tooltipWindow ordered:NSWindowAbove];
		[tooltipWindow orderFront:self];
		// Dismiss the tooltip if the user clicks, scrolls, or uses the keyboard
		eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDownMask|NSRightMouseDownMask|NSKeyDownMask|NSScrollWheelMask|NSOtherMouseDownMask handler:^(NSEvent *event) {
			[self clearTooltip];
			[NSEvent removeMonitor:eventMonitor];
			// Make sure the event propagates along its way to be handled normally
			return event;
		}];
	}
}

- (void)clearTooltip {
	if (tooltipWindow) {
		[rootWindow removeChildWindow:tooltipWindow];
		[tooltipWindow orderOut:self];
		[tooltipWindow release];
		tooltipWindow = nil;
	}
}

@end
