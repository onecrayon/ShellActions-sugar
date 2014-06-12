//
//  OCShellConsoleTextView.m
//  ShellActions
//
//  Created by Ian Beck on 3/2/12.
//  Copyright 2012 Ian Beck. MIT license.
//

#import "OCShellConsoleTextView.h"
#import <NSString+MRFoundation.h>


@implementation OCShellConsoleTextView

static NSMutableDictionary *textAttr = nil;
static NSMutableDictionary *errAttr = nil;

- (void)awakeFromNib {
	NSSize inset = [self textContainerInset];
	inset.height = 6.0f;
    [self setTextContainerInset:inset];
	
	// FIXME: Should we let the user set the font/font size somehow? Could possibly use whatever they use in the editor with a preference call
	[self setFont:[NSFont fontWithName:@"EspressoMono-Regular" size:11.0]];
	
	// Prevent horizontal overflow from wrapping, and make sure the text view resizes to fit the unwrapped text
	[[self textContainer] setWidthTracksTextView:NO];
	[self setHorizontallyResizable:YES];
	
	if (textAttr == nil) {
		NSMutableParagraphStyle *paraStyling = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[paraStyling setParagraphSpacing:3.0];
		
		textAttr = [[self typingAttributes] mutableCopy];
		[textAttr setObject:paraStyling forKey:NSParagraphStyleAttributeName];
		[textAttr setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
		
		errAttr = [[self typingAttributes] mutableCopy];
		[errAttr setObject:paraStyling forKey:NSParagraphStyleAttributeName];
		[errAttr setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
		[errAttr setObject:[NSFont fontWithName:@"EspressoMono-Bold" size:11.0] forKey:NSFontAttributeName];
		
		
		[paraStyling release];
	}
}

- (void)dealloc {
	MRRelease(textAttr);
    [super dealloc];
}

- (void)appendString:(NSString *)str asError:(BOOL)isError {
	// First, switch all the old text to gray
	[[self textStorage] addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:NSMakeRange(0, [[self textStorage] length])];
	NSUInteger originalEnd = [[self textStorage] length];
	// Create our attributed string
	NSAttributedString *attrStr;
	NSDictionary *attributes;
	if (isError) {
		attributes = errAttr;
	} else {
		attributes = textAttr;
	}
	if (originalEnd > 0) {
		// Make sure to add a double linebreak to separate it out visually from the rest
		attrStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n\n%@", [str stringByTrimmingWhitespaceAndNewlines]] attributes:attributes];
	} else {
		// No previous content, so just insert what we've got
		attrStr = [[NSAttributedString alloc] initWithString:[str stringByTrimmingWhitespaceAndNewlines] attributes:attributes];
	}
	// Append our string!
	[[self textStorage] beginEditing];
	[[self textStorage] appendAttributedString:attrStr];
	[[self textStorage] endEditing];
	// Scroll to the beginning of our new text if there previously was text (compensating for the linebreaks)
	if (originalEnd > 0) {
		[self scrollRangeToVisible:NSMakeRange(originalEnd + 2, 0)];
	}
	[attrStr release];
}

- (void)appendString:(NSString *)str {
	[self appendString:str asError:NO];
}

- (void)appendError:(NSString *)str {
	[self appendString:str asError:YES];
}

- (void)clearContents {
	// Clear out all contents
	[[self textStorage] deleteCharactersInRange:NSMakeRange(0, [[self textStorage] length])];
	// Reset the scroll position
	[self scrollRangeToVisible:NSMakeRange(0, 0)];
}

@end
