//
//  ReportWindowController.h
//  Popup
//
//  Created by Jiahao Li on 3/13/15.
//
//

#import <Cocoa/Cocoa.h>

@interface ReportWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *tableView;

- (void) refresh; 

@end
