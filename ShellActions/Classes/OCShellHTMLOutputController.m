//
//  OCShellHTMLOutputController.m
//  ShellActions
//
//  Created by Ian Beck on 2/29/12.
//  Copyright 2012 Ian Beck. MIT license.
//

#import "OCShellHTMLOutputController.h"


@implementation OCShellHTMLOutputController

@synthesize webView;
@synthesize saveSourceButton;
@synthesize openInEspressoCheckbox;
@synthesize saveAccessories;

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

- (void)loadSource:(NSString *)htmlSource withBaseURL:(NSString *)basePath {
	// Set the default font sizes to the browser defaults (since otherwise it defaults to 12pt for some reason)
	if ([[webView preferences] defaultFontSize] != 16) {
		WebPreferences *defaults = [[WebPreferences alloc] init];
		[defaults setDefaultFontSize:16];
		[defaults setDefaultFixedFontSize:13];
		[webView setPreferences:defaults];
		[defaults release];
	}
	[[webView mainFrame] loadHTMLString:htmlSource baseURL:[NSURL fileURLWithPath:basePath]];
	[self showWindow:self];
}

- (IBAction)saveHTMLAs:(id)sender {
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setAccessoryView:saveAccessories];
	[savePanel setNameFieldStringValue:[NSString stringWithFormat:@"%@.html", [[self window] title]]];
	[savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger returnCode) {
		if (returnCode == NSFileHandlingPanelOKButton) {
			// User chose to save the file (rather than canceling the save panel)
			[[NSFileManager defaultManager] createFileAtPath:[[savePanel URL] path] contents:[[[webView mainFrame] dataSource] data] attributes:nil];
			if ([openInEspressoCheckbox state] == NSOnState) {
				// They want to open the file in Espresso immediately; do so!
				[[NSWorkspace sharedWorkspace] openFile:[[savePanel URL] path] withApplication:@"Espresso"];
			}
		}
	}];
}

#pragma mark FrameLoadDelegate methods

// Notify that the page is loading via the titlebar
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
	[[sender window] setTitle:@"Loading..."];
	[saveSourceButton setEnabled:NO];
}

// Set the title based on the <title> tag in the page
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	if (![[sender mainFrameTitle] isEqualToString:@""]) {
		[[self window] setTitle:[sender mainFrameTitle]];
	} else {
		[[self window] setTitle:@"HTML Sugar Output"];
	}
	[saveSourceButton setEnabled:YES];
}

#pragma mark WebPolicyDelegate methods

// Force all links to open in the user's default browser
- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
	if ([[actionInformation objectForKey:WebActionNavigationTypeKey] intValue] != WebNavigationTypeOther) {
		[listener ignore];
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
	} else {
		[listener use];
	}
}

@end
