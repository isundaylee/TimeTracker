#define ARROW_WIDTH 12
#define ARROW_HEIGHT 8

#define CORNER_RADIUS 6.0f

@interface BackgroundView : NSView
{
    NSInteger _arrowX;
}

@property (nonatomic, assign) NSInteger arrowX;

@end
