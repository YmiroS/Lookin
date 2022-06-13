//
//  LKJsonEditController.m
//  LookinClient
//
//  Created by Xs on 2022/5/9.
//  Copyright © 2022 hughkli. All rights reserved.
//

#import "LKJsonEditController.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "NSDictionary+Addition.h"
@interface LKJsonEditController ()

@property (copy) NSString *htmlString;
@end

@implementation LKJsonEditController

-(void)viewDidLoad {
    [super viewDidLoad];
}

- (NSView *)makeContainerView {
    LKBaseView *containerView = [LKBaseView new];
    containerView.backgroundColor = [NSColor colorWithSRGBRed:30/255.0 green:30/255.0 blue:30/255.0 alpha:1];
    self.webView = [LKJsonEditWebView new];
    self.webView.hidden = YES;
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self;
    if (@available(macOS 12.0, *)) {
        self.webView.underPageBackgroundColor = [NSColor colorWithSRGBRed:30/255.0 green:30/255.0 blue:30/255.0 alpha:1];
    } else {
        // Fallback on earlier versions
    }
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

-(void) saveStringwithBlock:(void (^)(NSString* saveJson))nextBlock {
    [_webView evaluateJavaScript:@"saveToString()"
               completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
        //获取修改后的数据并保存,用于数据回传并刷新
        NSString *saveString = [self stringEscapeDeleteWithString:(NSString*)obj];
        NSDictionary* dic = [NSDictionary dictionaryWithJsonString: saveString];
        NSString *str = [dic jsonString];
        nextBlock(str);
    }];
}


//- (NSDictionary *) dictionaryEscapeAddWithdict: (NSMutableDictionary*) dic {
//    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
//        if ([obj isKindOfClass:[NSString class]]) {
//            dic[key] = [self stringEscapeDeleteWithString:(NSString*)obj];
//        } else if ([obj isKindOfClass:[NSDictionary class]]) {
//            NSMutableDictionary * tempDic = [[NSMutableDictionary alloc] initWithDictionary:obj];
//            [self dictionaryEscapeAddWithdict: tempDic];
//            dic[key] = tempDic;
//        } else if ([obj isKindOfClass:[NSArray class]]) {
//            NSMutableArray *tempArray = [NSMutableArray new];
//            for (id value in (NSArray*) obj) {
//                NSMutableDictionary * tempDic = [[NSMutableDictionary alloc] initWithDictionary:value];
//                if ([value isKindOfClass:[NSDictionary class]]) {
//                    [self dictionaryEscapeAddWithdict:tempDic];
//                    [tempArray addObject:tempDic];
//                } else if ([value isKindOfClass:[NSString class]]) {
//                    NSString *tempString = [self stringEscapeDeleteWithString:(NSString*)value];
//                    [tempArray addObject:tempString];
//                }
//            }
//            dic[key] = [tempArray copy];
//        }
//    }];
//    return dic;
//}

- (NSString *) stringEscapeDeleteWithString: (NSString*)string {
    NSString *specialString = @"\\";
//    NSString *specialString2 = @"\\";
    NSString *replaceText = @"";
//    NSString *replaceText2 = @"\\\\";
    
    NSMutableString *zyString = [[NSMutableString alloc] initWithString: string];
    if ([zyString localizedStandardContainsString:specialString]) { // 效果等同于[message containsString:specialString]
        // 遍历所有字符串
        [zyString enumerateSubstringsInRange:NSMakeRange(0, zyString.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
            if ([substring isEqualToString:specialString]) {
                // 转义特殊字符串
                [zyString replaceOccurrencesOfString:substring withString:replaceText options:NSLiteralSearch range:enclosingRange];
            }
        }];
    }

//    if ([zyString localizedStandardContainsString:specialString2]) { // 效果等同于[message containsString:specialString]
//        // 遍历所有字符串
//        [zyString enumerateSubstringsInRange:NSMakeRange(0, zyString.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
//            if ([substring isEqualToString:specialString2]) {
//                // 转义特殊字符串
//                [zyString replaceOccurrencesOfString:substring withString:replaceText2 options:NSLiteralSearch range:enclosingRange];
//            }
//        }];
//    }
    return zyString;
}



- (void) autoFormattor
{
    [self.webView evaluateJavaScript:@"autoFormattor()" completionHandler:nil];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self autoFormattor];
    self.webView.hidden = NO;
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (navigationAction.request.URL) {
        [[NSWorkspace sharedWorkspace] openURL:navigationAction.request.URL];
    }
    return nil;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
