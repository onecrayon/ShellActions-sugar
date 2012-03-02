//
//  OCShellHTMLOutputController.h
//  ShellActions
//
//  Created by Ian Beck on 2/29/12.
//  Copyright 2012 Ian Beck. MIT license.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface OCShellHTMLOutputController : NSWindowController {
@private
    WebView *webView;
	NSButton *saveSourceButton;
	NSButton *openInEspressoCheckbox;
	NSView *saveAccessories;
}

@property (retain) IBOutlet WebView *webView;
@property (retain) IBOutlet NSButton *saveSourceButton;
@property (retain) IBOutlet NSButton *openInEspressoCheckbox;
@property (retain) IBOutlet NSView *saveAccessories;

+ (id)sharedController;

- (void)loadSource:(NSString *)htmlSource withBaseURL:(NSString *)basePath;

- (IBAction)saveHTMLAs:(id)sender;

@end
