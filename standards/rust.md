# Rust Best Practices & Standards

This document contains best practices for Rust development that should be followed when creating or reviewing plans.

> **📌 Important**: This document includes both **General Programming Standards** (applicable to all languages) and **Rust-specific guidelines**. The general standards take priority.

---

## General Programming Standards (Rust-Specific)

These are the core principles from `general.md` applied specifically to Rust.

### 🚫 FORBIDDEN: Default Values for Environment Variables

**Never provide default values for environment variables.**

```rust
// ❌ FORBIDDEN - Silent fallback
let port = std::env::var("PORT").unwrap_or("3000".to_string());
let host = std::env::var("HOST").unwrap_or_else(|_| "localhost".to_string());

// ✅ REQUIRED - Fail if not defined
let port = std::env::var("PORT")
    .expect("PORT environment variable must be set");

// ✅ REQUIRED - With anyhow context
let port = std::env::var("PORT")
    .context("PORT environment variable must be set")?;

// ✅ REQUIRED - At startup with validation
fn load_config() -> Result<Config> {
    Ok(Config {
        port: std::env::var("PORT")
            .context("PORT must be set")?,
        database_url: std::env::var("DATABASE_URL")
            .context("DATABASE_URL must be set")?,
    })
}
```

### 🚫 FORBIDDEN: Silent Error Swallowing

**Never ignore error cases. Every `Result` and `Option` must be handled.**

```rust
// ❌ FORBIDDEN - Ignoring the Err case
if let Ok(value) = some_operation() {
    // Using value, but Err is silently ignored!
}

// ❌ FORBIDDEN - Silent unwrap in non-critical path
let _ = file.write_all(data);

// ✅ REQUIRED - Handle or propagate
let value = some_operation()
    .map_err(|e| anyhow::anyhow!("Operation failed: {}", e))?;

// ✅ REQUIRED - Log if truly optional
if let Err(e) = optional_operation() {
    tracing::warn!("Optional operation failed: {}", e);
}

// ✅ REQUIRED - Explicit ignore with reason
let _ = tx.send(msg); // Channel may be closed, receiver handles this
```

### 🚫 FORBIDDEN: Catch-All Defaults in Pattern Matching

**Never use `_` to hide known enum variants.**

```rust
// ❌ FORBIDDEN - Wildcard hiding known cases
enum Status {
    Active,
    Inactive,
    Pending,
    Suspended,  // New variant won't cause compile error!
}

fn handle(status: Status) -> &'static str {
    match status {
        Status::Active => "active",
        Status::Inactive => "inactive",
        _ => "other",  // FORBIDDEN: Hiding Pending and future variants
    }
}

// ✅ REQUIRED - Exhaustive matching
fn handle(status: Status) -> &'static str {
    match status {
        Status::Active => "active",
        Status::Inactive => "inactive",
        Status::Pending => "pending",
        Status::Suspended => "suspended",
        // Compiler will error if new variant is added!
    }
}

// ✅ ACCEPTABLE - Only for truly external/unknown data
fn parse_external(s: &str) -> Status {
    match s {
        "active" => Status::Active,
        "inactive" => Status::Inactive,
        "pending" => Status::Pending,
        "suspended" => Status::Suspended,
        unknown => {
            tracing::warn!("Unknown status from API: {}", unknown);
            Status::Pending  // Explicit fallback with logging
        }
    }
}
```

### 🚫 FORBIDDEN: Unsafe Unwrapping Without Justification

**Never use `.unwrap()` without a clear reason. Use `.expect()` with context.**

```rust
// ❌ FORBIDDEN - No explanation
let value = option.unwrap();
let result = operation().unwrap();

// ❌ FORBIDDEN - In library code (should return Result)
pub fn get_user(id: &str) -> User {
    self.users.get(id).unwrap().clone()
}

// ✅ REQUIRED - With explanation
let value = option.expect("Value guaranteed after validation");

// ✅ REQUIRED - Compile-time guarantees
let regex = Regex::new(r"^\d+$").expect("Static regex is valid");

// ✅ REQUIRED - Return Result in public APIs
pub fn get_user(&self, id: &str) -> Result<User> {
    self.users.get(id)
        .cloned()
        .ok_or_else(|| anyhow::anyhow!("User not found: {}", id))
}
```

---

## Project Structure

### Recommended Layout
```
project/
├── Cargo.toml
├── Cargo.lock
├── src/
│   ├── main.rs          # Binary entry point
│   ├── lib.rs           # Library entry point
│   ├── config.rs        # Configuration handling
│   ├── error.rs         # Custom error types
│   └── modules/
│       ├── mod.rs
│       └── ...
├── tests/               # Integration tests
│   └── integration_test.rs
├── benches/             # Benchmarks
│   └── benchmark.rs
├── examples/            # Example code
│   └── example.rs
└── docs/               # Documentation
```

---

## Code Style

### Naming Conventions
| Item | Convention | Example |
|------|------------|---------|
| Crates | snake_case | `my_crate` |
| Modules | snake_case | `my_module` |
| Types (structs, enums, traits) | PascalCase | `MyStruct` |
| Functions | snake_case | `my_function` |
| Methods | snake_case | `my_method` |
| Local variables | snake_case | `my_variable` |
| Constants | SCREAMING_SNAKE_CASE | `MY_CONSTANT` |
| Static variables | SCREAMING_SNAKE_CASE | `MY_STATIC` |
| Type parameters | Single uppercase or PascalCase | `T`, `Item` |
| Lifetimes | Short lowercase | `'a`, `'de` |

### Formatting
- Use `rustfmt` for consistent formatting
- Configure in `rustfmt.toml`:
```toml
edition = "2021"
max_width = 100
tab_spaces = 4
use_small_heuristics = "Default"
```

---

## Error Handling

### Use `thiserror` for Library Errors
```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum MyError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    
    #[error("Invalid configuration: {message}")]
    Config { message: String },
    
    #[error("Not found: {0}")]
    NotFound(String),
}
```

### Use `anyhow` for Application Errors
```rust
use anyhow::{Context, Result};

fn read_config(path: &str) -> Result<Config> {
    let content = std::fs::read_to_string(path)
        .context("Failed to read configuration file")?;
    
    let config: Config = serde_json::from_str(&content)
        .context("Failed to parse configuration")?;
    
    Ok(config)
}
```

### Error Handling Guidelines
- Never use `.unwrap()` in library code
- Use `.expect("meaningful message")` only when panic is intentional
- Propagate errors with `?` operator
- Add context to errors for better debugging
- Define custom error types for domain-specific errors

---

## Memory & Performance

### Ownership Best Practices
```rust
// Prefer borrowing over cloning
fn process(data: &str) -> Result<()> { ... }

// Use Cow for flexible ownership
use std::borrow::Cow;
fn process_flexible(data: Cow<'_, str>) -> String { ... }

// Return owned data from constructors
impl MyStruct {
    pub fn new(name: String) -> Self { ... }
}
```

### Performance Guidelines
- Use `&str` over `String` for function parameters when possible
- Prefer iterators over indexed loops
- Use `Vec::with_capacity()` when size is known
- Avoid unnecessary allocations in hot paths
- Use `#[inline]` judiciously for small, frequently-called functions

### Zero-Cost Abstractions
```rust
// Use iterators (compiled to efficient loops)
let sum: i32 = numbers.iter().filter(|n| **n > 0).sum();

// Use Option/Result methods instead of match
let value = option.unwrap_or_default();
let result = result.map(|v| v * 2)?;
```

---

## Concurrency

### Async Best Practices
```rust
// Use tokio for async runtime
#[tokio::main]
async fn main() -> Result<()> {
    // ...
}

// Use async traits with async-trait crate
use async_trait::async_trait;

#[async_trait]
pub trait MyTrait {
    async fn process(&self) -> Result<()>;
}
```

### Thread Safety
```rust
// Use Arc for shared ownership across threads
use std::sync::Arc;
let shared = Arc::new(data);

// Use Mutex/RwLock for interior mutability
use std::sync::{Mutex, RwLock};
let data = Arc::new(Mutex::new(value));

// Prefer RwLock for read-heavy workloads
let data = Arc::new(RwLock::new(value));
```

---

## Testing

### Test Organization
```rust
// Unit tests in the same file
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_basic_functionality() {
        // Arrange
        let input = "test";
        
        // Act
        let result = process(input);
        
        // Assert
        assert_eq!(result, expected);
    }
}
```

### Integration Tests
```rust
// tests/integration_test.rs
use my_crate::*;

#[test]
fn test_full_workflow() {
    // Test end-to-end functionality
}
```

### Testing Guidelines
- Aim for high test coverage on public APIs
- Use `proptest` or `quickcheck` for property-based testing
- Use `mockall` for mocking in tests
- Test error cases, not just happy paths
- Use `#[should_panic]` for panic tests

---

## Documentation

### Documentation Style
```rust
/// Short summary of what this function does.
///
/// More detailed explanation if needed. Can span
/// multiple paragraphs.
///
/// # Arguments
///
/// * `arg1` - Description of first argument
/// * `arg2` - Description of second argument
///
/// # Returns
///
/// Description of return value
///
/// # Errors
///
/// Description of when errors are returned
///
/// # Examples
///
/// ```
/// use my_crate::my_function;
///
/// let result = my_function("input");
/// assert_eq!(result, expected);
/// ```
///
/// # Panics
///
/// Description of when this function panics (if applicable)
pub fn my_function(arg1: &str, arg2: i32) -> Result<String> {
    // ...
}
```

---

## Dependencies

### Cargo.toml Best Practices
```toml
[package]
name = "my-crate"
version = "0.1.0"
edition = "2021"
rust-version = "1.70"
description = "Brief description"
license = "MIT OR Apache-2.0"
repository = "https://github.com/..."

[dependencies]
serde = { version = "1.0", features = ["derive"] }
tokio = { version = "1", features = ["full"] }

[dev-dependencies]
criterion = "0.5"

[features]
default = []
full = ["feature1", "feature2"]
```

### Dependency Guidelines
- Pin major versions: `"1"` or `"1.0"`
- Use workspace dependencies for monorepos
- Audit dependencies with `cargo audit`
- Minimize feature flags to reduce compile time
- Prefer well-maintained, widely-used crates

---

## Security

### Security Checklist
- [ ] No `.unwrap()` on user input
- [ ] Validate all external data
- [ ] Use constant-time comparison for secrets
- [ ] Sanitize log output (no secrets)
- [ ] Use `secrecy` crate for sensitive data
- [ ] Run `cargo audit` regularly
- [ ] Enable Clippy security lints

### Secure Coding
```rust
// Use secrecy for sensitive data
use secrecy::{Secret, ExposeSecret};

struct Config {
    api_key: Secret<String>,
}

// Constant-time comparison
use subtle::ConstantTimeEq;
```

---

## Clippy Lints

### Recommended Clippy Configuration
```toml
# Cargo.toml or .cargo/config.toml
[lints.clippy]
all = "warn"
pedantic = "warn"
nursery = "warn"
cargo = "warn"

# Allow specific lints as needed
module_name_repetitions = "allow"
must_use_candidate = "allow"
```

### Common Clippy Fixes
- Use `if let` instead of `match` for single patterns
- Prefer `map_or` over `map().unwrap_or()`
- Use `collect()` type hints: `collect::<Vec<_>>()`
- Replace `clone()` with `to_owned()` for strings

---

## CI/CD Recommendations

### GitHub Actions Workflow
```yaml
name: CI

on: [push, pull_request]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: rustfmt, clippy
      
      - name: Format check
        run: cargo fmt --check
      
      - name: Clippy
        run: cargo clippy -- -D warnings
      
      - name: Test
        run: cargo test
      
      - name: Audit
        run: cargo audit
```

---

## Summary Checklist

When reviewing or creating Rust code:

### General Standards (MUST)
- [ ] **No default env vars** - All env vars fail if undefined
- [ ] **No silent errors** - All `Result`/`Option` handled or propagated
- [ ] **No catch-all patterns** - Exhaustive matching on known enums
- [ ] **No bare `.unwrap()`** - Use `.expect("reason")` or handle properly

### Rust-Specific Standards
- [ ] Follows naming conventions
- [ ] Proper error handling (no unwrap in library code)
- [ ] Documentation on public items
- [ ] Tests for new functionality
- [ ] No Clippy warnings
- [ ] Formatted with rustfmt
- [ ] Dependencies audited
- [ ] Performance considerations addressed
