# AI-First Development Guide

**EVM - Embedded Verification Methodology**  
**Development Model:** AI-First with Claude and other agentic AI  
**Version:** 1.0.0  
**Last Updated:** 2026-03-28

---

## 🤖 Welcome to AI-First Development

This project is designed from the ground up to be developed **primarily with AI assistants** like Claude, ChatGPT, GitHub Copilot, and other agentic AI tools.

### Why AI-First?

✅ **Faster development** - AI handles boilerplate and patterns  
✅ **Consistent quality** - AI follows documented standards  
✅ **Better documentation** - AI requires and produces clear docs  
✅ **Knowledge transfer** - Documentation is the codebase  
✅ **Accessible** - Anyone can contribute with AI assistance  

---

## 📚 Primary AI Reference: CLAUDE.md

**[CLAUDE.md](CLAUDE.md) is the single source of truth for AI assistants.**

It contains:
- ✅ Complete development rules and guidelines
- ✅ Coding standards (SystemVerilog & Python)
- ✅ Architecture and design philosophy
- ✅ UVM vs EVM comparison and feature priorities
- ✅ Common patterns and anti-patterns
- ✅ Examples and templates

**First step for any AI task:** Read CLAUDE.md

---

## 🚀 Quick Start for AI Development

### Step 1: Set Up Your AI Assistant

**Using Claude (Recommended):**

1. Open Claude
2. Start a new conversation
3. Upload or provide context:
   ```
   I'm working on the EVM project. Please read these files:
   - CLAUDE.md (development rules)
   - README.md (project overview)
   - docs/UVM_vs_EVM_ANALYSIS.md (UVM comparison)
   
   This is an AI-first project. Follow all rules in CLAUDE.md.
   ```

**Using ChatGPT/GitHub Copilot:**
- Similar approach: provide CLAUDE.md as context
- Reference specific sections as needed

### Step 2: Understand the Project

Ask your AI assistant:

```
Please summarize the EVM project based on CLAUDE.md:
1. What is EVM?
2. How is it different from UVM?
3. What are the Priority 1, 2, and 3 features?
4. What's the development philosophy?
```

### Step 3: Start Developing

Choose a task and use appropriate prompts (see below).

---

## 💡 Prompt Templates

### For Adding New Features

```
I want to add [FEATURE_NAME] to EVM.

Please:
1. Check CLAUDE.md section 3.1.2 for feature priorities
2. Tell me if this is Priority 1, 2, or 3
3. If Priority 1 or 2, implement following CLAUDE.md guidelines
4. If Priority 3, explain why we shouldn't add it
5. Update CLAUDE.md if needed

Feature description: [DESCRIBE FEATURE]
```

### For Creating New Agent

```
Create a new agent for [PROTOCOL_NAME] following these requirements:

1. Follow the agent pattern in CLAUDE.md section 11.1
2. Make it generic and configurable (not protocol-specific hardcoding)
3. Include:
   - Interface definition (if_name_if.sv)
   - Configuration class (if_name_cfg.sv)
   - Agent class (if_name_agent.sv)
   - Driver if active mode needed
   - Monitor for observation
4. Add copyright headers per CLAUDE.md section 2.2
5. Follow SystemVerilog coding standards in section 6

Protocol details: [DESCRIBE PROTOCOL]
```

### For Refactoring Code

```
Please refactor [FILE_NAME] following CLAUDE.md standards:

1. Check section 6 for SystemVerilog coding standards
2. Ensure 4-space indentation, no tabs
3. Check constructor rules (section 6.3)
4. Verify all phase methods call super first
5. Use EVM logging, not $display
6. Keep it lightweight per section 3.1.1

File: [PATH_TO_FILE]
```

### For Bug Fixes

```
There's a bug in [FILE_NAME]:

Issue: [DESCRIBE BUG]

Please:
1. Identify root cause
2. Fix following CLAUDE.md coding standards
3. Check for similar issues elsewhere
4. Add comments explaining the fix
5. Update NEXT_STEPS.md if needed
```

### For Documentation

```
Create/update documentation for [FEATURE/COMPONENT]:

1. Follow CLAUDE.md section 8 (Documentation Requirements)
2. Use appropriate format (class comments, README, etc.)
3. Include usage examples
4. Update relevant .md files
5. Keep it concise and clear

Component: [DESCRIBE WHAT TO DOCUMENT]
```

### For UVM Feature Questions

```
I'm considering adding [UVM_FEATURE] to EVM.

Please:
1. Check docs/UVM_vs_EVM_ANALYSIS.md for this feature
2. Tell me if it's in UVM and what it does
3. Check if it's already in EVM (section "UVM to EVM Mapping")
4. Recommend: Implement, Consider, or Skip based on Priority
5. If implementing, provide minimal EVM version (not full UVM complexity)

UVM Feature: [FEATURE_NAME]
```

---

## 🎯 Common Development Tasks

### Task 1: Understanding Existing Code

**Prompt:**
```
Please explain how [COMPONENT/FILE] works:

1. Read the file
2. Explain its purpose
3. Show how it fits into EVM architecture (per CLAUDE.md section 3)
4. Highlight any patterns from CLAUDE.md section 11
5. Note any anti-patterns from section 12

File/Component: [PATH_OR_NAME]
```

### Task 2: Adding Test Cases

**Prompt:**
```
Create a new test case for [SCENARIO]:

1. Follow test template in CLAUDE.md section 9.1
2. Extend evm_base_test
3. Implement all necessary phases
4. Use raise/drop objections in main_phase
5. Add check_phase for verification
6. Follow naming conventions (section 5.2)

Test scenario: [DESCRIBE SCENARIO]
```

### Task 3: Creating Documentation

**Prompt:**
```
Create README.md for [DIRECTORY/COMPONENT]:

1. Follow structure in CLAUDE.md section 8.2
2. Include:
   - Title and description
   - Features/capabilities
   - Usage examples
   - File structure
   - Requirements
   - License reference
3. Use markdown formatting
4. Add copyright header

Component: [NAME]
```

### Task 4: Code Review

**Prompt:**
```
Review this code against CLAUDE.md standards:

[PASTE CODE OR FILE PATH]

Check:
1. Copyright headers (section 2.2)
2. Coding standards (section 6)
3. Constructor rules (section 6.3)
4. Phase methods call super first
5. Logging usage (section 6.5)
6. Anti-patterns (section 12)
7. Documentation (section 8.1)
```

---

## 📋 Development Workflow

### Typical AI-Assisted Workflow

```
1. Define Task
   └─> "I want to add streaming support for SPI interface"

2. Consult AI with Context
   └─> Provide CLAUDE.md + relevant docs

3. AI Analyzes
   └─> Checks priorities, existing patterns, standards

4. AI Proposes Solution
   └─> Implementation following all rules

5. Review & Iterate
   └─> Human reviews, AI adjusts

6. Update Documentation
   └─> AI updates CLAUDE.md, README, etc.

7. Test
   └─> AI creates test cases

8. Commit
   └─> Clear commit message per CLAUDE.md section 14.2
```

### Best Practices

✅ **DO:**
- Always reference CLAUDE.md in prompts
- Ask AI to check feature priorities first
- Request explanations for decisions
- Have AI update documentation with code
- Use specific, detailed prompts
- Iterate based on AI responses

❌ **DON'T:**
- Assume AI knows project without CLAUDE.md
- Skip documentation updates
- Add features without checking priorities
- Ignore AI warnings about complexity
- Accept code that doesn't follow standards

---

## 🔍 Example: Complete Feature Addition

### Scenario: Adding Config Database (Priority 1)

**Initial Prompt:**
```
I want to implement the Configuration Database (evm_config_db) 
which is listed as Priority 1 in CLAUDE.md section 3.1.2.

Please:
1. Read CLAUDE.md section 3.1.2 and 3.1.4 (Refactoring Strategy)
2. Read docs/UVM_vs_EVM_ANALYSIS.md section on Config DB
3. Design a minimal implementation (EVM style, not full UVM)
4. Show me the plan before implementing

Context: This is for hierarchical, type-safe configuration
Est effort: 4-5 days per CLAUDE.md
```

**AI Response** (example):
```
Based on CLAUDE.md and UVM_vs_EVM_ANALYSIS.md, here's the plan:

Files to create:
1. vkit/src/evm_config_db.svh - Template class
2. vkit/src/evm_resource.sv - Resource storage
3. vkit/src/evm_resource_pool.sv - Central pool

Features (minimal):
- Type-safe set/get
- Hierarchical scoping
- Basic wildcard matching
- Integration with evm_component.apply_config_settings()

Skipping (too complex):
- Multiple precedence rules
- Regex matching
- Audit trails
- Resource dependencies

Implementation approach:
[AI shows code structure]

Shall I proceed?
```

**Follow-up Prompts:**
```
Yes, please implement:
1. Create evm_resource.sv first
2. Add copyright header per CLAUDE.md section 2.2
3. Follow coding standards section 6
4. Keep it under 150 lines (lightweight!)

Then:
1. Create evm_resource_pool.sv
2. Create evm_config_db.svh template
3. Update evm_pkg.sv to include new files
4. Add example usage to simple_counter
5. Update CLAUDE.md Appendix A status
```

---

## 🎓 Learning from AI

### Ask AI to Explain Decisions

**Good prompts:**
```
Why did you implement it this way instead of [ALTERNATIVE]?
How does this follow CLAUDE.md guidelines?
What would happen if we did [X] instead?
Are there any tradeoffs with this approach?
```

### Ask AI to Compare with UVM

```
How does this EVM implementation compare to UVM's version?
What UVM features did we intentionally skip? Why?
Is this appropriately lightweight per CLAUDE.md section 3.1.1?
```

### Ask AI to Teach

```
Explain the Phase-based methodology to me using CLAUDE.md
Walk me through how objections work
Show me the difference between transaction and streaming models
```

---

## 🛠️ Tools and Setup

### Recommended AI Tools

| Tool | Best For | Setup |
|------|----------|-------|
| **Claude** | Complex refactoring, architecture | Upload CLAUDE.md |
| **ChatGPT** | Quick questions, code generation | Paste CLAUDE.md sections |
| **GitHub Copilot** | In-editor assistance | Works with local context |
| **Cursor/Windsurf** | IDE integration | Configure with CLAUDE.md |

### Context Management

**For Long Sessions:**
```
Every N messages, remind AI:
"Remember to follow CLAUDE.md section [X] for this task"
```

**For New Topics:**
```
Start with: "New task. Please review CLAUDE.md section [X] before we begin"
```

### File References

**Always reference full paths:**
```
❌ BAD:  "Update the driver"
✅ GOOD: "Update vkit/src/evm_driver.sv"
```

**Include line numbers when specific:**
```
✅ GOOD: "In evm_component.sv lines 45-60, refactor the..."
```

---

## 📊 Quality Checklist

Before committing AI-generated code, verify:

- [ ] Copyright header present (CLAUDE.md 2.2)
- [ ] Follows coding standards (CLAUDE.md 6)
- [ ] Constructors are minimal (CLAUDE.md 6.3)
- [ ] Phase methods call super first (CLAUDE.md 6.4.3)
- [ ] Uses EVM logging, not $display (CLAUDE.md 6.5)
- [ ] Feature priority checked (CLAUDE.md 3.1.2)
- [ ] Documentation updated
- [ ] Examples still work
- [ ] Lightweight implementation (not over-engineered)
- [ ] CLAUDE.md updated if rules change

---

## 🚫 Common Pitfalls

### Pitfall 1: Not Providing Enough Context

❌ **Bad:**
```
Add a factory to EVM
```

✅ **Good:**
```
Implement evm_factory (Priority 1 from CLAUDE.md 3.1.2).
Please read:
- CLAUDE.md section 3.1.4 (Refactoring Strategy Phase 1)
- docs/UVM_vs_EVM_ANALYSIS.md section 4.1.1 (Factory Pattern)

Goal: Minimal implementation for type/instance overrides.
Keep it under 200 LOC per EVM philosophy.
```

### Pitfall 2: Accepting Over-Engineered Solutions

❌ **AI Proposes:** 500-line factory with callbacks, events, and complex inheritance

✅ **Your Response:**
```
This is too complex. CLAUDE.md section 3.1.1 says EVM should be 
lightweight. UVM's factory is 500+ lines - ours should be ~100 lines.

Please simplify:
- Remove callbacks (Priority 3: Skip)
- Remove events
- Just: type registration, override table, create() method
```

### Pitfall 3: Skipping Documentation

❌ **AI:** "Here's the code [paste]"

✅ **You:** 
```
Great! Now also:
1. Add class comment per CLAUDE.md 8.1.1
2. Update CLAUDE.md Appendix A to mark factory as complete
3. Create example in simple_counter showing usage
4. Update README.md feature list
```

### Pitfall 4: Ignoring Priorities

❌ **You:** "Add virtual sequences"

✅ **AI Should Say:**
```
Virtual sequences are Priority 3 (Skip) in CLAUDE.md section 3.1.2.
They add complexity without proportional value for embedded.
Should I explain why, or would you like to add them anyway?
```

---

## 🎯 Success Stories

### Example 1: Simple Counter Example

**Human:**
```
Create a complete working example showing all 12 EVM phases
```

**AI:** (after reading CLAUDE.md)
- Created full directory structure
- Implemented all phases correctly
- Added objections in main_phase
- Created Vivado project scripts
- Wrote comprehensive documentation
- Result: examples/simple_counter/ (fully functional)

### Example 2: CLAUDE.md Creation

**Human:**
```
Create comprehensive development guidelines for AI assistants
```

**AI:**
- Analyzed entire codebase
- Documented all patterns and anti-patterns
- Created UVM comparison
- Defined feature priorities
- Added code templates
- Result: CLAUDE.md (single source of truth)

---

## 📖 Additional Resources

### Documentation Hierarchy

1. **[CLAUDE.md](CLAUDE.md)** - Start here (AI primary reference)
2. **[AI_DEVELOPMENT.md](AI_DEVELOPMENT.md)** - This file (how to work with AI)
3. **[README.md](README.md)** - Project overview
4. **[docs/UVM_vs_EVM_ANALYSIS.md](docs/UVM_vs_EVM_ANALYSIS.md)** - UVM comparison
5. **[examples/](examples/)** - Working code examples

### Quick Reference for AI

```
Question: Should I add feature X?
Answer: Check CLAUDE.md section 3.1.2 priorities

Question: How should I format this code?
Answer: Follow CLAUDE.md section 6

Question: What's the difference from UVM?
Answer: Read docs/UVM_vs_EVM_ANALYSIS.md

Question: How do I test this?
Answer: CLAUDE.md section 9, then examples/simple_counter/

Question: Is this too complex?
Answer: If >200 LOC, probably yes. EVM is lightweight.
```

---

## 🤝 Contributing Back

When you create something great with AI:

1. **Document it** - Update CLAUDE.md with patterns
2. **Create examples** - Show others how to use it
3. **Share prompts** - Add successful prompts to this guide
4. **Improve AI_DEVELOPMENT.md** - Make it better for next person

---

## 📝 Feedback

This guide evolves with the project. If you find:
- Prompts that work particularly well
- Common issues not covered
- Better ways to structure AI interactions

Please update this file or open an issue!

---

## 🎉 Summary

**AI-First Development with EVM:**

1. **CLAUDE.md is your bible** - Reference it in every prompt
2. **Be specific** - Detailed prompts get better results
3. **Check priorities** - Don't add unnecessary complexity
4. **Keep it lightweight** - EVM is simple by design
5. **Document everything** - AI requires and produces good docs
6. **Iterate** - Work with AI, don't just accept first output
7. **Test** - AI can help create tests too
8. **Contribute** - Improve the system for everyone

**Happy AI-assisted development!** 🚀🤖

---

**End of AI_DEVELOPMENT.md**

**Last Updated:** 2026-03-28  
**Version:** 1.0.0  
**Maintainer:** EVM Community
