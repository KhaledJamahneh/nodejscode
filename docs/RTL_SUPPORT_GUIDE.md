# RTL (Right-to-Left) Support Guide

## Backend Implementation

The backend now provides language metadata with every notification to support proper RTL rendering.

### Notification Payload Structure

```json
{
  "title": "تم توصيل المياه",
  "body": "تم توصيل 5 جالونات إلى موقعك.",
  "lang": "ar",
  "dir": "rtl",
  "locale": "ar-SA"
}
```

### Language Metadata

| Language | `dir` | `locale` |
|----------|-------|----------|
| English  | `ltr` | `en-US`  |
| Arabic   | `rtl` | `ar-SA`  |

## Frontend Integration Requirements

### 1. Dynamic Layout Direction

The frontend **must** apply the `dir` attribute based on the notification language:

```javascript
// React/Flutter example
<div dir={notification.dir}>
  <h1>{notification.title}</h1>
  <p>{notification.body}</p>
</div>
```

```dart
// Flutter example
Directionality(
  textDirection: notification.dir == 'rtl' 
    ? TextDirection.rtl 
    : TextDirection.ltr,
  child: Text(notification.body),
)
```

### 2. CSS RTL Support

Ensure CSS handles RTL properly:

```css
/* Use logical properties instead of left/right */
.notification {
  margin-inline-start: 16px;  /* NOT margin-left */
  padding-inline-end: 8px;    /* NOT padding-right */
}

/* Or use dir attribute selector */
[dir="rtl"] .notification {
  text-align: right;
}
```

### 3. User Preference Storage

Store user's language preference:

```sql
-- Add to users table
ALTER TABLE users ADD COLUMN preferred_language VARCHAR(5) DEFAULT 'en';
```

```javascript
// Backend: Get user's language preference
const getUserLanguage = async (userId) => {
  const result = await query(
    'SELECT preferred_language FROM users WHERE id = $1',
    [userId]
  );
  return result.rows[0]?.preferred_language || 'en';
};
```

### 4. API Response Headers

Include language metadata in API responses:

```javascript
// Backend middleware
res.setHeader('Content-Language', user.preferred_language);
res.setHeader('Content-Direction', getLanguageMetadata(user.preferred_language).dir);
```

### 5. Notification Display

Frontend should respect the `dir` attribute:

```javascript
// React Native / Flutter
const NotificationCard = ({ notification }) => {
  return (
    <View style={{ 
      flexDirection: notification.dir === 'rtl' ? 'row-reverse' : 'row' 
    }}>
      <Text style={{ 
        textAlign: notification.dir === 'rtl' ? 'right' : 'left' 
      }}>
        {notification.body}
      </Text>
    </View>
  );
};
```

## Common RTL Issues to Avoid

### ❌ Wrong: Hardcoded Direction
```javascript
<div style={{ textAlign: 'left' }}>
  {notification.body}
</div>
```

### ✅ Correct: Dynamic Direction
```javascript
<div style={{ textAlign: notification.dir === 'rtl' ? 'right' : 'left' }}>
  {notification.body}
</div>
```

### ❌ Wrong: Ignoring Punctuation
```
English: "5 gallons delivered."
Arabic: "تم توصيل 5 جالونات." // Period appears on wrong side without RTL
```

### ✅ Correct: Proper RTL Container
```html
<div dir="rtl">تم توصيل 5 جالونات.</div>
<!-- Period now appears correctly on the left side -->
```

## Testing RTL Support

### Manual Testing
1. Switch user language to Arabic
2. Trigger notification
3. Verify:
   - Text flows right-to-left
   - Punctuation appears on correct side
   - Icons/buttons are mirrored appropriately
   - Numbers display correctly (Arabic numerals vs. Eastern Arabic numerals)

### Automated Testing
```javascript
describe('RTL Notifications', () => {
  it('should include dir metadata for Arabic', () => {
    const notification = createNotification('ar', 'water_delivered_body', 5);
    expect(notification.dir).toBe('rtl');
    expect(notification.locale).toBe('ar-SA');
  });

  it('should include dir metadata for English', () => {
    const notification = createNotification('en', 'water_delivered_body', 5);
    expect(notification.dir).toBe('ltr');
    expect(notification.locale).toBe('en-US');
  });
});
```

## Backend API Usage

### Get Language Metadata
```javascript
const { getLanguageMetadata } = require('./utils/i18n');

const metadata = getLanguageMetadata('ar');
// { dir: 'rtl', locale: 'ar-SA' }
```

### Send Notification with RTL Support
```javascript
const { t, getLanguageMetadata } = require('./utils/i18n');

const userLang = await getUserLanguage(userId);
const metadata = getLanguageMetadata(userLang);

await sendNotification(userId, {
  title: t(userLang, 'water_delivered_title'),
  body: t(userLang, 'water_delivered_body', 5, 'gallon'),
  lang: userLang,
  dir: metadata.dir,
  locale: metadata.locale
});
```

## Browser/Platform Support

- **Web**: All modern browsers support `dir="rtl"` attribute
- **React Native**: Use `I18nManager.forceRTL()` or `Directionality` widget
- **Flutter**: Use `Directionality` widget with `TextDirection.rtl`
- **iOS**: Set `semanticContentAttribute` to `.forceRightToLeft`
- **Android**: Set `android:layoutDirection="rtl"` in manifest

## Resources

- [MDN: dir attribute](https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/dir)
- [W3C: Structural markup and right-to-left text](https://www.w3.org/International/questions/qa-html-dir)
- [Flutter: Internationalization](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [React Native: RTL Layout](https://reactnative.dev/blog/2016/08/19/right-to-left-support-for-react-native-apps)

## Summary

✅ Backend provides `dir` and `locale` metadata  
✅ Frontend must apply `dir` attribute dynamically  
✅ Use logical CSS properties (inline-start/end)  
✅ Test with actual Arabic content  
✅ Store user language preference  
