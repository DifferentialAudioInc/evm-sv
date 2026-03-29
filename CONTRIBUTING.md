# Contributing to EVM

**EVM - Embedded Verification Methodology**  
**Development Model:** AI-First 🤖  
**Last Updated:** 2026-03-28

---

## 🎯 Welcome Contributors!

We welcome contributions to EVM! This project uses an **AI-first development approach** - meaning we expect and encourage the use of AI assistants like Claude, ChatGPT, and GitHub Copilot.

**Key Philosophy:** AI-assisted development with human oversight for quality

---

## 🤖 AI-First Development

### Required Reading

Before contributing, please read:

1. **[CLAUDE.md](CLAUDE.md)** - Complete development rules and standards (PRIMARY)
2. **[AI_DEVELOPMENT.md](AI_DEVELOPMENT.md)** - How to develop with AI assistance
3. **[README.md](README.md)** - Project overview and goals
4. **[docs/UVM_vs_EVM_ANALYSIS.md](docs/UVM_vs_EVM_ANALYSIS.md)** - UVM comparison and feature priorities

### Why AI-First?

✅ Faster development cycles  
✅ Consistent code quality  
✅ Better documentation  
✅ Lower barrier to entry  
✅ Knowledge sharing through documentation  

---

## 📋 Contribution Process

### 1. Preparation

**Read the documentation:**
```
✅ CLAUDE.md (development rules)
✅ AI_DEVELOPMENT.md (AI workflow)
✅ Relevant docs/ files for your task
✅ examples/ to understand patterns
```

**Set up AI assistant:**
```
Provide CLAUDE.md to your AI assistant
Reference specific sections as needed
Use prompt templates from AI_DEVELOPMENT.md
```

### 2. Choose Your Contribution

**Priority 1: Essential Features (Most Needed)**
- Factory pattern implementation
- Configuration database (evm_config_db)
- TLM seq_item_port for driver-sequencer connection

**Priority 2: Enhancements**
- Additional examples
- Documentation improvements
- Bug fixes
- Testing improvements

**Priority 3: Do NOT Add (Keep Lightweight)**
- Full RAL (we have CSR generator)
- Virtual sequences (not needed)
- Callback infrastructure
- TLM 2.0
- Additional phase domains

**Check CLAUDE.md section 3.1.2 for current priorities**

### 3. Development Workflow

```
1. Fork the repository
   └─> github.com/DifferentialAudioInc/evm-sv

2. Create a branch
   └─> git checkout -b feature/your-feature-name

3. Develop with AI assistance
   └─> Use AI_DEVELOPMENT.md prompts
   └─> Follow CLAUDE.md standards
   └─> Keep implementation lightweight

4. Test your changes
   └─> Run existing examples
   └─> Add new tests if needed
   └─> Verify nothing breaks

5. Update documentation
   └─> Update CLAUDE.md if rules change
   └─> Update README.md if features added
   └─> Add/update examples
   └─> Write clear commit messages

6. Submit pull request
   └─> Describe changes clearly
   └─> Reference issues if applicable
   └─> Show before/after if relevant
```

---

## ✅ Contribution Guidelines

### DO:

✅ **Use AI assistants** - Claude, ChatGPT, Copilot, etc.  
✅ **Follow CLAUDE.md** - All coding standards and rules  
✅ **Check feature priorities** - Don't add Priority 3 features  
✅ **Keep it lightweight** - EVM is simple by design  
✅ **Add copyright headers** - Per CLAUDE.md section 2.2  
✅ **Update documentation** - Code + docs together  
✅ **Test thoroughly** - Don't break existing examples  
✅ **Use EVM logging** - Not $display  
✅ **Call super.method()** first - Always  
✅ **Minimal constructors** - No object creation  
✅ **Generic agents** - Not protocol-specific  

### DON'T:

❌ **Over-engineer** - If it's complex, simplify  
❌ **Skip documentation** - Code without docs won't be accepted  
❌ **Ignore CLAUDE.md** - It's the law  
❌ **Add UVM complexity** - EVM is 10x simpler  
❌ **Break examples** - They must always work  
❌ **Hardcode specifics** - Keep agents generic  
❌ **Use $display** - Use log_info/warning/error  
❌ **Skip tests** - Prove it works  
❌ **Forget copyright** - Required in all files  
❌ **Submit without AI check** - Have AI review first  

---

## 🎨 Code Style

### SystemVerilog

**Follow CLAUDE.md Section 6:**

```systemverilog
// ✅ GOOD
class my_agent extends evm_agent;
    // Properties
    my_cfg cfg;
    
    // Constructor - MINIMAL
    function new(string name, evm_component parent);
        super.new(name, parent);
    endfunction
    
    // Phases - call super first
    virtual function void build_phase();
        super.build_phase();
        log_info("Building agent", EVM_HIGH);
    endfunction
endclass
```

**Common mistakes to avoid:**

```systemverilog
// ❌ WRONG - Creating objects in constructor
function new(string name = "test");
    super.new(name);
    my_agent = new("agent", this);  // NO!
endfunction

// ❌ WRONG - No super call
virtual function void build_phase();
    my_logic();  // Where's super.build_phase()?
endfunction

// ❌ WRONG - Using $display
$display("Test starting");  // Use log_info instead
```

### Python

**Follow CLAUDE.md Section 7:**

```python
# ✅ GOOD
def generate_stimulus(freq: float, duration: float, fs: float) -> np.ndarray:
    """
    Generate sine wave stimulus.
    
    Args:
        freq: Frequency in Hz
        duration: Duration in seconds
        fs: Sample rate in Hz
    
    Returns:
        NumPy array of samples
    """
    if freq <= 0:
        raise ValueError(f"Frequency must be positive, got {freq}")
    
    return np.sin(2 * np.pi * freq * np.arange(0, duration, 1/fs))
```

---

## 📝 Commit Messages

**Format:**

```
<type>: <short description>

<optional longer description>

<optional issue reference>
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance

**Examples:**

```
✅ GOOD:
feat: Add factory pattern implementation
fix: Correct objection handling in base test
docs: Update CLAUDE.md with new patterns
refactor: Simplify agent creation per CLAUDE.md

❌ BAD:
update
fixes
wip
minor changes
```

---

## 🧪 Testing

### Before Submitting

1. **Run existing examples:**
   ```bash
   cd examples/simple_counter/sim
   # Test that example still works
   ```

2. **Add tests for new features:**
   ```systemverilog
   // Create test following CLAUDE.md section 9.1
   class my_feature_test extends evm_base_test;
       // Test implementation
   endclass
   ```

3. **Verify documentation:**
   - [ ] README.md updated if needed
   - [ ] CLAUDE.md updated if rules changed
   - [ ] Example added/updated
   - [ ] Comments added to code

---

## 📖 Documentation Requirements

### For New Features

1. **Code comments** (CLAUDE.md section 8.1):
   ```systemverilog
   //--------------------------------------------------------------------------
   // Class: my_new_feature
   // Description: What it does and why
   //--------------------------------------------------------------------------
   ```

2. **README updates** if visible feature

3. **CLAUDE.md updates** if new patterns or rules

4. **Examples** showing usage

### For Bug Fixes

1. **Comment explaining fix:**
   ```systemverilog
   // Fix for issue #123: Objection not properly dropped
   // Root cause was...
   ```

2. **Update NEXT_STEPS.md** if needed

---

## 🔍 Pull Request Checklist

Before submitting your PR:

- [ ] I've read CLAUDE.md
- [ ] I've used AI assistance (Claude, ChatGPT, etc.)
- [ ] Code follows CLAUDE.md standards
- [ ] Copyright headers added to new files
- [ ] Feature priority checked (not Priority 3)
- [ ] Implementation is lightweight
- [ ] All phase methods call super first
- [ ] Using EVM logging (not $display)
- [ ] Constructors are minimal
- [ ] Documentation updated
- [ ] Examples work
- [ ] Tests added/updated
- [ ] CLAUDE.md updated if needed
- [ ] Commit messages are clear
- [ ] No broken functionality

---

## 🎯 Priority Areas for Contribution

### Highest Priority (Most Needed)

1. **Factory Pattern** (~10-13 days)
   - See docs/UVM_vs_EVM_ANALYSIS.md section 4.1.1
   - Goal: ~100-200 LOC implementation
   - Features: type/instance overrides, create()

2. **Configuration Database** (~4-5 days)
   - See docs/UVM_vs_EVM_ANALYSIS.md section 4.1.2
   - Goal: ~150-200 LOC implementation
   - Features: set/get, hierarchical scope

3. **TLM Seq Item Port** (~3-4 days)
   - See docs/UVM_vs_EVM_ANALYSIS.md section 4.1.3
   - Goal: ~100-150 LOC implementation
   - Features: get_next_item(), item_done()

### Medium Priority

- Additional working examples
- More protocol agents
- Python tool enhancements
- Documentation improvements
- Bug fixes

### Low Priority (But Welcome)

- Printing infrastructure
- Comparison infrastructure
- Additional tests
- Performance optimizations

---

## 💡 Tips for Success

### Working with AI

```
"I want to contribute [FEATURE]. Please help me:
1. Check if it's Priority 1, 2, or 3 in CLAUDE.md
2. Review existing implementation in [FILE]
3. Propose implementation following CLAUDE.md standards
4. Keep it lightweight (EVM is 10x simpler than UVM)"
```

### Getting Started

**Easy first contributions:**
1. Fix documentation typos
2. Add code comments
3. Improve examples
4. Add tests

**Medium contributions:**
1. New protocol agent
2. New example testbench
3. Python tool enhancement
4. Bug fixes

**Advanced contributions:**
1. Factory pattern
2. Config database
3. TLM ports
4. Architecture improvements

---

## 🤝 Code Review Process

### What We Look For

1. **Follows CLAUDE.md** - All standards met
2. **Lightweight** - Not over-engineered
3. **Documented** - Clear comments and updates
4. **Tested** - Examples work
5. **AI-assisted** - Used AI for consistency

### Typical Review Comments

```
"Please add copyright header per CLAUDE.md 2.2"
"Constructor should be minimal - move object creation to connect_interfaces()"
"Use log_info instead of $display per CLAUDE.md 6.5"
"This seems complex - can we simplify per section 3.1.1?"
"Great! Please also update CLAUDE.md Appendix A status"
```

---

## 🐛 Reporting Issues

### Bug Reports

```markdown
**Describe the bug**
Clear description of the issue

**To Reproduce**
Steps to reproduce:
1. cd examples/simple_counter
2. Run simulation
3. See error

**Expected behavior**
What should happen

**Environment**
- Simulator: Vivado 2023.2
- OS: Windows 11
- EVM version: 1.0.0

**Additional context**
Any other relevant information
```

### Feature Requests

```markdown
**Feature description**
What feature do you want?

**Priority check**
Have you checked CLAUDE.md section 3.1.2?
Is this Priority 1, 2, or 3?

**Use case**
Why is this needed?

**Proposed implementation**
How might this work?
```

---

## 📞 Getting Help

### Questions?

1. **Check documentation first:**
   - CLAUDE.md for development questions
   - AI_DEVELOPMENT.md for AI workflow
   - docs/ for technical details

2. **Ask AI:**
   ```
   "I'm trying to contribute to EVM. 
   Please read CLAUDE.md and help me with [QUESTION]"
   ```

3. **Open an issue:**
   - GitHub Issues for unresolved questions
   - Tag as "question"

### Discussion

- Use GitHub Discussions for:
  - Feature ideas
  - Best practices
  - General questions
  - Sharing successes

---

## 🎉 Recognition

Contributors who follow these guidelines and submit quality PRs will be:

- ✨ Listed in CONTRIBUTORS.md
- ✨ Credited in release notes
- ✨ Acknowledged in documentation
- ✨ Building the future of AI-first development!

---

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

## 🙏 Thank You!

Every contribution makes EVM better for the community. Whether it's:
- A single typo fix
- A new feature
- Documentation improvement
- Bug report

**We appreciate your help!** 🚀

---

**Questions about contributing?**

- 📖 Read [CLAUDE.md](CLAUDE.md)
- 🤖 Check [AI_DEVELOPMENT.md](AI_DEVELOPMENT.md)
- 📝 See [README.md](README.md)
- 💬 Open an issue

**Happy contributing with AI!** 🤖✨

---

**End of CONTRIBUTING.md**

**Last Updated:** 2026-03-28  
**Maintainer:** EVM Community
