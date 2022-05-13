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
#import "LKPreferenceManager.h"
#import "LookinAttributesSection.h"
#import "LKUserActionManager.h"
#import "LKWindowToolbarHelper.h"
#import "LKDashboardViewController.h"
#import "LKStaticHierarchyDataSource.h"
#import "LKDashboardCardView.h"
#import "LookinDefines.h"
#import "LKAppsManager.h"
#import "LKPreferenceManager.h"
#import "LKStaticAsyncUpdateManager.h"
#import "LKReadHierarchyDataSource.h"
#import "LookinDashboardBlueprint.h"
#import "LKUserActionManager.h"
#import "LKDashboardSearchInputView.h"
#import "LKDashboardSearchPropView.h"
#import "LookinAttributesSection.h"
#import "LKDashboardSectionView.h"
#import "LKDashboardSearchMethodsView.h"
#import "LKDashboardSearchMethodsDataSource.h"


@interface LKJsonEditWindowController ()<NSToolbarDelegate>
@property(copy) NSString *jsonString;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSToolbarItem *> *toolbarItemsMap;
@end

@implementation LKJsonEditWindowController

- (instancetype)init {
    NSSize screenSize = [NSScreen mainScreen].frame.size;
    LKWindow *window = [[LKWindow alloc] initWithContentRect:NSMakeRect(0, 0, MIN(screenSize.width * .5, 800), MIN(screenSize.height * .5, 500)) styleMask:NSWindowStyleMaskFullSizeContentView|NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable|NSWindowStyleMaskUnifiedTitleAndToolbar backing:NSBackingStoreBuffered defer:YES];
    window.backgroundColor = [NSColor clearColor];
    window.tabbingMode = NSWindowTabbingModeDisallowed;
    window.minSize = NSMakeSize(1120, 800);
    [window center];
    [window setFrameUsingName:LKWindowSizeName_Json];
    
    if (self = [self initWithWindow:window]) {
        LKJsonEditController *vc = [LKJsonEditController new];
        window.contentView = vc.view;
        self.contentViewController = vc;
        
        NSToolbar *toolbar = [[NSToolbar alloc] init];
        toolbar.displayMode = NSToolbarDisplayModeIconAndLabel;
        toolbar.sizeMode = NSToolbarSizeModeRegular;
        toolbar.delegate = self;
        window.toolbar = toolbar;

    }
    return self;
}
-(void)refresh {
    LKJsonEditController *vc = self.contentViewController;
    [vc loadJsonEditor];
}
#pragma mark - NSToolbarDelegate

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [self toolbarDefaultItemIdentifiers:toolbar];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return @[LKToolBarIdentifier_JsonDataSave];
}

- (nullable NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *item = self.toolbarItemsMap[itemIdentifier];
    if (!item) {
        if (!self.toolbarItemsMap) {
            self.toolbarItemsMap = [NSMutableDictionary dictionary];
        }
        item = [[LKWindowToolbarHelper sharedInstance] makeToolBarItemWithIdentifier:itemIdentifier preferenceManager:[LKPreferenceManager mainManager]];
        self.toolbarItemsMap[itemIdentifier] = item;
        
        if ([item.itemIdentifier isEqualToString:LKToolBarIdentifier_JsonDataSave]) {
            item.label = NSLocalizedString(@"SaveAndRefresh", nil);
            item.target = self;
            item.action = @selector(_saveString:);
        }
    }
    return item;
}

- (void)_saveString:(NSButton *) button{
    LKJsonEditController *vc = self.contentViewController;
    @weakify(self);
    [vc saveStringwithBlock:^(NSString *saveJson) {
        @strongify(self);
        [[self modifyAttribute:self.attribute newValue:@[saveJson]] subscribeError:^(NSError * _Nullable error) {
            NSLog(@"修改返回 error");
        }];
    }];
    
}
//
//- (void)_handleSettingMenuItem:(NSMenuItem *)item {
//    [LKPreferenceManager mainManager].callStackType = item.tag;
//}


- (RACSignal *)modifyAttribute:(LookinAttribute *)attribute newValue:(id)newValue {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        LookinDisplayItem *modifyingItem = attribute.targetDisplayItem;
        
        LookinAttributeModification *modification = [LookinAttributeModification new];
        if ([LookinDashboardBlueprint isUIViewPropertyWithAttrID:attribute.identifier]) {
            modification.targetOid = modifyingItem.viewObject.oid;
        } else {
            modification.targetOid = modifyingItem.layerObject.oid;
        }
        modification.setterSelector = [LookinDashboardBlueprint setterWithAttrID:attribute.identifier];
        modification.attrType = attribute.attrType;
        modification.value = newValue;
        
        if (!modification.setterSelector) {
            NSAssert(NO, @"");
            AlertError(LookinErr_Inner, self.contentViewController.view.window);
            [subscriber sendError:LookinErr_Inner];
        }
        
        if (![LKAppsManager sharedInstance].inspectingApp) {
            AlertError(LookinErr_NoConnect, self.contentViewController.view.window);
            [subscriber sendError:LookinErr_NoConnect];
        }
        
        @weakify(self);
        [[[LKAppsManager sharedInstance].inspectingApp submitModification:modification] subscribeNext:^(LookinDisplayItemDetail *detail) {
            NSLog(@"modification - succ");
            @strongify(self);
            LKInspectableApp *app = [LKAppsManager sharedInstance].inspectingApp;
            [[app fetchHierarchyData] subscribeNext:^(LookinHierarchyInfo *info) {
                [[LKStaticHierarchyDataSource sharedInstance] reloadWithHierarchyInfo:info keepState:NO AndRootItem: modifyingItem.superItem];
            } error:^(NSError * _Nullable error) {
                // error
                @strongify(self);
                
                [[NSAlert alertWithError:error] beginSheetModalForWindow:self.window completionHandler:nil];
            }];
        } error:^(NSError * _Nullable error) {
            @strongify(self);
            AlertError(error, self.contentViewController.view.window);
            [subscriber sendError:error];
        }];
        
        return nil;
    }];
}


@end
