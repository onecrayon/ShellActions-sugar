//
//  OCShellConsoleOutputController.h
//  ShellActions
//
//  Created by Ian Beck on 3/2/12.
//  Copyright 2012 Ian Beck. MIT license.
//

#import <Cocoa/Cocoa.h>
#import "OCShellConsoleTextView.h"


@interface OCShellConsoleOutputController : NSWindowController {
@private
    OCShellConsoleTextView *outputText;
}

@property (retain) IBOutlet OCShellConsoleTextView *outputText;

+ (id)sharedController;

- (void)displayString:(NSString *)outputString;
- (void)displayError:(NSString *)outputString;

- (IBAction)clearConsole:(id)sender;

@end
