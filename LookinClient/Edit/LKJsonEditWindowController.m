//
//  LKAboutWindowController.m
//  LookinClient
//
//  Created by 李凯 on 2019/10/30.
//  Copyright © 2019 hughkli. All rights reserved.
//

#import "LKJsonEditWindowController.h"
#import "LKJsonEditController.h"
#import "LKWindow.h"

@interface LKJsonEditWindowController ()
@property(copy) NSString *jsonString;
@end

@implementation LKJsonEditWindowController

- (instancetype)init {
    NSSize screenSize = [NSScreen mainScreen].frame.size;
    LKWindow *window = [[LKWindow alloc] initWithContentRect:NSMakeRect(0, 0, MIN(screenSize.width * .5, 800), MIN(screenSize.height * .5, 500)) styleMask:NSWindowStyleMaskFullSizeContentView|NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable|NSWindowStyleMaskUnifiedTitleAndToolbar backing:NSBackingStoreBuffered defer:YES];
    window.backgroundColor = [NSColor clearColor];
    window.tabbingMode = NSWindowTabbingModeDisallowed;
    window.minSize = NSMakeSize(600, 300);
    [window center];
    
    if (self = [self initWithWindow:window]) {
        LKJsonEditController *vc = [LKJsonEditController new];
        window.contentView = vc.view;
        self.contentViewController = vc;
    }
    return self;
}



@end
