const Map<String, String> enStrings = {
  // App
  'app_name': 'TwinChat',
  'tagline': 'Communication without borders',

  // Auth
  'login': 'Log in',
  'register': 'Sign up',
  'logout': 'Log out',
  'phone': 'Phone',
  'code': 'Code',
  'password': 'Password',
  'username': 'Username',
  'email': 'Email',
  'enter_phone': 'Sign in with SMS',
  'enter_code': 'Enter code',
  'get_code': 'Get code',
  'resend_code': 'Resend code',
  'login_with_password': 'Log in with username and password',
  'login_with_phone': 'Log in with SMS',
  'phone_hint': '+998 90 123 45 67',
  'code_sent_to': 'Code sent to',
  'paste_from_clipboard': 'Paste from clipboard',
  'code_resent': 'Code resent',
  'invalid_phone': 'Enter a valid phone number',
  'code_too_short': 'Code is too short',
  'login_or_password_empty': 'Enter username and password',
  'username_too_short': 'Username must be at least 3 characters',
  'password_too_short': 'Password must be at least 6 characters',
  'registration': 'Registration',
  'registration_hint': 'Create a TwinChat account',
  'already_have_account': 'Already have an account?',
  'dont_have_account': "Don't have an account?",

  // Navigation
  'chats': 'Chats',
  'contacts': 'Contacts',
  'stories': 'Stories',
  'settings': 'Settings',
  'profile': 'Profile',
  'my_profile': 'My Profile',
  'safe_mode': 'Safe Mode',
  'saved_messages': 'Saved Messages',

  // Chat
  'no_chats': 'No chats',
  'no_chats_hint': 'Tap "New chat"\nto start messaging',
  'new_chat': 'New chat',
  'personal_chat': 'Personal chat',
  'group_chat': 'Group chat',
  'message_hint': 'Message...',
  'no_messages': 'No messages',
  'write_first': 'Write first!',
  'typing': 'typing...',
  'deleted': 'Deleted',
  'edited': 'edited',
  'voice_message': 'Voice message',
  'uploading': 'Uploading...',
  'chat_not_found': 'Route not found',

  // Message actions
  'edit_message': 'Edit',
  'add_reaction': 'Add reaction',
  'delete_message': 'Delete',
  'save': 'Save',
  'cancel': 'Cancel',
  'close': 'Close',
  'confirm': 'Confirm',

  // Contacts
  'no_contacts': 'No contacts yet',
  'add_contact': 'Add contact',
  'search_by_username': 'Search by username',
  'nickname_optional': 'Nickname (optional)',
  'sync_contacts': 'Sync contacts',
  'contacts_synced': 'Contacts synced',
  'allow_contact_access': 'Contact access',
  'allow_contact_access_hint': 'Allow contact access for sync',
  'open_chat': 'Message',

  // Stories
  'no_stories': 'No stories yet',
  'create_first_story': 'Create your first story',
  'views': 'views',
  'add_story': 'Add',

  // Settings
  'theme': 'Theme',
  'light_theme': 'Light',
  'dark_theme': 'Dark',
  'system_theme': 'System',
  'text_size': 'Text size',
  'notifications': 'Notifications',
  'privacy': 'Privacy',
  'language': 'Language',
  'auto_translate': 'Auto-translate incoming',
  'auto_delete_messages': 'Auto-delete messages',
  'two_factor_auth': 'Two-factor authentication',
  'see_phone_number': 'Who can see phone number',
  'see_profile_photo': 'Who can see profile photo',
  'see_last_seen': 'Who can see last seen',
  'storage_days': 'Storage period (days)',
  'everyone': 'Everyone',
  'nobody': 'Nobody',
  'contacts_only': 'Contacts',

  // Profile
  'edit_profile': 'Edit profile',
  'avatar_updated': 'Avatar updated',
  'profile_updated': 'Updating profile...',
  'not_specified': 'Not specified',
  'was_online': 'Last seen',

  // Safe Mode
  'safe_mode_enabled': 'Enabled',
  'safe_mode_disabled': 'Disabled',
  'enable_safe_mode': 'Enable Safe Mode',
  'disable_safe_mode': 'Disable Safe Mode',
  'key_fingerprint': 'Key fingerprint',
  'enter_key_to_unlock': 'Enter key to unlock',
  'auto_lock_minutes': 'Auto-lock (minutes)',
  'key_share_log': 'Key share log',
  'no_shares_yet': 'No keys shared yet',
  'key_revoked': 'Revoked',

  // Errors
  'error_loading': 'Loading error',
  'no_connection': 'No internet connection',
  'server_error': 'Server error',
  'session_expired': 'Session expired, please log in again',
  'access_denied': 'Access denied',
  'not_found': 'Not found',
  'unknown_error': 'Unknown error',

  // Misc
  'retry': 'Retry',
  'loading': 'Loading...',
  'online': 'Online',
  'offline': 'Offline',
  'yes': 'Yes',
  'no': 'No',

  // Login
  'welcome': 'Welcome',
  'login_hint': 'Sign in to your TwinChat account',
  'enter_username': 'Enter username',
  'enter_password': 'Enter password',
  'or': 'or',
  'sms_login': 'Sign in with SMS code',
  'no_account': "Don't have an account?",
  'register_button': 'Sign up',

  // Register
  'create_account': 'Create account',
  'register_hint': 'Fill in your details to register on TwinChat',
  'min_3_chars': 'At least 3 characters',
  'enter_email': 'Enter email',
  'invalid_email': 'Invalid email',
  'invalid_number': 'Enter a valid number',
  'min_6_chars': 'At least 6 characters',
  'repeat_password': 'Repeat password',
  'passwords_no_match': 'Passwords do not match',
  'has_account': 'Already have an account?',

  // Code resend
  'code_resent_to': 'Code resent to',

  // Contacts sync
  'contacts_synced_count': 'Contacts synced',
  'sync_error': 'Sync error',

  // Chat dialogs
  'private': 'Private',
  'group': 'Group',
  'group_name': 'Group name',
  'group_name_hint': 'My group',
  'empty_group_name': 'Group name cannot be empty',
  'create': 'Create',
  'chat_limit_note': 'The server currently supports creating a chat with one member. Adding members will be available in the next version.',
  'group_name_title': 'Group settings',
  'no_name': 'No name',
  'title': 'Title',
  'members': 'Members',

  // Stories
  'no_stories_hint': 'No stories yet',
  'views_count': 'views',
  'story_number': 'Story',
  'add_photo': 'Add photo',
  'photo': 'Photo',
  'video': 'Video',
  'attach_file': 'Attach file',

  // Error on chat open
  'error_opening_chat': 'Error opening chat',
  'call': 'Call',
  'select_chat_for_call': 'Select a chat to call',
};
