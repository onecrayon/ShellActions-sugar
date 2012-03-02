//
//  OCShellHTMLOutputController.h
//  ShellActions
//
//  Created by Ian Beck on 2/29/12.
//  Copyright 2012 MacRabbit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface OCShellHTMLOutputController : NSWindowController {
@private
    WebView *webView;
	NSSegmentedControl *navigateButtons;
	NSButton *reloadButton;
	NSButton *browserButton;
}

@property (retain) IBOutlet WebView *webView;
@property (retain) IBOutlet NSSegmentedControl *navigateButtons;
@property (retain) IBOutlet NSButton *reloadButton;
@property (retain) IBOutlet NSButton *browserButton;

+ (id)sharedController;

- (void)loadSource:(NSString *)htmlSource withBaseURL:(NSString *)basePath;

- (IBAction)navigateWebview:(id)sender;
- (IBAction)saveHTMLAs:(id)sender;

@end
