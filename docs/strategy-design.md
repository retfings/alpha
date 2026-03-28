# Strategy Interface Design Decision

## Overview

The strategy module uses a **record-of-functions** approach (struct `Strategy`) rather than traits. This document explains the rationale and trade-offs.

## Current Design: Record-of-Functions

```mbt
// src/strategy/types.mbt
pub(all) struct Strategy {
  name : String
  on_init : (StrategyContext) -> Unit
  on_bar : (@data.KLine, StrategyContext, Array[Float]) -> Signal
}
```

### Usage Example

```mbt
// src/strategy/builtins/ma_cross.mbt
pub struct MaCrossStrategy {
  fast_period : Int
  slow_period : Int
  name : String
}

pub fn MaCrossStrategy::on_bar(
  self : MaCrossStrategy,
  kline : @data.KLine,
  _ctx : @strategy.StrategyContext,
  close_history : Array[Float],
) -> @strategy.Signal {
  // Implementation
}
```

## Alternative: Trait-Based Design

```mbt
pub trait Strategy {
  fn name : String
  fn on_init : (self, StrategyContext) -> Unit
  fn on_bar : (self, KLine, StrategyContext, Array[Float]) -> Signal
}

// Implementation would look like:
pub struct MaCrossStrategy {
  fast_period : Int
  slow_period : Int
}

impl Strategy for MaCrossStrategy {
  fn name(self) -> String { ... }
  fn on_init(self, ctx: StrategyContext) -> Unit { ... }
  fn on_bar(self, kline: KLine, ctx: StrategyContext, history: Array[Float]) -> Signal { ... }
}
```

## Comparison

### Record-of-Functions (Current)

**Pros:**
1. **Simple and explicit** - The interface is a plain struct with function types
2. **No inheritance complexity** - No need to understand trait methods, impl blocks, or associated types
3. **Easy to test** - Can create mock strategies by passing inline functions
4. **Flexible composition** - Functions can be swapped at runtime
5. **Lower cognitive load** - Developers familiar with any language can understand it immediately
6. **Works well with MoonBit's current type system** - No need for advanced trait features

**Cons:**
1. **No compile-time interface enforcement** - Nothing ensures all required functions are provided
2. **Runtime errors possible** - Missing or incorrectly typed functions fail at runtime
3. **Harder to extend** - Adding new interface methods requires updating all construction sites
4. **No polymorphism** - Cannot use subtype polymorphism for strategy collections
5. **No automatic documentation** - Trait methods are self-documenting; function fields are not
6. **Verbosity** - Each strategy must manually construct the Strategy record

### Trait-Based Design

**Pros:**
1. **Compile-time interface enforcement** - Compiler ensures all trait methods are implemented
2. **Type safety** - Method signatures are checked at compile time
3. **Better IDE support** - Autocomplete and go-to-definition work better
4. **Natural polymorphism** - `Array[Strategy]` can hold different strategy implementations
5. **Self-documenting** - Trait definition clearly states the contract
6. **Easier to extend** - Adding methods to trait forces all implementations to update

**Cons:**
1. **More complex** - Requires understanding traits, impl blocks, and potentially associated types
2. **Less flexible** - Cannot easily swap implementations at runtime
3. **MoonBit trait limitations** - MoonBit's trait system may have limitations compared to Rust/Swift
4. **Steeper learning curve** - New contributors need to understand trait semantics
5. **Potential over-engineering** - For a simple strategy interface, traits may be unnecessary

## Decision: Keep Record-of-Functions

After evaluation, we recommend **keeping the current record-of-functions approach** for the following reasons:

### 1. Project Scale
The current codebase has ~500 tests and a focused scope. The simplicity of record-of-functions outweighs the benefits of trait-based polymorphism for this scale.

### 2. Functional Style Fits Domain
Strategy execution is inherently functional:
- Input: market data + state
- Output: trading signal
- Pure function semantics

The record-of-functions approach aligns with this functional mental model.

### 3. Testing Simplicity
White-box tests can easily create inline strategies:
```mbt
let test_strategy = Strategy::{
  name: "test",
  on_init: fn(_) { },
  on_bar: fn(kline, ctx, hist) { Signal::hold(...) }
}
```

This is more cumbersome with traits.

### 4. MoonBit Ecosystem
MoonBit is a relatively new language. Using simpler constructs reduces the risk of hitting language limitations or unclear error messages.

### 5. No Immediate Need for Polymorphism
The current architecture doesn't require runtime polymorphism for strategies. Strategies are typically created once and executed in a loop.

## Future Considerations

### When to Consider Traits

Consider migrating to traits if:
1. **Multiple strategy types** need to be stored in heterogeneous collections
2. **Strategy composition** becomes a requirement (e.g., strategy A delegates to strategy B)
3. **Plugin architecture** is needed (loading strategies from external modules)
4. **Advanced type-level programming** is required (associated types, GATs, etc.)

### Hybrid Approach

A hybrid approach is also possible:
- Keep record-of-functions for simple, inline strategies
- Add a `StrategyTrait` for complex strategies requiring polymorphism

```mbt
pub trait StrategyTrait {
  fn execute(self, kline: KLine, ctx: StrategyContext) -> Signal
}

// Wrapper to adapt record to trait
pub fn adapt_strategy(s: Strategy) -> impl StrategyTrait { ... }
```

## Conclusion

The record-of-functions approach is the right choice for this project's current needs. It provides simplicity, flexibility, and ease of testing while avoiding unnecessary complexity.

Revisit this decision when:
- Project scales to 10x current size
- Complex strategy composition is required
- Plugin/extensibility becomes a priority

---

**Last updated:** 2026-03-27
**Author:** Claude Code
**Task:** #25 - Evaluate traits vs record-of-functions for Strategy interface
