# EVM Configuration Override Pattern

**No Factory, No Config DB - Keep It Simple!**

---

## 🎯 The Problem

**How do I override configuration in a derived test without factory or config DB?**

```systemverilog
class base_test extends evm_base_test;
    // Agent has cfg with param1 = 10
    // How does derived test change param1 to 20?
endclass

class derived_test extends base_test;
    // Want to override param1 = 20
endclass
```

---

## ✅ EVM Solution: Factory Methods Pattern

Use **virtual factory methods** for creating configs - simple, explicit, overrideable!

### Pattern 1: Virtual Config Creator

```systemverilog
//==============================================================================
// Base Test - Defines default configuration
//==============================================================================
class base_test extends evm_base_test;
    my_agent agent;
    
    function new(string name = "base_test");
        super.new(name);
    endfunction
    
    //--------------------------------------------------------------------------
    // Virtual Factory Method - Override in derived tests
    //--------------------------------------------------------------------------
    virtual function my_agent_cfg create_agent_cfg();
        my_agent_cfg cfg = new("agent_cfg");
        
        // Default configuration
        cfg.param1 = 10;
        cfg.param2 = "default";
        cfg.enable_feature_x = 0;
        
        return cfg;
    endfunction
    
    virtual function void build_phase();
        super.build_phase();
        
        // Create agent with configuration
        agent = new("agent", this);
        agent.cfg = create_agent_cfg();  // ← Call virtual method
    endfunction
endclass

//==============================================================================
// Derived Test - Overrides configuration
//==============================================================================
class derived_test extends base_test;
    
    function new(string name = "derived_test");
        super.new(name);
    endfunction
    
    //--------------------------------------------------------------------------
    // Override Factory Method
    //--------------------------------------------------------------------------
    virtual function my_agent_cfg create_agent_cfg();
        my_agent_cfg cfg;
        
        // Get base configuration first
        cfg = super.create_agent_cfg();
        
        // Override specific parameters
        cfg.param1 = 20;                    // ← Override!
        cfg.enable_feature_x = 1;           // ← Override!
        
        return cfg;
    endfunction
    
    // build_phase inherited - automatically uses overridden create_agent_cfg()
endclass
```

**Benefits:**
- ✅ Simple and explicit
- ✅ No factory overhead
- ✅ No config DB strings
- ✅ Compile-time checking
- ✅ Easy to debug

---

## 🎨 Pattern 2: Configure Hook

```systemverilog
//==============================================================================
// Base Test
//==============================================================================
class base_test extends evm_base_test;
    my_agent agent;
    
    virtual function void build_phase();
        super.build_phase();
        
        // Create agent with default config
        agent = new("agent", this);
        agent.cfg = new("cfg");
        agent.cfg.param1 = 10;  // Default
        
        // Hook for derived classes
        configure_agent(agent);
    endfunction
    
    //--------------------------------------------------------------------------
    // Virtual Hook - Override to customize
    //--------------------------------------------------------------------------
    virtual function void configure_agent(my_agent agent);
        // Base class does nothing
        // Derived classes override
    endfunction
endclass

//==============================================================================
// Derived Test
//==============================================================================
class derived_test extends base_test;
    
    //--------------------------------------------------------------------------
    // Override Hook
    //--------------------------------------------------------------------------
    virtual function void configure_agent(my_agent agent);
        // Modify configuration after base creation
        agent.cfg.param1 = 20;           // ← Override!
        agent.cfg.enable_feature_x = 1;  // ← Override!
    endfunction
endclass
```

**Benefits:**
- ✅ Simpler than factory method
- ✅ Access to agent object
- ✅ Can call methods on agent
- ✅ Clear override point

---

## 💡 Pattern 3: Builder Pattern

```systemverilog
//==============================================================================
// Configuration Builder
//==============================================================================
class my_agent_cfg_builder;
    
    local my_agent_cfg cfg;
    
    function new();
        cfg = new("cfg");
        set_defaults();
    endfunction
    
    function void set_defaults();
        cfg.param1 = 10;
        cfg.param2 = "default";
    endfunction
    
    // Fluent interface
    function my_agent_cfg_builder with_param1(int val);
        cfg.param1 = val;
        return this;
    endfunction
    
    function my_agent_cfg_builder with_param2(string val);
        cfg.param2 = val;
        return this;
    endfunction
    
    function my_agent_cfg build();
        return cfg;
    endfunction
endclass

//==============================================================================
// Base Test
//==============================================================================
class base_test extends evm_base_test;
    my_agent agent;
    
    virtual function my_agent_cfg_builder get_cfg_builder();
        my_agent_cfg_builder builder = new();
        return builder;  // Derived can override
    endfunction
    
    virtual function void build_phase();
        super.build_phase();
        
        agent = new("agent", this);
        agent.cfg = get_cfg_builder().build();
    endfunction
endclass

//==============================================================================
// Derived Test
//==============================================================================
class derived_test extends base_test;
    
    virtual function my_agent_cfg_builder get_cfg_builder();
        my_agent_cfg_builder builder = super.get_cfg_builder();
        
        // Chain modifications
        builder.with_param1(20)
               .with_param2("custom");
        
        return builder;
    endfunction
endclass
```

**Benefits:**
- ✅ Fluent interface
- ✅ Readable configuration
- ✅ Reusable builders
- ✅ Good for complex configs

---

## 🔧 Pattern 4: Direct Override in build_phase

**Simplest approach - just override build_phase:**

```systemverilog
//==============================================================================
// Base Test
//==============================================================================
class base_test extends evm_base_test;
    my_agent agent;
    
    virtual function void build_phase();
        super.build_phase();
        
        agent = new("agent", this);
        agent.cfg = new("cfg");
        agent.cfg.param1 = 10;  // Default
    endfunction
endclass

//==============================================================================
// Derived Test
//==============================================================================
class derived_test extends base_test;
    
    virtual function void build_phase();
        super.build_phase();  // Creates agent with default cfg
        
        // Override after creation
        agent.cfg.param1 = 20;           // ← Direct override!
        agent.cfg.enable_feature_x = 1;  // ← Direct override!
    endfunction
endclass
```

**Benefits:**
- ✅ Simplest possible
- ✅ No extra methods
- ✅ Explicit and clear

**Drawback:**
- ⚠️ Need to remember what base created

---

## 📊 Comparison

| Pattern | Complexity | Flexibility | Best For |
|---------|-----------|-------------|----------|
| **Factory Method** | Medium | High | Standard approach |
| **Configure Hook** | Low | Medium | Simple overrides |
| **Builder** | High | Very High | Complex configs |
| **Direct Override** | Very Low | Low | Simple cases |

---

## 🎯 Recommendation

**Use Pattern 1 (Factory Method) as standard:**

```systemverilog
// Base test
virtual function my_cfg create_cfg();
    my_cfg cfg = new();
    cfg.param = default_val;
    return cfg;
endfunction

function void build_phase();
    super.build_phase();
    agent.cfg = create_cfg();  // ← Virtual dispatch
endfunction

// Derived test
virtual function my_cfg create_cfg();
    my_cfg cfg = super.create_cfg();
    cfg.param = new_val;  // ← Override
    return cfg;
endfunction
```

**Why:**
- Clean separation of concerns
- Easy to override
- Reuses base configuration
- Compile-time safe
- No magic strings

---

## 💡 Complete Example

```systemverilog
//==============================================================================
// Configuration Class
//==============================================================================
class spi_agent_cfg extends evm_object;
    bit is_active = 1;
    int spi_mode = 0;
    real clk_freq_mhz = 10.0;
    int data_width = 8;
    
    function new(string name = "spi_agent_cfg");
        super.new(name);
    endfunction
endclass

//==============================================================================
// Base Test
//==============================================================================
class spi_base_test extends evm_base_test;
    spi_agent agent;
    
    function new(string name = "spi_base_test");
        super.new(name);
    endfunction
    
    // Virtual factory method
    virtual function spi_agent_cfg create_spi_cfg();
        spi_agent_cfg cfg = new("spi_cfg");
        
        // Default configuration
        cfg.is_active = 1;
        cfg.spi_mode = 0;           // CPOL=0, CPHA=0
        cfg.clk_freq_mhz = 10.0;    // 10 MHz
        cfg.data_width = 8;         // 8-bit
        
        return cfg;
    endfunction
    
    virtual function void build_phase();
        super.build_phase();
        
        agent = new("agent", this);
        agent.cfg = create_spi_cfg();  // ← Uses virtual method
    endfunction
endclass

//==============================================================================
// Mode 3 Test - Override SPI mode
//==============================================================================
class spi_mode3_test extends spi_base_test;
    
    function new(string name = "spi_mode3_test");
        super.new(name);
    endfunction
    
    // Override factory method
    virtual function spi_agent_cfg create_spi_cfg();
        spi_agent_cfg cfg = super.create_spi_cfg();
        
        // Override for Mode 3
        cfg.spi_mode = 3;  // CPOL=1, CPHA=1
        
        return cfg;
    endfunction
endclass

//==============================================================================
// High Speed Test - Override frequency
//==============================================================================
class spi_high_speed_test extends spi_base_test;
    
    function new(string name = "spi_high_speed_test");
        super.new(name);
    endfunction
    
    virtual function spi_agent_cfg create_spi_cfg();
        spi_agent_cfg cfg = super.create_spi_cfg();
        
        // Override for high speed
        cfg.clk_freq_mhz = 50.0;  // 50 MHz
        
        return cfg;
    endfunction
endclass
```

---

## ✨ Summary

**EVM Config Override Pattern:**
1. Use virtual factory methods (`create_xxx_cfg()`)
2. Call `super.create_xxx_cfg()` to get base config
3. Override specific parameters
4. Return modified config

**No factory, no config DB, no strings - just clean virtual methods!** 🎉
