//
//  LKJsonEditController.m
//  LookinClient
//
//  Created by Xs on 2022/5/9.
//  Copyright © 2022 hughkli. All rights reserved.
//

#import "LKJsonEditController.h"
#import <JavaScriptCore/JavaScriptCore.h>
@interface LKJsonEditController ()

@property (copy) NSString *htmlString;
@end

@implementation LKJsonEditController

-(void)viewDidLoad {
    [super viewDidLoad];
}

- (NSView *)makeContainerView {
    LKBaseView *containerView = [LKBaseView new];
    self.webView = [LKJsonEditWebView new];
    self.webView.hidden = YES;
    self.webView.navigationDelegate = self;
    if (@available(macOS 12.0, *)) {
        self.webView.underPageBackgroundColor = [NSColor colorWithSRGBRed:30/255.0 green:30/255.0 blue:30/255.0 alpha:1];
    } else {
        // Fallback on earlier versions
    }
//    self.webView.enclosingScrollView.verticalScrollElasticity = NSScrollElasticityAutomatic;
//    self.webView.enclosingScrollView.horizontalScrollElasticity = NSScrollElasticityAutomatic;
    [containerView addSubview:self.webView];
    return containerView;
}
- (void)viewDidLayout {
    [super viewDidLayout];
    $(self.webView).width(self.view.bounds.size.width).height(self.view.bounds.size.height).horAlign;
    
}
- (void)viewDidAppear {
    [super viewDidAppear];
    [self loadJsonEditor];
}


- (void)loadJsonEditor
{
    
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"index"
                                                         ofType:@"html"
                                                    inDirectory:@"EditStatic"];
    NSURL* fileURL = [NSURL fileURLWithPath:filePath];
    NSURLRequest* request = [NSURLRequest requestWithURL:fileURL];
    [self.webView loadRequest:request];

}

- (void)webViewShow:(WebView *)sender {
    [self autoFormattor];
    
}

-(void) saveString {
    [_webView evaluateJavaScript:@"saveToString()"
               completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
        //获取修改后的数据并保存,用于数据回传并刷新
        NSString *saveString = (NSString*)obj;
        
    }];
}

- (void) autoFormattor
{
    [self.webView evaluateJavaScript:@"autoFormattor()" completionHandler:nil];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.webView.hidden = NO;
    [self autoFormattor];
    [self saveString];
}



@end
