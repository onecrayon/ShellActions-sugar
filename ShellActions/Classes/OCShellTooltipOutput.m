//
//  OCShellTooltipOutput.m
//  ShellActions
//
//  Created by Ian Beck on 04/10/12.
//  Copyright 2012 One Crayon. All rights reserved.
//

#import "OCShellTooltipOutput.h"
#import "NS(Attributed)String+Geometrics.h"

#import <NSString+MRFoundation.h>
#import <EspressoTextActions.h>


// HACK: these are not exposed in the public Espresso API, but we need them to properly locate the root project directory
// DON'T TRY THIS AT HOME! YOUR SUGAR WILL LIKELY BREAK WITH FUTURE ESPRESSO UPDATES
@interface NSObject (OCShellTooltipExtraInfo)
@property(readonly) id tab;
@end

@implementation OCShellTooltipOutput

- (OCShellTooltipOutput *)init {
	self = [super init];
	if (self) {
		view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 478, 34)];
	}
	return self;
}

- (void)dealloc {
	MRRelease(labelText);
	MRRelease(tooltipWindow);
	MRRelease(rootWindow);
	MRRelease(view);
	if (eventMonitor) {
		[NSEvent removeMonitor:eventMonitor];
		eventMonitor = nil;
	}
	[super dealloc];
}

- (void)displayString:(NSString *)outputString inTextActionContext:(id)context forRange:(NSRange)range {
	// Grab the active text view, and verify it is indeed a text view
	rootWindow = [[context windowForSheet] retain];
	id activeView = [[rootWindow tab] initialFirstResponder];
	if ([[activeView className] isEqualToString:@"EKTextView"]) {
		/*
		Many thanks to Bavarious for this code:
		http://stackoverflow.com/questions/7554472/gettting-window-coordinates-of-the-insertion-point-cocoa
		*/
		// We've got the text view! Grab the point for our cursor
		NSRange lastLineRange = [[context lineStorage] lineRangeForIndex:range.location + range.length];
		if (lastLineRange.location == range.location + range.length) {
			// The last line is thanks to a trailing linebreak; fetch the second-to-last instead
			lastLineRange = [[context lineStorage] lineRangeForIndex:lastLineRange.location - 1];
		}
		if (lastLineRange.location > range.location) {
			// We have a multiline selection; use the last line as the anchor
			range = lastLineRange;
		}
		NSRect screenRect = [activeView firstRectForCharacterRange:range actualRange:NULL];
		// The origin is the lower left corner of the frame rectangle containing the insertion point
		NSPoint insertionPoint = screenRect.origin;
		if (screenRect.size.width > 0) {
			// We are anchoring to a selection (not a single cursor); align it in the middle
			insertionPoint.x += lroundf(screenRect.size.width / 2);
		}
		// TODO: figure out how to avoid overlapping tooltips when there are multiple on screen?
		// Make sure our text doesn't exceed 250 characters (total width accommodates 256, but that never wraps right)
		if ([outputString length] > 250) {
			outputString = [NSString stringWithFormat:@"%@ ...", [[outputString substringToIndex:246] stringByTrimmingWhitespaceAndNewlines]];
		}
		// Create our text view
		labelText = [[NSTextView alloc] initWithFrame:NSMakeRect(10.0, 10.0, 458.0, 14.0)];
		[labelText setFont:[NSFont fontWithName:@"EspressoMono-Regular" size:11.0]];
		[labelText setDrawsBackground:NO];
		[labelText setRichText:NO];
		[labelText setUsesRuler:NO];
		[labelText setTextColor:[NSColor whiteColor]];
		[view addSubview:labelText];
		// Set our string, and resize our text view
		[labelText setString:outputString];
		// Resize the window based on the size of the text
		// EspressoMono font is 7 px wide per character (so 448 is 64 characters across) and by default has 5px each side of line fragment padding; height is arbitrarily large
		NSSize textSize = [outputString sizeForWidth:458 height:600 font:[labelText font]];
		// Adjust sizes for padding (10px all sides)
		[view setFrameSize:NSMakeSize(textSize.width + 20, textSize.height + 20)];
		[labelText setFrame:NSMakeRect(10, 10, textSize.width, textSize.height)];
		// Initialize our tooltip
		tooltipWindow = [[MAAttachedWindow alloc] initWithView:view attachedToPoint:insertionPoint];
		// Display
		[rootWindow addChildWindow:tooltipWindow ordered:NSWindowAbove];
		[tooltipWindow orderFront:self];
		// Dismiss the tooltip if the user clicks, scrolls, or uses the keyboard
		eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDownMask|NSRightMouseDownMask|NSKeyDownMask|NSScrollWheelMask|NSOtherMouseDownMask handler:^(NSEvent *event) {
			[rootWindow removeChildWindow:tooltipWindow];
			[tooltipWindow orderOut:self];
			[tooltipWindow release];
			tooltipWindow = nil;
			[NSEvent removeMonitor:eventMonitor];
			eventMonitor = nil;
			// Make sure the event propagates along its way to be handled normally
			return event;
		}];
	}
}

@end
