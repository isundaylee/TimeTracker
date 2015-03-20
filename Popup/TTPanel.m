#import "TTPanel.h"

@implementation TTPanel

- (BOOL)canBecomeKeyWindow;
{
    return YES; // Allow Search field to become the first responder
}

@end
