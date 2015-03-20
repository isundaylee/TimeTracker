#import "TTMenubarController.h"
#import "TTPanelController.h"
#import "CalendarStore/CalendarStore.h"

@interface TTApplicationDelegate : NSObject <NSApplicationDelegate, PanelControllerDelegate>

@property (nonatomic, strong) TTMenubarController *menubarController;
@property (nonatomic, strong, readonly) TTPanelController *panelController;

- (IBAction)togglePanel:(id)sender;

- (CalCalendar *)timesheetCalendar; 

@end
