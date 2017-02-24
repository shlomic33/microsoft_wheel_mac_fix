#include <IOKit/IOKitLib.h>
#include <IOKit/hid/IOHIDLib.h>

#define VENDOR_ID                       0x45e   // microsoft
#define PRODUCT_ID                      0x7a5   // sculpt ergonomic mouse
#define ScrollWheelResolutionReportId   0x12    // this is the problematic feature id.

static
CFMutableDictionaryRef create_matching_dict(UInt32 vendorID, UInt32 productID)
{
    CFMutableDictionaryRef result = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                                              &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    if (result)
    {
        CFNumberRef vendorIDRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &vendorID);
        if (vendorIDRef)
        {
            CFDictionarySetValue(result, CFSTR(kIOHIDVendorIDKey), vendorIDRef);
            CFRelease(vendorIDRef);
            CFNumberRef productIDRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &productID);
            if (productIDRef)
            {
                CFDictionarySetValue(result, CFSTR(kIOHIDProductIDKey), productIDRef);
                CFRelease(productIDRef);
            }
            else
            {
                fprintf(stderr, "failed to create a productIDRef object");
            }
            
        }
        else
        {
            fprintf(stderr, "failed to create a vendorIDRef object");
        }
        
    }
    else
    {
        fprintf(stderr, "failed to create a CFMutableDictionaryRef object");
        
    }
    return result;
}


static
void handle_matching_device(void * inContext, IOReturn inResult, void * inSender, IOHIDDeviceRef inIOHIDDeviceRef)
{
    IOReturn result;
    printf("hid device matched!\n");
    result = IOHIDDeviceOpen(inIOHIDDeviceRef, kIOHIDOptionsTypeNone);
    assert(result == kIOReturnSuccess);
    
    uint8_t report[2];
    // Feature Report ID - these is the feature of mouse scroll wheel resolution.
    report[0] = ScrollWheelResolutionReportId;
    // Set the feature to the lowest avaible resolution - like regular mice.
    report[1] = 0x00;
    result = IOHIDDeviceSetReport(inIOHIDDeviceRef, kIOHIDReportTypeFeature, ScrollWheelResolutionReportId, report, sizeof(report));
    if (result == kIOReturnSuccess)
    {
        printf("fix applied successfully!\n");
    }
    else
    {
        printf("error while sending feature report\n");
    }
    IOHIDDeviceClose(inIOHIDDeviceRef, kIOHIDOptionsTypeNone);
    CFRunLoopStop(CFRunLoopGetCurrent());
    
}

int main(int argc, const char * argv[])
{
    IOHIDManagerRef hid_manager = IOHIDManagerCreate(NULL, 0);
    assert(CFGetTypeID(hid_manager) == IOHIDManagerGetTypeID());
    CFDictionaryRef matching_dict = create_matching_dict(VENDOR_ID, PRODUCT_ID);
    IOHIDManagerSetDeviceMatching(hid_manager, matching_dict);
    IOHIDManagerRegisterDeviceMatchingCallback(hid_manager, handle_matching_device, NULL);
    IOHIDManagerScheduleWithRunLoop(hid_manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    IOReturn result = IOHIDManagerOpen(hid_manager, kIOHIDOptionsTypeNone);
    assert(result == kIOReturnSuccess);
    CFRunLoopRun();
    return result;
}
