#import "TTStatusItemView.h"

@implementation TTStatusItemView

@synthesize statusItem = _statusItem;
@synthesize image = _image;
@synthesize alternateImage = _alternateImage;
@synthesize isHighlighted = _isHighlighted;
@synthesize action = _action;
@synthesize target = _target;
@synthesize text = _text;

#pragma mark -

- (id)initWithStatusItem:(NSStatusItem *)statusItem
{
    CGFloat itemWidth = [statusItem length];
    CGFloat itemHeight = [[NSStatusBar systemStatusBar] thickness];
    NSRect itemRect = NSMakeRect(0.0, 0.0, itemWidth, itemHeight);
    self = [super initWithFrame:itemRect];
    
    if (self != nil) {
        _statusItem = statusItem;
        _statusItem.view = self;
        _text = @"Idle";
    }
    return self;
}

- (NSString *)text {
    return _text;
}

- (void)setText:(NSString *)text {
    _text = text;
    [self setNeedsDisplay:YES];
}


#pragma mark -

- (void)drawRect:(NSRect)dirtyRect
{
	// Set up dark mode for icon
    if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"]  isEqual: @"Dark"])
    {
        self.image = [NSImage imageNamed:@"StatusHighlighted"];
    }
    else
    {
        if (self.isHighlighted)
            self.image = [NSImage imageNamed:@"StatusHighlighted"];
        else
            self.image = [NSImage imageNamed:@"Status"];
    }
	[self.statusItem drawStatusBarBackgroundInRect:dirtyRect withHighlight:self.isHighlighted];
    
    NSImage *icon = self.image;
    NSSize iconSize = [icon size];
    NSRect bounds = self.bounds;
    CGFloat iconX = roundf((NSWidth(bounds) - iconSize.width) / 2);
    CGFloat iconY = roundf((NSHeight(bounds) - iconSize.height) / 2);
    CGFloat horizontalPadding = 10.0f;
    CGFloat textSize = 14.0f;
    CGFloat textPadding = 3.0f;

//	[icon drawAtPoint:iconPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    NSString *text = self.text;
    NSMutableDictionary *stringAttrs = [[NSMutableDictionary alloc] init];
    
    if (self.isHighlighted) {
        [stringAttrs setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
    } else {
        [stringAttrs setValue:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
    }
    
    [stringAttrs setValue:[NSFont fontWithName:@"HelveticaNeue" size:textSize] forKey:NSFontAttributeName];
    
    NSSize size = [text sizeWithAttributes:stringAttrs];
    
    [text drawAtPoint:CGPointMake(horizontalPadding, textPadding) withAttributes:stringAttrs];
//    [text drawInRect:NSMakeRect(0, 0, 100, 30) withAttributes:stringAttrs];
    
    _statusItem.length = 2 * horizontalPadding + size.width;
}

#pragma mark -
#pragma mark Mouse tracking

- (void)mouseDown:(NSEvent *)theEvent
{
    [NSApp sendAction:self.action to:self.target from:self];
}

#pragma mark -
#pragma mark Accessors

- (void)setHighlighted:(BOOL)newFlag
{
    if (_isHighlighted == newFlag) return;
    _isHighlighted = newFlag;
    [self setNeedsDisplay:YES];
}

#pragma mark -

- (void)setImage:(NSImage *)newImage
{
    if (_image != newImage) {
        _image = newImage;
        [self setNeedsDisplay:YES];
    }
}

- (void)setAlternateImage:(NSImage *)newImage
{
    if (_alternateImage != newImage) {
        _alternateImage = newImage;
        if (self.isHighlighted) {
            [self setNeedsDisplay:YES];
        }
    }
}

#pragma mark -

- (NSRect)globalRect
{
    NSRect frame = [self frame];
    return [self.window convertRectToScreen:frame];
}
@end
