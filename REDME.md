- [x] add a callback when the data is updated
- [x] Create some SwiftUI hook that will auto rerender
- [ ] Add a hook for analytics events?
- [ ] Swizzle NSLocalizedString?
- [x] make sure we're checking etag (cache control)


- [x] Do remote fetch explicitly?
- [x] Figure out how to implement reactive callbacks


### Limitations
- Strings with multiple pluralization arguments are currently not supported, such as "I have %lld apples and %lld oranges.". The SDK will fall back to the translation bundled with the app.