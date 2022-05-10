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
    window.minSize = NSMakeSize(600, 300);
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
            item.target = self.contentViewController;
            item.action = @selector(saveString);
        }
    }
    return item;
}

- (void)_handleSetting:(NSButton *)button {
    LKPreferenceManager *manager = [LKPreferenceManager mainManager];

    NSArray<NSNumber *> *options = @[@(LookinPreferredCallStackTypeDefault), @(LookinPreferredCallStackTypeFormattedCompletely), @(LookinPreferredCallStackTypeRaw)];
    NSUInteger selectedIdx = [options indexOfObject:@(manager.callStackType)];
    
    NSArray<NSString *> *strings = @[NSLocalizedString(@"Format stacks and hide frames in system libraries", nil), NSLocalizedString(@"Format stacks and show all frames", nil), NSLocalizedString(@"Show raw informations", nil)];
    
    NSMenu *menu = [NSMenu new];
    [strings enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMenuItem *item = [NSMenuItem new];
        if (idx == selectedIdx) {
            item.state = NSControlStateValueOn;
        } else {
            item.state = NSControlStateValueOff;
        }
        item.tag = idx;
        item.title = obj;
        item.image = [[NSImage alloc] initWithSize:NSMakeSize(1, 24)];
        item.target = self;
        item.action = @selector(_handleSettingMenuItem:);
        [menu addItem:item];
    }];
    
    [menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0, button.bounds.size.height) inView:button];
}

- (void)_handleSettingMenuItem:(NSMenuItem *)item {
    [LKPreferenceManager mainManager].callStackType = item.tag;
}


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
//            if (self.staticDataSource) {
//                [self.staticDataSource modifyWithDisplayItemDetail:detail];
//                if ([LookinDashboardBlueprint needPatchAfterModificationWithAttrID:attribute.identifier]) {
//                    [[LKStaticAsyncUpdateManager sharedInstance] updateAfterModifyingDisplayItem:(LookinStaticDisplayItem *)modifyingItem];
//                }
//
//            } else {
//                NSAssert(NO, @"");
//            }
            [subscriber sendNext:nil];
            
        } error:^(NSError * _Nullable error) {
            @strongify(self);
            AlertError(error, self.contentViewController.view.window);
            [subscriber sendError:error];
        }];
        
        return nil;
    }];
}


@end
