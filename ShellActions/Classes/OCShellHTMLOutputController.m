//
//  OCShellHTMLOutputController.m
//  ShellActions
//
//  Created by Ian Beck on 2/29/12.
//  Copyright 2012 MacRabbit. All rights reserved.
//

#import "OCShellHTMLOutputController.h"


@implementation OCShellHTMLOutputController

@synthesize webView;
@synthesize navigateButtons;
@synthesize reloadButton;
@synthesize browserButton;

static OCShellHTMLOutputController *sharedObject = nil;

+ (OCShellHTMLOutputController *)sharedController {
	if (sharedObject == nil) {
		sharedObject = [[self alloc] init];
		[NSBundle loadNibNamed:@"OCShellHTMLOutputWindow" owner:sharedObject];
	}
	return sharedObject;
}

- (void)dealloc {
	MRRelease(sharedObject);
    [super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)loadSource:(NSString *)htmlSource withBaseURL:(NSString *)basePath {
	// Set the default font sizes to the browser defaults (since otherwise it defaults to 12pt for some reason)
	if ([[webView preferences] defaultFontSize] != 16) {
		WebPreferences *defaults = [[WebPreferences alloc] init];
		[defaults setDefaultFontSize:16];
		[defaults setDefaultFixedFontSize:13];
		[webView setPreferences:defaults];
		[defaults release];
	}
	[[webView mainFrame] loadHTMLString:htmlSource baseURL:[NSURL URLWithString:basePath]];
	[self showWindow:self];
}

- (IBAction)navigateWebview:(id)sender {
	
}

- (IBAction)saveHTMLAs:(id)sender {
	
}

#pragma FrameLoadDelegate methods

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
	[[sender window] setTitle:@"Loading..."];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	if (![[sender mainFrameTitle] isEqualToString:@""]) {
		[[self window] setTitle:[sender mainFrameTitle]];
	} else {
		[[self window] setTitle:@"HTML Sugar Output"];
	}
}

@end
