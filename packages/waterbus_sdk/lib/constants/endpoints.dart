class Endpoints {
  // Auth
  static const String auth = 'v1/auth';
  static const String presignedUrlS3 = 'v1/auth/presigned-url';

  // Users
  static const String users = 'v1/users';
  static const String username = 'v1/users/username';
  static const String searchUsers = 'v1/users/search';

  // Room
  static const String rooms = 'v1/meetings';
  static const String join = 'join';
  static const String members = 'members';
  static const String inactive = 'v1/meetings/conversations/inactive'; // Mapped to meetings/conversations/:status
  static const String deactivate = 'deactivate';

  // Chats
  static const String chats = 'v1/chats';
  static const String conversations = 'v1/meetings/conversations';
}
