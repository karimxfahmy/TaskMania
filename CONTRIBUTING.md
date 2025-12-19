# Contributing to TaskMania 🤝

Thank you for your interest in contributing to TaskMania! This document provides guidelines for contributing to the project.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Setup](#development-setup)
4. [Making Changes](#making-changes)
5. [Testing](#testing)
6. [Submitting Changes](#submitting-changes)
7. [Style Guidelines](#style-guidelines)

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Respect differing viewpoints and experiences

## Getting Started

### Find an Issue

- Check the [issue tracker](../../issues) for open issues
- Look for issues labeled `good first issue` or `help wanted`
- Comment on the issue to let others know you're working on it

### Report a Bug

Before creating a bug report:
1. Check if the bug has already been reported
2. Try to reproduce it with the latest version
3. Collect relevant information (logs, screenshots, etc.)

Create a bug report with:
- Clear and descriptive title
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, Docker version, etc.)
- Relevant logs and error messages

### Suggest Enhancements

Enhancement suggestions are welcome! Include:
- Clear description of the feature
- Use cases and benefits
- Possible implementation approach
- Any alternatives you've considered

## Development Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/YOUR-USERNAME/TaskMania.git
cd TaskMania

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL-OWNER/TaskMania.git
```

### 2. Set Up Development Environment

```bash
# Build containers
docker-compose build

# Start services
docker-compose up -d

# Install web dependencies for local development
cd web
npm install
```

### 3. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

## Making Changes

### Project Structure

```
TaskMania/
├── api_server.py          # Flask API
├── scripts/               # Monitoring scripts
│   ├── system_monitor.sh  # Bash monitoring
│   ├── alert_system.sh    # Alert system
│   └── data_processor.py  # Data processing
├── web/                   # React frontend
│   └── src/
│       ├── components/    # React components
│       └── App.js         # Main app
├── docker/                # Dockerfiles
└── config/                # Configuration files
```

### Working on Different Components

#### Backend (API Server)

```bash
# Edit api_server.py
# Restart API container
docker-compose restart api

# View logs
docker-compose logs -f api
```

#### Frontend (React)

```bash
cd web

# Start development server
npm start

# Make changes to src/components/*.js
# Changes auto-reload in browser
```

#### Monitoring Scripts

```bash
# Edit scripts/system_monitor.sh
# Rebuild monitor container
docker-compose build monitor
docker-compose up -d monitor

# Test manually
docker-compose exec monitor /app/scripts/system_monitor.sh once
```

#### Docker Configuration

```bash
# Edit Dockerfiles or docker-compose.yml
# Rebuild affected services
docker-compose build
docker-compose up -d
```

## Testing

### Manual Testing

```bash
# Test monitor script
docker-compose exec monitor /app/scripts/system_monitor.sh once

# Test alert system
docker-compose exec alerts /app/scripts/alert_system.sh test

# Test data processor
docker-compose exec processor python3 /app/scripts/data_processor.py summary --hours 1
```

### API Testing

```bash
# Health check
curl http://localhost:8000/api/health

# Get metrics
curl http://localhost:8000/api/metrics/latest

# Get alerts
curl http://localhost:8000/api/alerts/recent
```

### Frontend Testing

```bash
cd web
npm test
```

### Integration Testing

```bash
# Full system test
docker-compose up -d
sleep 30  # Wait for metrics collection
curl http://localhost:8000/api/metrics/latest | jq
open http://localhost:3000
```

## Submitting Changes

### 1. Commit Your Changes

Follow the commit message convention:

```bash
# Format: <type>(<scope>): <subject>

# Examples:
git commit -m "feat(monitor): add GPU temperature monitoring"
git commit -m "fix(api): handle missing metrics file"
git commit -m "docs(readme): update installation instructions"
git commit -m "style(web): improve dashboard layout"
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

### 2. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 3. Create a Pull Request

1. Go to your fork on GitHub
2. Click "New Pull Request"
3. Select your branch
4. Fill in the PR template:
   - Description of changes
   - Related issues
   - Testing performed
   - Screenshots (if applicable)

### 4. Code Review

- Respond to review comments
- Make requested changes
- Push updates to your branch (PR auto-updates)

## Style Guidelines

### Bash Scripts

```bash
#!/bin/bash
# Use strict mode
set -euo pipefail

# Comment functions
function_name() {
    # Function description
    local var_name="value"
    echo "Output"
}

# Use meaningful variable names
CONSTANT_NAME="value"
variable_name="value"
```

### Python Code

```python
# Follow PEP 8
# Use type hints
def function_name(param: str) -> dict:
    """Function description."""
    result = {}
    return result

# Use docstrings
class ClassName:
    """Class description."""
    
    def method_name(self):
        """Method description."""
        pass
```

### JavaScript/React

```javascript
// Use functional components
function ComponentName({ prop }) {
  // Use hooks
  const [state, setState] = useState(null);
  
  // Clear prop names
  return (
    <div className="component-name">
      {/* JSX content */}
    </div>
  );
}

export default ComponentName;
```

### CSS

```css
/* Use BEM naming convention */
.component-name {
  /* Properties */
}

.component-name__element {
  /* Properties */
}

.component-name--modifier {
  /* Properties */
}
```

### Docker

```dockerfile
# Multi-stage builds when possible
FROM base:latest AS builder
# Build steps

FROM base:latest
# Production steps

# Clear labels
LABEL maintainer="email@example.com"

# Meaningful environment variables
ENV VAR_NAME=value
```

## Additional Guidelines

### Documentation

- Update README.md for user-facing changes
- Update code comments for complex logic
- Add docstrings for functions and classes
- Update API documentation for endpoint changes

### Backward Compatibility

- Don't break existing APIs without discussion
- Provide migration paths for breaking changes
- Document breaking changes in CHANGELOG.md

### Performance

- Consider performance impact of changes
- Avoid unnecessary data processing
- Optimize database queries
- Use appropriate data structures

### Security

- Never commit secrets or passwords
- Use environment variables for sensitive data
- Validate and sanitize inputs
- Follow security best practices

## Questions?

Feel free to:
- Open an issue for questions
- Join discussions in existing issues
- Reach out to maintainers

## Recognition

Contributors are recognized in:
- CHANGELOG.md for their changes
- GitHub contributors page
- Special mentions for significant contributions

---

Thank you for contributing to TaskMania! 🎉
