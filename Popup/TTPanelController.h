#import "TTBackgroundView.h"
#import "TTStatusItemView.h"

@class TTPanelController;

@protocol PanelControllerDelegate <NSObject>

- (IBAction)togglePanel:(id)sender;
- (void)setStatusItemText:(NSString *)text;

@optional

- (TTStatusItemView *)statusItemViewForPanelController:(TTPanelController *)controller;

@end

#pragma mark -

@interface TTPanelController : NSWindowController <NSWindowDelegate>
{
    BOOL _hasActivePanel;
    __unsafe_unretained TTBackgroundView *_backgroundView;
    __unsafe_unretained id<PanelControllerDelegate> _delegate;
    __unsafe_unretained NSSearchField *_searchField;
    __unsafe_unretained NSTextField *_textField;
}

@property (nonatomic, unsafe_unretained) IBOutlet TTBackgroundView *backgroundView;
@property (nonatomic, unsafe_unretained) IBOutlet NSSearchField *searchField;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField *textField;

@property (nonatomic) BOOL hasActivePanel;
@property (nonatomic, unsafe_unretained, readonly) id<PanelControllerDelegate> delegate;

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate;

- (void)openPanel;
- (void)closePanel;

@end
