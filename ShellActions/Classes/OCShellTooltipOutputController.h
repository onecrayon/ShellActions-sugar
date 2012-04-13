//
//  OCShellTooltipOutputController.h
//  ShellActions
//
//  Created by Ian Beck on 04/10/12.
//  Copyright 2012 One Crayon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MAAttachedWindow.h"


@interface OCShellTooltipOutputController : NSViewController {
@private
	NSTextView *labelText;
	MAAttachedWindow *tooltipWindow;
	NSWindow *rootWindow;
	id eventMonitor;
}

@property(retain) IBOutlet NSTextView *labelText;

+ (id)sharedController;

- (void)displayString:(NSString *)outputString inContext:(id)context;
- (void)clearTooltip;

@end
