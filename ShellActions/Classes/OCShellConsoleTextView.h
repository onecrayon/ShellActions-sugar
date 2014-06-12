//
//  OCShellConsoleTextView.h
//  ShellActions
//
//  Created by Ian Beck on 3/2/12.
//  Copyright 2012 Ian Beck. MIT license.
//

#import <Foundation/Foundation.h>


@interface OCShellConsoleTextView : NSTextView {
@private
    
}

- (void)appendString:(NSString *)str;
- (void)appendError:(NSString *)str;
- (void)clearContents;

@end
