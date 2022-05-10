//
//  LKJsonEditWebView.m
//  LookinClient
//
//  Created by Xs on 2022/5/9.
//  Copyright © 2022 hughkli. All rights reserved.
//

#import "LKJsonEditWebView.h"

@implementation LKJsonEditWebView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}
-(void)scrollWheel:(NSEvent *)event {
    NSLog(@"%@",event);
    [super scrollWheel:event];
//    [[self nextResponder] scrollWheel:event];
}

@end
