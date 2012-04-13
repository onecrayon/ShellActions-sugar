//
//  OCShellTooltipOutputController.h
//  ShellActions
//
//  Created by Ian Beck on 04/10/12.
//  Copyright 2012 One Crayon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MAAttachedWindow.h"


@interface OCShellTooltipOutputController : NSObject {
@private
	NSView *view;
	NSTextView *labelText;
	MAAttachedWindow *tooltipWindow;
	NSWindow *rootWindow;
	id eventMonitor;
}

- (void)displayString:(NSString *)outputString inTextActionContext:(id)context forRange:(NSRange)range;

@end
