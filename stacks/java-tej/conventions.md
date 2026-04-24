# Java 17 TEJ/RestExpress Conventions

## Overview
TEJ (Tele-Engineering Java) is your-ado-org's internal framework for building RESTful microservices using RestExpress. Java 17 LTS is the standard version.

## Naming Conventions

### Classes
- **PascalCase** (UpperCamelCase)
- Example: `UserAuthenticationService`, `OAuthProviderController`
- Suffixes indicate purpose:
  - `*Service` — Business logic
  - `*Controller` — HTTP request handlers
  - `*Repository` — Data access layer
  - `*Exception` — Custom exceptions
  - `*Request` / `*Response` — DTO objects

### Methods
- **camelCase** (lowerCamelCase)
- Verbs first: `getUser()`, `createAuthToken()`, `validateEmail()`
- Boolean methods: `isValid()`, `hasPermission()`, `canDelete()`
- Void/side-effect methods: `logEvent()`, `updateCache()`

### Constants
- **UPPER_SNAKE_CASE**
- Example: `DEFAULT_TIMEOUT_SECONDS`, `MAX_RETRY_ATTEMPTS`
- Scope: Package-private or public static final

### Packages
- **Structure**: `com.example.app.{service}.{layer}`
- Example: `com.example.app.auth.controller`, `com.example.app.auth.service`
- Layers: `controller`, `service`, `repository`, `model`, `exception`, `util`

## Error Handling

### Exception Hierarchy
Base: `ApplicationServiceException` (extends RuntimeException)

```java
public class ApplicationServiceException extends RuntimeException {
  private int errorCode;
  private String errorType;
  // ...
}
```

**Prohibited**: Raw `RuntimeException`, `Exception`, `Throwable`

### Custom Exceptions
```java
public class UserNotFoundException extends ApplicationServiceException {
  public UserNotFoundException(long userId) {
    super("User not found: " + userId);
    this.errorCode = 404;
  }
}
```

## Serialization
- **Only Gson** (never Jackson, XStream, or manual JSON)
- Reason: Consistent across Your Org ecosystem
- Example:
  ```java
  Gson gson = new Gson();
  String json = gson.toJson(userObject);
  ```

## Controller Patterns
- **Thin controllers**: 10-15 lines max
- Business logic → services only
- Request validation → service layer
- Response mapping → service layer
- Example:
  ```java
  @RestRoute(POST, "/users")
  public UserResponse createUser(Request request) {
    UserRequest req = gson.fromJson(request.getBody(), UserRequest.class);
    return userService.create(req);
  }
  ```

## Database Access
- **Only parameterized queries** (no string concatenation)
- **Try-with-resources** for all JDBC operations
- Use repositories for data access
- Example:
  ```java
  String sql = "SELECT * FROM users WHERE id = ?";
  try (PreparedStatement stmt = connection.prepareStatement(sql)) {
    stmt.setLong(1, userId);
    ResultSet rs = stmt.executeQuery();
  }
  ```

## Logging
- **Only SLF4J** (never System.out, System.err, printStackTrace)
- Logger pattern:
  ```java
  private static final Logger logger = LoggerFactory.getLogger(UserService.class);
  ```
- Log levels:
  - `DEBUG` — Development tracing
  - `INFO` — Key transitions
  - `WARN` — Recoverable issues
  - `ERROR` — Unrecoverable errors

---
**Last Updated**: 2026-04-10  
**Stack**: Java 17 TEJ/RestExpress
