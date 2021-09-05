//
//  ManticoreOptionsTableViewController.m
//  manticore
//
//  Created by Corban Amouzou on 2021-09-04.
//

#import <Foundation/Foundation.h>
#import <UIkit/UIKit.h>
#import "ManticoreOptionsTableViewController.h"
#import "UserInterfacePreferences.h"
#import "JailbreakPreferences.h"

//static const NSDictionary<NSString *, NSString *> *iconList = @{};


enum Sections {
    PackageManagerSection,
    ThemeSection,
    ToggleSections,
    NumberOfSections,
};


@implementation ManticoreOptionsTableViewController {
    JailbreakPreferences *jbPrefs;
    UserInterfacePreferences *uiPrefs;
}



- (void) viewDidLoad {
    jbPrefs = JailbreakPreferences.shared;
    // A nice little goodie in there
    UIVisualEffectView *backgroundView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial]];
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.backgroundView = backgroundView;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 30, 0, 30);
    self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    self.tableView.showsVerticalScrollIndicator = false;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return NumberOfSections;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case PackageManagerSection:
        case ThemeSection:
            return 1;
        case ToggleSections:
            return 7;
        default:
            return 0;
    }
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    switch (indexPath.section) {
        case PackageManagerSection: {
            cell = [[PackageManagerSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cool"];
            break;
        }
        case ThemeSection: {
            break;
        }
        default:
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = @"Restore Root FS";
                    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero primaryAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
                        UISwitch *sender = action.sender;
                        [self->jbPrefs setRestoreRootFS:sender.on];
                        [UIView transitionWithView:self.tableView duration:0.35 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                            [self.tableView reloadData];
                        } completion:nil];
                    }]];
                    switchView.on = jbPrefs.restoreRootFS;
                    cell.accessoryView = switchView;
                    break;
                }
                case 1: {
                    cell.textLabel.text = @"Disable Updates";
                    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero primaryAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
                        UISwitch *sender = action.sender;
                        [self->jbPrefs setDisableUpdates:sender.on];
                    }]];
                    switchView.on = jbPrefs.disableUpdates;
                    cell.accessoryView = switchView;
                    break;
                }
                case 2: {
                    cell.textLabel.text = @"Max Memory Limit";
                    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero primaryAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
                        UISwitch *sender = action.sender;
                        [self->jbPrefs setMaxMemLimit:sender.on];
                    }]];
                    switchView.on = jbPrefs.maxMemLimit;
                    cell.accessoryView = switchView;
                    break;
                }
                case 3: {
                    cell.textLabel.text = @"Load Tweaks";
                    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero primaryAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
                        UISwitch *sender = action.sender;
                        [self->jbPrefs setLoadTweaks:sender.on];
                    }]];
                    switchView.on = jbPrefs.loadTweaks;
                    cell.accessoryView = switchView;
                    break;
                }
                case 4: {
                    cell.textLabel.text = @"Load Daemons";
                    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero primaryAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
                        UISwitch *sender = action.sender;
                        [self->jbPrefs setLoadDaemons:sender.on];
                    }]];
                    switchView.on = jbPrefs.loadDaemons;
                    cell.accessoryView = switchView;
                    break;
                }
                case 5: {
                    cell.textLabel.text = @"Show Log Window";
                    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero primaryAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
                        UISwitch *sender = action.sender;
                        [self->jbPrefs setShowLogWindow:sender.on];
                    }]];
                    switchView.on = jbPrefs.showLogWindow;
                    cell.accessoryView = switchView;
                    break;
                }
                case 6: {
                    cell.textLabel.text = @"Disable Screen Time";
                    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero primaryAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
                        UISwitch *sender = action.sender;
                        [self->jbPrefs setDisableScreenTime:sender.on];
                    }]];
                    switchView.on = jbPrefs.disableScreenTime;
                    cell.accessoryView = switchView;
                    break;
                }
            }
            //cell.textLabel.text = @"Unfinished";
            break;
    }
    cell.backgroundColor = [UIColor.systemGray2Color colorWithAlphaComponent:0.2];
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    cell.indentationWidth = 5;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 0;
    switch (indexPath.section) {
        case PackageManagerSection:
            switch (indexPath.row) {
                case 0:
                    height = 200;
                    break;
                    
                default:
                    break;
            }
            break;
            
        default:
            height = [super tableView:tableView heightForRowAtIndexPath:indexPath];
            break;
    }
    return height;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [UIView new];
}

@end

@implementation PackageManagerSelectionCell

- (id) init {
    if (self = [super init]) {
        UIView *mainView = self.contentView;
    }
    return self;
}

- (void) layoutConstraints {
    
}

@end
