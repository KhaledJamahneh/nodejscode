# Error Handling Guide for Flutter Integration

## Backend Error Response Format

All API errors now return proper HTTP status codes with consistent JSON format:

```json
{
  "success": false,
  "message": "Human-readable error message"
}
```

## HTTP Status Codes

| Status | Type | Example Messages |
|--------|------|------------------|
| **400** | Validation Error | "Insufficient inventory. You have 39 gallons but reported 50 delivered." |
| **400** | Validation Error | "Insufficient coupons. Client has 2 but this delivery requires 3." |
| **400** | Validation Error | "Delivery is already completed" |
| **400** | Validation Error | "Delivered amount (50) significantly exceeds request (20). Max 10% over-delivery allowed." |
| **400** | Validation Error | "gallons_delivered must be a positive number" |
| **403** | Authorization Error | "Client account is inactive" |
| **403** | Authorization Error | "Workers cannot deliver to themselves" |
| **404** | Not Found | "Delivery not found or not assigned to you" |
| **404** | Not Found | "Worker profile not found" |
| **500** | Server Error | "Failed to complete delivery" (unexpected errors) |

## Flutter Error Handling

### Before (DioException)

```dart
try {
  await dio.post('/api/v1/workers/deliveries/$id/complete', data: {...});
} catch (e) {
  // User sees: "DioException [bad response]: null"
  showDialog(context, 'Error', e.toString()); // ❌ Not user-friendly
}
```

### After (User-Friendly Notifications)

```dart
try {
  final response = await dio.post(
    '/api/v1/workers/deliveries/$id/complete',
    data: {...},
  );
  
  // Success
  showSuccessNotification('Delivery completed successfully');
  
} on DioException catch (e) {
  final statusCode = e.response?.statusCode;
  final message = e.response?.data['message'] ?? 'An error occurred';
  
  switch (statusCode) {
    case 400:
      // Validation error - show as warning
      showWarningNotification(message);
      break;
      
    case 403:
      // Authorization error - show as error
      showErrorNotification(message);
      break;
      
    case 404:
      // Not found - show as info
      showInfoNotification(message);
      break;
      
    case 500:
    default:
      // Server error - show generic message
      showErrorNotification('Something went wrong. Please try again.');
      break;
  }
}
```

## Example Notification Widgets

### Success Notification (Green)
```dart
void showSuccessNotification(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 3),
    ),
  );
}
```

### Warning Notification (Orange)
```dart
void showWarningNotification(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.warning, color: Colors.white),
          SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.orange,
      duration: Duration(seconds: 5),
    ),
  );
}
```

### Error Notification (Red)
```dart
void showErrorNotification(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.error, color: Colors.white),
          SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 5),
    ),
  );
}
```

## Complete Example: Delivery Completion

```dart
Future<void> completeDelivery(String deliveryId, DeliveryData data) async {
  try {
    final response = await dio.post(
      '/api/v1/workers/deliveries/$deliveryId/complete',
      data: {
        'gallons_delivered': data.gallonsDelivered,
        'empty_gallons_returned': data.emptyGallonsReturned,
        'delivery_latitude': data.latitude,
        'delivery_longitude': data.longitude,
        'paid_amount': data.paidAmount,
        'total_price': data.totalPrice,
      },
    );
    
    // Success
    showSuccessNotification('Delivery completed successfully');
    Navigator.pop(context); // Go back to delivery list
    
  } on DioException catch (e) {
    final statusCode = e.response?.statusCode;
    final message = e.response?.data['message'] ?? 'An error occurred';
    
    if (statusCode == 400) {
      // Validation error - user can fix it
      showWarningNotification(message);
      
      // Special handling for insufficient inventory
      if (message.contains('Insufficient inventory')) {
        // Show dialog to adjust gallons delivered
        showAdjustGallonsDialog(context, message);
      }
      
    } else if (statusCode == 403) {
      // Authorization error - cannot proceed
      showErrorNotification(message);
      Navigator.pop(context); // Go back
      
    } else if (statusCode == 404) {
      // Not found - delivery may have been deleted
      showInfoNotification(message);
      Navigator.pop(context); // Go back
      
    } else {
      // Server error - retry later
      showErrorNotification('Something went wrong. Please try again later.');
    }
  }
}
```

## Benefits

✅ **User-Friendly** - Clear, actionable error messages
✅ **Proper Status Codes** - 400 for validation, 403 for auth, 404 for not found
✅ **No DioException** - Users see meaningful notifications
✅ **Actionable** - Users know what to fix (e.g., reduce gallons delivered)
✅ **Professional** - Consistent error handling across the app

## Testing

Test each error scenario:

```bash
# Test insufficient inventory (should return 400)
curl -X POST http://localhost:3000/api/v1/workers/deliveries/123/complete \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"gallons_delivered": 100}' # More than worker has

# Test already completed (should return 400)
curl -X POST http://localhost:3000/api/v1/workers/deliveries/123/complete \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"gallons_delivered": 20}' # Complete twice

# Test not found (should return 404)
curl -X POST http://localhost:3000/api/v1/workers/deliveries/99999/complete \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"gallons_delivered": 20}'
```
