#import "TTPanelController.h"
#import "TTApplicationDelegate.h"
#import "TTBackgroundView.h"
#import "TTStatusItemView.h"
#import "TTMenubarController.h"
#import "TTReportWindowController.h"
#import "CalendarStore/CalendarStore.h"

#define OPEN_DURATION .15
#define CLOSE_DURATION .1

#define SEARCH_INSET 17

#define POPUP_HEIGHT 122
#define PANEL_WIDTH 280
#define MENU_ANIMATION_DURATION .1

#pragma mark -

@interface TTPanelController () {
    NSButton *_reportButton;
    TTReportWindowController *_reportWindowController;
}

@property (nonatomic, strong) NSArray *workTypes;
@property (nonatomic, strong) NSMutableArray *workButtons;
@property (nonatomic, strong) NSButton *stopButton;
@property (nonatomic) CGFloat panelHeight;
@property (nonatomic) BOOL isCounting;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSString *currentWorkType;
@property (nonatomic) CGFloat trackingPanelHeight;
@property (nonatomic) CGFloat nonTrackingPanelHeight;

@end

@implementation TTPanelController

@synthesize backgroundView = _backgroundView;
@synthesize delegate = _delegate;
@synthesize searchField = _searchField;
@synthesize textField = _textField;
@synthesize workTypes = _workTypes;
@synthesize workButtons = _workButtons;
@synthesize panelHeight = _panelHeight;
@synthesize isCounting = _isCounting;
@synthesize startTime = _startTime;
@synthesize currentWorkType = _currentWorkType;
@synthesize stopButton = _stopButton;
@synthesize trackingPanelHeight = _trackingPanelHeight;
@synthesize nonTrackingPanelHeight = _nonTrackingPanelHeight;

#pragma mark -

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate
{
    NSLog(@"initWithDelegate called");
    self = [super initWithWindowNibName:@"Panel"];
    if (self != nil)
    {
        _delegate = delegate;

        _isCounting = NO;
        
        _workTypes = [NSArray arrayWithObjects:
                      [NSString stringWithFormat:@"UROP"],
                      [NSString stringWithFormat:@"6.01 SLA"],
                      [NSString stringWithFormat:@"The Tech"],
                      nil];
        
        _workButtons = [[NSMutableArray alloc] init];

        NSPanel *panel = (id)[self window];
        [panel setAcceptsMouseMovedEvents:YES];
        [panel setLevel:NSPopUpMenuWindowLevel];
        [panel setOpaque:NO];
        [panel setBackgroundColor:[NSColor clearColor]];
        
        CGFloat padding = 10.0f;
        CGFloat buttonHeight = 20.0f;
        CGFloat panelWidth = panel.frame.size.width;
        CGFloat bottom = padding;
        
        CGRect frame = CGRectMake(padding,
                                  bottom,
                                  panelWidth - 2 * padding,
                                  buttonHeight);
        
        _stopButton = [[NSButton alloc] initWithFrame:frame];
        _stopButton.title = @"Stop";
        _stopButton.bezelStyle = NSRoundedBezelStyle;
        
        _stopButton.hidden = YES;
        _stopButton.target = self;
        _stopButton.action = @selector(stopButtonClicked:);
        
        _trackingPanelHeight = bottom + padding + buttonHeight;
        
        [_backgroundView addSubview:_stopButton];
        
        for (id str in _workTypes) {
            CGRect frame = CGRectMake(padding,
                                      bottom,
                                      panelWidth - 2 * padding,
                                      buttonHeight);
            
            bottom += (padding + buttonHeight);
            
            NSButton *button = [[NSButton alloc] initWithFrame:frame];
            
            button.target = self;
            button.action = @selector(workButtonClicked:);
            
            button.bezelStyle = NSRoundedBezelStyle;
            button.title = str;
            
            [_workButtons addObject:button];
            
            [_backgroundView addSubview:button];
        }
        
        CGFloat reportButtonTopPadding = 20.0f;
        
        _reportButton = [[NSButton alloc] initWithFrame:CGRectMake(padding, bottom + reportButtonTopPadding, panelWidth - 2 * padding, buttonHeight)];
        _reportButton.bezelStyle = NSRoundedBezelStyle;
        _reportButton.title = @"View Hours";
        _reportButton.target = self;
        _reportButton.action = @selector(viewHoursClicked:);
        [_backgroundView addSubview:_reportButton];
        
        bottom += (reportButtonTopPadding + padding + buttonHeight);
        
        _nonTrackingPanelHeight = bottom;
        _panelHeight = _nonTrackingPanelHeight;
        
        NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(updateStatusText:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes]; 
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidChangeNotification object:self.searchField];
}

#pragma mark View hours logic

- (IBAction) viewHoursClicked:(id)sender {
    if (!_reportWindowController) {
        _reportWindowController = [[TTReportWindowController alloc] initWithWindowNibName:@"ReportWindowController"];
    }
    
    [_reportWindowController showWindow:self];
    [_reportWindowController refresh];
    [_reportWindowController.window orderFrontRegardless];
    
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [_reportWindowController.window makeKeyAndOrderFront:self];
}

#pragma mark Counting logic

- (IBAction) workButtonClicked:(id)sender  {
    NSLog(@"%@", [sender title]);
    
    self.startTime = [NSDate date];
    self.currentWorkType = [sender title];
    
    for (NSButton *button in self.workButtons) {
        button.hidden = YES;
    }
    
    self.stopButton.hidden = NO;
    
    self.isCounting = YES;
    self.panelHeight = self.trackingPanelHeight;
    
    [self.delegate setStatusItemText:[NSString stringWithFormat:@"%@ 0:00", self.currentWorkType]];
    [self.delegate togglePanel:sender];
}

- (IBAction)stopButtonClicked:(id)sender {
    NSDate *endTime = [NSDate date];
    NSTimeInterval interval = [endTime timeIntervalSinceDate:self.startTime];
    
    for (NSButton *button in self.workButtons) {
        button.hidden = NO;
    }
    
    self.stopButton.hidden = YES;
    
    self.isCounting = NO;
    self.panelHeight = self.nonTrackingPanelHeight;
    
    TTApplicationDelegate *appDelegate = (TTApplicationDelegate *)[NSApplication sharedApplication].delegate;
    CalCalendarStore *store = [CalCalendarStore defaultCalendarStore];
    CalCalendar *timesheet = [appDelegate timesheetCalendar];
    CalEvent *event = [CalEvent event];
    
    if (timesheet) {
        event.startDate = self.startTime;
        event.endDate = endTime;
        event.calendar = timesheet;
        event.title = [NSString stringWithFormat:@"Timesheet: %@", self.currentWorkType];
    
        NSError *error;
    
        [store saveEvent:event span:CalSpanThisEvent error:&error];
    
        if (error) {
            NSAlert *alert = [[NSAlert alloc] init];
            
            [alert addButtonWithTitle:@"OK"];
            [alert setMessageText:@"Error creating event. "];
            [alert setInformativeText:[error description]];
            [alert setAlertStyle:NSWarningAlertStyle];
            
            [alert runModal];
        }
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Cannot find calendar. "];
        [alert setInformativeText:@"There isn't a calendar with name \"Timesheet\". "];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        [alert runModal];
    }
    
    self.startTime = NULL;
    self.currentWorkType = NULL;
    
    [self.delegate setStatusItemText:@"Idle"];
    [self.delegate togglePanel:sender];
}

- (IBAction)updateStatusText:(id)sender {
    if (self.isCounting) {
        NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:self.startTime];
        int seconds = (int)(interval + 0.5);
        int minutes = seconds / 60;
        
        int hours = minutes / 60;
        minutes -= 60 * hours;
    
        [self.delegate setStatusItemText:[NSString stringWithFormat:@"%@ %d:%02d", self.currentWorkType, hours, minutes]];
    }
}


#pragma mark -

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Make a fully skinned panel
    NSPanel *panel = (id)[self window];
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];
    
    // Follow search string
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runSearch) name:NSControlTextDidChangeNotification object:self.searchField];
}

#pragma mark - Public accessors

- (BOOL)hasActivePanel
{
    return _hasActivePanel;
}

- (void)setHasActivePanel:(BOOL)flag
{
    if (_hasActivePanel != flag)
    {
        _hasActivePanel = flag;
        
        if (_hasActivePanel)
        {
            [self openPanel];
        }
        else
        {
            [self closePanel];
        }
    }
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
    self.hasActivePanel = NO;
}

- (void)windowDidResignKey:(NSNotification *)notification;
{
    if ([[self window] isVisible])
    {
        self.hasActivePanel = NO;
    }
}

- (void)windowDidResize:(NSNotification *)notification
{
    NSWindow *panel = [self window];
    NSRect statusRect = [self statusRectForWindow:panel];
    NSRect panelRect = [panel frame];
    
    CGFloat statusX = roundf(NSMidX(statusRect));
    CGFloat panelX = statusX - NSMinX(panelRect);
    
    self.backgroundView.arrowX = panelX;
    
    NSRect searchRect = [self.searchField frame];
    searchRect.size.width = NSWidth([self.backgroundView bounds]) - SEARCH_INSET * 2;
    searchRect.origin.x = SEARCH_INSET;
    searchRect.origin.y = NSHeight([self.backgroundView bounds]) - ARROW_HEIGHT - SEARCH_INSET - NSHeight(searchRect);
    
    if (NSIsEmptyRect(searchRect))
    {
        [self.searchField setHidden:YES];
    }
    else
    {
        [self.searchField setFrame:searchRect];
        [self.searchField setHidden:NO];
    }
    
    NSRect textRect = [self.textField frame];
    textRect.size.width = NSWidth([self.backgroundView bounds]) - SEARCH_INSET * 2;
    textRect.origin.x = SEARCH_INSET;
    textRect.size.height = NSHeight([self.backgroundView bounds]) - ARROW_HEIGHT - SEARCH_INSET * 3 - NSHeight(searchRect);
    textRect.origin.y = SEARCH_INSET;
    
    if (NSIsEmptyRect(textRect))
    {
        [self.textField setHidden:YES];
    }
    else
    {
        [self.textField setFrame:textRect];
        [self.textField setHidden:NO];
    }
}

#pragma mark - Keyboard

- (void)cancelOperation:(id)sender
{
    self.hasActivePanel = NO;
}

- (void)runSearch
{
    NSString *searchFormat = @"";
    NSString *searchString = [self.searchField stringValue];
    if ([searchString length] > 0)
    {
        searchFormat = NSLocalizedString(@"Search for ‘%@’…", @"Format for search request");
    }
    NSString *searchRequest = [NSString stringWithFormat:searchFormat, searchString];
    [self.textField setStringValue:searchRequest];
}

#pragma mark - Public methods

- (NSRect)statusRectForWindow:(NSWindow *)window
{
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = NSZeroRect;
    
    TTStatusItemView *statusItemView = nil;
    if ([self.delegate respondsToSelector:@selector(statusItemViewForPanelController:)])
    {
        statusItemView = [self.delegate statusItemViewForPanelController:self];
    }
    
    if (statusItemView)
    {
        statusRect = statusItemView.globalRect;
        statusRect.origin.y = NSMinY(statusRect) - NSHeight(statusRect);
    }
    else
    {
        statusRect.size = NSMakeSize(STATUS_ITEM_VIEW_WIDTH, [[NSStatusBar systemStatusBar] thickness]);
        statusRect.origin.x = roundf((NSWidth(screenRect) - NSWidth(statusRect)) / 2);
        statusRect.origin.y = NSHeight(screenRect) - NSHeight(statusRect) * 2;
    }
    return statusRect;
}

- (void)openPanel
{
    NSLog(@"openPanel called");
    NSWindow *panel = [self window];
    
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = [self statusRectForWindow:panel];

    NSRect panelRect = [panel frame];
    panelRect.size.width = PANEL_WIDTH;
    panelRect.size.height = self.panelHeight + 2 * CORNER_RADIUS;
    panelRect.origin.x = roundf(NSMidX(statusRect) - NSWidth(panelRect) / 2);
    panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect);
    
    if (NSMaxX(panelRect) > (NSMaxX(screenRect) - ARROW_HEIGHT))
        panelRect.origin.x -= NSMaxX(panelRect) - (NSMaxX(screenRect) - ARROW_HEIGHT);
    
    [NSApp activateIgnoringOtherApps:NO];
    [panel setAlphaValue:0];
    [panel setFrame:statusRect display:YES];
    [panel makeKeyAndOrderFront:nil];
    
    NSTimeInterval openDuration = OPEN_DURATION;
    
    NSEvent *currentEvent = [NSApp currentEvent];
    if ([currentEvent type] == NSLeftMouseDown)
    {
        NSUInteger clearFlags = ([currentEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);
        BOOL shiftPressed = (clearFlags == NSShiftKeyMask);
        BOOL shiftOptionPressed = (clearFlags == (NSShiftKeyMask | NSAlternateKeyMask));
        if (shiftPressed || shiftOptionPressed)
        {
            openDuration *= 10;
            
            if (shiftOptionPressed)
                NSLog(@"Icon is at %@\n\tMenu is on screen %@\n\tWill be animated to %@",
                      NSStringFromRect(statusRect), NSStringFromRect(screenRect), NSStringFromRect(panelRect));
        }
    }
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:openDuration];
    [[panel animator] setFrame:panelRect display:YES];
    [[panel animator] setAlphaValue:1];
    [NSAnimationContext endGrouping];
    
    [panel performSelector:@selector(makeFirstResponder:) withObject:self.searchField afterDelay:openDuration];
}

- (void)closePanel
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:CLOSE_DURATION];
    [[[self window] animator] setAlphaValue:0];
    [NSAnimationContext endGrouping];
    
    dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * CLOSE_DURATION * 2), dispatch_get_main_queue(), ^{
        
        [self.window orderOut:nil];
    });
}

@end
