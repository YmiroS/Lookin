//
//  LKNavigationManager.m
//  Lookin
//
//  Created by Li Kai on 2018/11/3.
//  https://lookin.work
//

#import "LKNavigationManager.h"
#import "LKLaunchWindowController.h"
#import "LKStaticWindowController.h"
#import "LKPreferenceWindowController.h"
#import "LKStaticViewController.h"
#import "LKPreviewController.h"
#import "LKPreviewController.h"
#import "LKAppsManager.h"
#import "LookinHierarchyFile.h"
#import "LKReadWindowController.h"
#import "LKMethodTraceWindowController.h"
#import "LKConsoleViewController.h"
#import "LKPreferenceManager.h"
#import "LKAboutWindowController.h"
#import "LKJsonEditWindowController.h"
#import "LookinAttribute.h"
#import "NSDictionary+Addition.h"


@interface LKNavigationManager ()

@property(nonatomic, strong) LKPreferenceWindowController *preferenceWindowController;
@property(nonatomic, strong) LKAboutWindowController *aboutWindowController;

@end

@implementation LKNavigationManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static LKNavigationManager *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone{
    return [self sharedInstance];
}

- (void)showLaunch {
    _launchWindowController = [[LKLaunchWindowController alloc] init];
    [self.launchWindowController showWindow:self];
}

- (void)showStaticWorkspace {
    if (!self.staticWindowController) {
        _staticWindowController = [[LKStaticWindowController alloc] init];
        self.staticWindowController.window.delegate = self;
    }
    [self.staticWindowController showWindow:self];
}

- (void)closeLaunch {
    [self.launchWindowController close];
    _launchWindowController = nil;
}

- (void)showPreference {
    if (!self.preferenceWindowController) {
        self.preferenceWindowController = [LKPreferenceWindowController new];
        self.preferenceWindowController.window.delegate = self;
    }
    [self.preferenceWindowController showWindow:self];
}

- (void)showAbout {
    if (!self.aboutWindowController) {
        _aboutWindowController = [[LKAboutWindowController alloc] init];
        self.aboutWindowController.window.delegate = self;
    }
    [self.aboutWindowController showWindow:self];
}

- (void)showMethodTrace {
    if (!self.methodTraceWindowController) {
        if (![LKAppsManager sharedInstance].inspectingApp) {
            NSWindow *window = self.staticWindowController.window;
            AlertErrorText(NSLocalizedString(@"Can not use Method Trace at this time.", nil), NSLocalizedString(@"Lost connection with the iOS app.", nil), window);
            return;
        }
        
        _methodTraceWindowController = [LKMethodTraceWindowController new];
        self.methodTraceWindowController.window.delegate = self;
    }
    [self.methodTraceWindowController showWindow:self];
}

- (void)showJsonEdit: (NSString *)jsonString AndAttribute:(LookinAttribute *)attribute {
    [self replaceJsonData:jsonString];
    if (!self.jsonEditWindowController) {
        _jsonEditWindowController = [LKJsonEditWindowController new];
        self.jsonEditWindowController.window.delegate = self;
    }
    self.jsonEditWindowController.isGaiaX = NO;
    self.jsonEditWindowController.title = @"json 数据";
    [self.jsonEditWindowController refresh];
    self.jsonEditWindowController.attribute = attribute;
    [self.jsonEditWindowController showWindow:self];
}

- (void)showGaiaXEdit: (NSString *)jsonString AndAttribute:(LookinAttribute *)attribute {
    [self replaceGaiaXData:jsonString];
    if (!self.jsonEditWindowController) {
        _jsonEditWindowController = [LKJsonEditWindowController new];
        self.jsonEditWindowController.window.delegate = self;
        self.jsonEditWindowController.isGaiaX = YES;
        self.jsonEditWindowController.title = @"GaiaX 模板信息";
    }
    self.jsonEditWindowController.isGaiaX = YES;
    self.jsonEditWindowController.title = @"GaiaX 模板信息";
    [self.jsonEditWindowController refresh];
    self.jsonEditWindowController.attribute = attribute;
    [self.jsonEditWindowController showWindow:self];
}



-(void) replaceJsonData:(NSString *) jsonData {
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"main"
                                                         ofType:@"html"
                                                    inDirectory:@"EditStatic"];
    NSMutableString *htmlString = [NSMutableString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    NSMutableDictionary *jsonDict = [[NSDictionary dictionaryWithJsonString:jsonData] mutableCopy];
    
    NSString *zyString = [[self dictionaryEscapeAddWithdict:jsonDict] jsonString];
    
    NSString *newhtmlString = [htmlString stringByReplacingOccurrencesOfString:@"{%$#@!}" withString:zyString];
    NSString* newfilePath = [[NSBundle mainBundle] pathForResource:@"index"
                                                         ofType:@"html"
                                                    inDirectory:@"EditStatic"];
    BOOL success = [newhtmlString writeToFile:newfilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

-(void) replaceGaiaXData:(NSString *) jsonData {
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"main"
                                                         ofType:@"html"
                                                    inDirectory:@"EditStatic"];
    NSMutableString *htmlString = [NSMutableString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSString *zyString = [self stringGaiaXEscapeAddWithString:jsonData];
    NSString *newhtmlString = [htmlString stringByReplacingOccurrencesOfString:@"{%$#@!}" withString:zyString];
    NSString* newfilePath = [[NSBundle mainBundle] pathForResource:@"index"
                                                         ofType:@"html"
                                                    inDirectory:@"EditStatic"];
    BOOL success = [newhtmlString writeToFile:newfilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}



- (NSDictionary *) dictionaryEscapeAddWithdict: (NSMutableDictionary*) dic {
    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            dic[key] = [self stringEscapeAddWithString:(NSString*)obj];
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary * tempDic = [[NSMutableDictionary alloc] initWithDictionary:obj];
            [self dictionaryEscapeAddWithdict: tempDic];
            dic[key] = tempDic;
        } else if ([obj isKindOfClass:[NSArray class]]) {
            NSMutableArray *tempArray = [NSMutableArray new];
            for (id value in (NSArray*) obj) {
                if ([value isKindOfClass:[NSDictionary class]]) {
                    NSMutableDictionary * tempDic = [[NSMutableDictionary alloc] initWithDictionary:value];
                    [self dictionaryEscapeAddWithdict:tempDic];
                    [tempArray addObject:tempDic];
                } else if ([value isKindOfClass:[NSString class]]) {
                    NSString *tempString = [self stringEscapeAddWithString:(NSString*)value];
                    [tempArray addObject:tempString];
                } else if ([value isKindOfClass:[NSArray class]]) {
                    NSMutableArray *doubleArray = [NSMutableArray new];
                    for (id oneObj in value) {
                        if ([oneObj isKindOfClass:[NSDictionary class]]) {
                            NSMutableDictionary * tempDic = [[NSMutableDictionary alloc] initWithDictionary:oneObj];
                            [self dictionaryEscapeAddWithdict:tempDic];
                            [doubleArray addObject:tempDic];
                        }
                    }
                    [tempArray addObject:doubleArray];
                }
            }
            dic[key] = [tempArray copy];
        }
    }];
    return dic;
}

- (NSString *) stringEscapeAddWithString: (NSString*)string {
    NSString *specialString = @"\"";
    NSString *specialString2 = @"\\\\";
    NSString *replaceText = @"\\\"";
    NSString *replaceText2 = @"\\\\\\";
    
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

    if ([zyString localizedStandardContainsString:specialString2]) { // 效果等同于[message containsString:specialString]
        // 遍历所有字符串
        zyString = [[zyString stringByReplacingOccurrencesOfString:specialString2 withString:replaceText2] mutableCopy];
    }
    return zyString;
}

- (NSString *) stringGaiaXEscapeAddWithString: (NSString*)string {
    NSString *specialString = @"'";
    NSString *replaceText = @"\"";
    
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
    return zyString;
}


- (LKWindowController *)currentKeyWindowController {
    NSWindow *keyWindow = [NSApplication sharedApplication].keyWindow;
    if ([keyWindow.windowController isKindOfClass:[LKWindowController class]]) {
        return keyWindow.windowController;
    }
    return nil;
}

- (BOOL)showReaderWithFilePath:(NSString *)filePath error:(NSError **)error {
    NSData *data = [NSData dataWithContentsOfFile:filePath options:0 error:error];
    if (!data) {
        return NO;
    }
    
    id dataObj = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSObject class] fromData:data error:error];
    if (!dataObj) {
        // 比如拖了一个 pdf 格式的文件进来就会走到这里
        if (error) {
            *error = [NSError errorWithDomain:LookinErrorDomain code:LookinErrCode_UnsupportedFileType userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Failed to open the document.", nil), NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"The file type is not supported.", nil)}];
        }
        return NO;
    }
    
    NSError *verifyError = [LookinHierarchyFile verifyHierarchyFile:dataObj];
    if (verifyError) {
        // 有问题，无法打开
        if (error) {
            *error = verifyError;
        }
        return NO;
    }
    
    // 文件校验无误
    NSString *title = [[NSFileManager defaultManager] displayNameAtPath:filePath];
    [self showReaderWithHierarchyFile:dataObj title:title];
    return YES;
}

- (void)showReaderWithHierarchyFile:(LookinHierarchyFile *)file title:(NSString *)title {
    LKReadWindowController *wc = [[LKReadWindowController alloc] initWithFile:file];
    wc.window.title = title ? : @"";
    wc.window.delegate = self;
    [wc showWindow:self];
    
    if (!self.readWindowControllers) {
        self.readWindowControllers = [NSMutableArray array];
    }
    [self.readWindowControllers addObject:wc];
}

#pragma mark - <NSWindowDelegate>


/**
 staticWindowController 关闭时不要直接释放，因为点击 methodTrace 窗口的“连接已断开” tips 需要唤起 static 窗口来切换 App
 */
- (void)windowWillClose:(NSNotification *)notification {
    NSWindow *closingWindow = notification.object;
    
    if (closingWindow == self.preferenceWindowController.window) {
        _preferenceWindowController = nil;
        
    } else if (closingWindow == self.staticWindowController.window) {
        [closingWindow saveFrameUsingName:LKWindowSizeName_Static];
        
    } else if (closingWindow == self.methodTraceWindowController.window) {
        [closingWindow saveFrameUsingName:LKWindowSizeName_Methods];
        _methodTraceWindowController = nil;
        
    } else if (closingWindow == self.aboutWindowController.window) {
        self.aboutWindowController = nil;
        
    } else {
        LKReadWindowController *wc = [self.readWindowControllers lookin_firstFiltered:^BOOL(LKReadWindowController *obj) {
            return obj.window == closingWindow;
        }];
        [self.readWindowControllers removeObject:wc];
    }
}

@end
