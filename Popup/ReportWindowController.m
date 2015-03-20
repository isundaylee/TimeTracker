//
//  ReportWindowController.m
//  Popup
//
//  Created by Jiahao Li on 3/13/15.
//
//

#import "ReportWindowController.h"
#import "ApplicationDelegate.h"
#import "CalendarStore/CalendarStore.h"
#import "EventKit/EventKit.h"

const NSInteger SEGMENT_PREV = 0;
const NSInteger SEGMENT_DISPLAY = 1;
const NSInteger SEGMENT_NEXT = 2; 

@interface ReportWindowController () {
    NSArray *_rows;
    NSInteger _offset;
}

@end

@implementation ReportWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    _offset = 0;
    
    [self refresh];
}

- (void)refresh {
    NSArray *weekdays = [self collectWeekDaysWithOffset:_offset];
    
    NSDate *firstDay = [weekdays objectAtIndex:0];
    NSDate *lastDay = [weekdays objectAtIndex:[weekdays count] - 1];
    
    NSString *firstDayString = [NSDateFormatter localizedStringFromDate:firstDay dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
    NSString *lastDayString = [NSDateFormatter localizedStringFromDate:lastDay dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
    
    [self.weekSelector setLabel:[NSString stringWithFormat:@"%@ - %@", firstDayString, lastDayString] forSegment:1];
    
    _rows = [self tableValuesFromDays:weekdays hours:[self collectHoursFromWeekWithOffset:_offset]];
    
    [self.tableView reloadData];
}

#pragma mark Week selector logic

- (IBAction)weekSelectorClicked:(id)sender {
    NSSegmentedControl *control = (NSSegmentedControl *) sender;
    NSInteger button = [control selectedSegment];
    [control selectSegmentWithTag:SEGMENT_DISPLAY];
    
    if (button == SEGMENT_PREV) {
        _offset -= 1;
        [self refresh];
    } else if (button == SEGMENT_NEXT) {
        _offset += 1;
        [self refresh]; 
    }
}

#pragma mark Counting logic

- (NSDate *) getCurrentWeekday:(NSInteger)weekday {
    NSDate *today = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [calendar components:NSYearCalendarUnit |  NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit fromDate:today];
    
    NSInteger currentWeekday = ([comp weekday] + 6) % 7;
    
    NSDateComponents *componentsToSubtract = [[NSDateComponents alloc] init];
    [componentsToSubtract setDay: weekday - currentWeekday];
    
    NSDate *day = [calendar dateByAddingComponents:componentsToSubtract toDate:today options:0];
    NSDateComponents *dayComp = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit fromDate:day];
    
    return [calendar dateFromComponents:dayComp];
}

- (NSArray *) collectHoursFromDays:(NSArray *)days {
    NSMutableArray *results = [NSMutableArray array];
    ApplicationDelegate *appDelegate = (ApplicationDelegate *)[NSApplication sharedApplication].delegate;
    CalCalendarStore *store = [CalCalendarStore defaultCalendarStore];
    CalCalendar *timesheet = [appDelegate timesheetCalendar];
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *oneDay = [[NSDateComponents alloc] init];
    oneDay.day = 1;
    
    if (timesheet) {
        for (NSDate *day in days) {
            NSDate *start = day;
            NSDate *end = [gregorian dateByAddingComponents:oneDay toDate:start options:0];
            
            NSPredicate *predicate = [CalCalendarStore eventPredicateWithStartDate:start endDate:end calendars:@[timesheet]];
            NSArray *events = [store eventsWithPredicate:predicate];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            
            for (CalEvent *e in events) {
                NSTimeInterval first = MAX([e.startDate timeIntervalSince1970], [start timeIntervalSince1970]);
                NSTimeInterval last = MIN([e.endDate timeIntervalSince1970], [end timeIntervalSince1970]);
                NSTimeInterval duration = last - first;
                
                NSInteger minutes = ceil(duration / 60.0);
                
                NSNumber *value = [dict valueForKey:e.title];
                
                if (value) {
                    [dict setValue:[NSNumber numberWithLong:value.intValue + minutes] forKey:e.title];
                } else {
                    [dict setValue:[NSNumber numberWithLong:minutes] forKey:e.title];
                }
            }
            
            [results addObject:dict];
        }
    
        return results;
    } else {
        return nil;
    }
}

- (NSArray *) collectWeekDaysWithOffset:(NSInteger) offset {
    NSMutableArray *days = [NSMutableArray array];
    
    for (int i=1; i<=7; i++) {
        NSDate *currentWeekday = [self getCurrentWeekday:i];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *offsetComp = [[NSDateComponents alloc] init];
        offsetComp.day = offset * 7;
        
        [days addObject:[calendar dateByAddingComponents:offsetComp toDate:currentWeekday options:0]];
    }
    
    return days;
}

- (NSArray *) collectHoursFromWeekWithOffset:(NSInteger) offset {
    return [self collectHoursFromDays:[self collectWeekDaysWithOffset:offset]];
}

- (NSArray *) tableValuesFromDays:(NSArray *)days hours:(NSArray *)hours {
    NSMutableArray *rows = [NSMutableArray array];
    NSInteger grandTotal = 0;
    
    NSAssert([days count] == [hours count], @"Days and hours must have the same length. ");
    
    for (int i=0; i<[days count]; i++) {
        NSDate *day = [days objectAtIndex:i];
        NSDictionary *hoursheet = [hours objectAtIndex:i];
        NSString *dateString = [NSDateFormatter localizedStringFromDate:day dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
        
        NSInteger total = 0;
        
        for (NSString *key in [hoursheet allKeys]) {
            NSInteger minutes = [[hoursheet valueForKey:key] longValue];
            NSInteger hours = minutes / 60;
            
            minutes -= (hours * 60);
            total += (60 * hours + minutes);
            grandTotal += (60 * hours + minutes);

            [rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                             dateString,
                             @"date",
                             [NSString stringWithFormat:@"%ld:%02ld", hours, minutes],
                             @"hours",
                             key,
                             @"role", nil]];
            
            dateString = @"";
        }
        
        [rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                         dateString,
                         @"date",
                         [NSString stringWithFormat:@"%ld:%02ld", total / 60, total % 60],
                         @"hours",
                         @"    Total",
                         @"role", nil]];
    }
    
    [rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                     @"",
                     @"date",
                     [NSString stringWithFormat:@"%ld:%02ld", grandTotal / 60, grandTotal % 60],
                     @"hours",
                     @"Grand Total",
                     @"role", nil]];
    
    return rows;
}

#pragma mark NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _rows.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [[_rows objectAtIndex:row] valueForKey:tableColumn.identifier];
}

#pragma mark NSTableViewDelegate methods

@end
