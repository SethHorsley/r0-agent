# MicroAgent 🤖

**MicroAgent** is a Ruby gem that supercharges your development workflow with AI-powered code generation, testing automation, and intelligent analysis. Let AI handle the boilerplate while you focus on solving big problems! 🚀

![MicroAgent Demo](https://via.placeholder.com/800x400.png?text=MicroAgent+Demo+Animation) <!-- Replace with actual demo gif -->

## Current Issues:

### These are prompts that cause problems

add emojies to the command handler

## ✨ Features

- **🧠 AI-Powered Code Generation**  
  Convert natural language prompts into production-ready Ruby code
- **🧪 Test-Driven Development**  
  Auto-generate Minitest specs and ensure code quality
- **💻 Interactive CLI**  
  Conversational interface with command history and auto-complete
- **🔌 Multi-LLM Support**  
  Choose between OpenAI GPT-4/3.5 and Anthropic Claude models
- **🔍 Codebase Analysis**  
  Understand complex codebases and suggest improvements
- **⚡ Rapid Iteration**  
  Automatic test execution with AI-powered error recovery

## 📦 Installation

Add to your project's Gemfile:

```ruby
gem 'micro_agent', '~> 0.1'
```

Then execute:

```bash
bundle install
```

Or install globally:

```bash
gem install micro_agent
```

## ⚙️ Configuration

Set up your API keys interactively:

```bash
micro-agent config
```

Follow the prompts to configure:

```yaml
# ~/.config/micro-agent.yml
providers:
  anthropic:
    api_key: "your_api_key"
  open_ai:
    api_key: "your_api_key"
large_provider:
  provider: "open_ai"
  model: "gpt-4"
```

## 🚀 Basic Usage

Start interactive mode:

```bash
micro-agent
```

Create new components:

```bash
micro-agent create
? Describe your task: A Ruby class that handles JWT authentication
```

Analyze existing code:

```bash
micro-agent /analyze
? What would you like to analyze: Improve error handling in UserController
```

## 🛠️ Example Workflow

1. **Describe Your Task**  
   `Create a Redis-backed rate limiter for API endpoints`

2. **Generate Implementation**

   ```ruby
   class RateLimiter
     def initialize(redis, threshold: 100)
       @redis = redis
       @threshold = threshold
     end
     # ...
   end
   ```

3. **Auto-Generated Tests**

   ```ruby
   require 'test_helper'
   class RateLimiterTest < Minitest::Test
     def test_enforces_threshold
       redis = MockRedis.new
       limiter = RateLimiter.new(redis, threshold: 2)
       assert limiter.check('ip1')
       assert limiter.check('ip1')
       refute limiter.check('ip1')
     end
   end
   ```

4. **Iterative Improvement**
   ```
   Tests failed: 1 error
   Retrying with error context...
   Revised implementation generated
   All tests passed! ✅
   ```

## 🤖 Supported Providers

| Provider  | Models               | Best For             |
| --------- | -------------------- | -------------------- |
| OpenAI    | GPT-4, GPT-3.5 Turbo | Complex logic        |
| Anthropic | Claude 2, Claude 3   | Long-form generation |

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Submit PR with tests

```bash
git clone https://github.com/SethHorsley/micro-agent.git
bundle install
rake test
```

## 📜 License

MIT License - see [LICENSE.txt](LICENSE.txt) for details

## 💬 Support

Found a bug? Have a feature request?  
[Open an issue](https://github.com/your/micro-agent/issues)

---

Made with ❤️ by AI
