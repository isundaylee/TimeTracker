#define STATUS_ITEM_VIEW_WIDTH 100

#pragma mark -

@class TTStatusItemView;

@interface TTMenubarController : NSObject {
@private
    TTStatusItemView *_statusItemView;
}

@property (nonatomic) BOOL hasActiveIcon;
@property (nonatomic, strong, readonly) NSStatusItem *statusItem;
@property (nonatomic, strong, readonly) TTStatusItemView *statusItemView;

@end
