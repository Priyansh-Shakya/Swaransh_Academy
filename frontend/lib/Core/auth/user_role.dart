/// App-level roles. Resolved server-side after Supabase auth completes —
/// never set by the client directly.
///
/// `currentRoleProvider` and `isSignedInProvider` live in auth_notifier.dart.
/// Import from there for watching role across the app.
enum UserRole { guest, student, admin }
