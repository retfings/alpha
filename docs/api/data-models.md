# Stock Selection Data Models

This document defines the core data models used throughout the stock selection system, including request/response schemas and domain models.

## Table of Contents

- [Common Types](#common-types)
- [Indicator Models](#indicator-models)
- [Screening Models](#screening-models)
- [Weight Configuration Models](#weight-configuration-models)
- [Trading Model Types](#trading-model-types)
- [Strategy Models](#strategy-models)
- [Execution Models](#execution-models)

---

## Common Types

### StockCode

```typescript
type StockCode = string
// Format: "market.code"
// Examples: "sh.600000", "sz.000001"
```

### DateString

```typescript
type DateString = string
// Format: "YYYY-MM-DD"
// Example: "2024-03-28"
```

### DateTimeString

```typescript
type DateTimeString = string
// Format: ISO 8601
// Example: "2024-03-28T10:30:00Z"
```

### IndicatorCategory

```typescript
type IndicatorCategory =
  | 'technical'      // Technical analysis indicators (MA, RSI, MACD)
  | 'fundamental'    // Fundamental metrics (P/E, P/B, ROE)
  | 'market'         // Market data (market cap, volume)
  | 'sentiment'      // Sentiment indicators (analyst ratings, news)
  | 'volatility'     // Volatility measures (ATR, Bollinger Bands)
```

### SignalType

```typescript
type SignalType =
  | 'bullish'        // Buy signal
  | 'bearish'        // Sell signal
  | 'neutral'        // Hold signal
  | 'overbought'     // Overbought condition
  | 'oversold'       // Oversold condition
  | 'undervalued'    // Undervalued
  | 'overvalued'     // Overvalued
```

### ComparisonOperator

```typescript
type ComparisonOperator =
  | 'eq'             // Equal
  | 'neq'            // Not equal
  | 'gt'             // Greater than
  | 'gte'            // Greater than or equal
  | 'lt'             // Less than
  | 'lte'            // Less than or equal
  | 'between'        // Between two values
  | 'above_price'    // Indicator value above current price
  | 'below_price'    // Indicator value below current price
  | 'cross_above'    // Crossed above threshold
  | 'cross_below'    // Crossed below threshold
```

### RebalancePeriod

```typescript
type RebalancePeriod =
  | 'daily'
  | 'weekly'
  | 'biweekly'
  | 'monthly'
  | 'quarterly'
```

### StrategyStatus

```typescript
type StrategyStatus =
  | 'active'     // Strategy is running
  | 'inactive'   // Strategy is disabled
  | 'paused'     // Strategy is temporarily paused
```

### RunStatus

```typescript
type RunStatus =
  | 'pending'    // Waiting to execute
  | 'running'    // Currently executing
  | 'completed'  // Execution completed
  | 'failed'     // Execution failed
```

---

## Indicator Models

### Indicator

Basic indicator definition.

```typescript
interface Indicator {
  id: string                    // Unique identifier (e.g., "rsi_14")
  name: string                  // Display name
  category: IndicatorCategory   // Category
  description: string           // Description
  parameters: Record<string, IndicatorParameter>  // Configurable parameters
  output_type: 'float' | 'int' | 'bool' | 'string'  // Output type
  tags: string[]                // Search tags
}
```

### IndicatorParameter

Definition of an indicator parameter.

```typescript
interface IndicatorParameter {
  type: 'int' | 'float' | 'string' | 'bool' | 'enum'
  default?: number | string | boolean
  min?: number                  // Minimum value (for numeric types)
  max?: number                  // Maximum value (for numeric types)
  options?: string[]            // Valid options (for enum type)
  description?: string          // Parameter description
}
```

### IndicatorDetail

Extended indicator with calculation details.

```typescript
interface IndicatorDetail extends Indicator {
  formula?: string                          // Calculation formula
  output_range?: {
    min: number
    max: number
  }
  interpretation?: {
    oversold_threshold?: number
    overbought_threshold?: number
  }
  related_indicators?: string[]
}
```

### StockIndicatorValue

Indicator value for a specific stock.

```typescript
interface StockIndicatorValue {
  value: number                 // Current value
  signal: SignalType            // Signal interpretation
  history: HistoricalValue[]    // Historical values
}

interface HistoricalValue {
  date: DateString
  value: number
}
```

### StockIndicatorResponse

Response for stock indicator queries.

```typescript
interface StockIndicatorResponse {
  stock: StockCode
  as_of_date: DateString
  indicators: Record<string, StockIndicatorValue>
}
```

---

## Screening Models

### IndicatorFilter

A single indicator filter condition.

```typescript
interface IndicatorFilter {
  id: string                    // Indicator ID
  operator: ComparisonOperator  // Comparison operator
  value?: number | string | boolean  // Single value
  values?: [number, number]     // For 'between' operator [min, max]
}
```

### ScreenFilters

Additional screening filters.

```typescript
interface ScreenFilters {
  sectors?: string[]                    // Industry sectors
  exchanges?: ('sh' | 'sz')[]           // Stock exchanges
  industries?: string[]                 // Specific industries
  market_cap?: MarketCapRange           // Market cap range
  exclude_st?: boolean                  // Exclude ST stocks
  exclude_new_listing?: boolean         // Exclude new listings
}

interface MarketCapRange {
  min: number                   // Minimum market cap
  max: number                   // Maximum market cap
}
```

### RankingConfig

Ranking configuration for screen results.

```typescript
interface RankingConfig {
  sort_by: string               // Field to sort by
  order: 'asc' | 'desc'         // Sort order
  weight_config_id?: string     // Weight configuration for composite score
}
```

### ScreenRequest

Request to screen stocks.

```typescript
interface ScreenRequest {
  indicators: IndicatorFilter[]   // Indicator filters
  filters?: ScreenFilters         // Additional filters
  ranking?: RankingConfig         // Ranking configuration
  limit?: number                  // Max results (1-500, default: 100)
}
```

### ScreenResult

A single stock in screen results.

```typescript
interface ScreenResult {
  code: StockCode               // Stock code
  name: string                  // Stock name
  score: number                 // Composite score (0-100)
  rank: number                  // Rank in results
  indicators: Record<string, number>  // Indicator values
  current_price: number         // Current price
  signals: Record<string, 'pass' | 'fail' | 'neutral'>  // Filter results
}
```

### ScreenResponse

Response from screen execution.

```typescript
interface ScreenResponse {
  screen_id: string             // Screen execution ID
  timestamp: DateTimeString
  results: {
    total_matches: number       // Total stocks matching criteria
    returned: number            // Number of stocks returned
    stocks: ScreenResult[]      // Stock results
  }
  criteria_applied: {
    indicators: number          // Number of indicator filters
    filters: number             // Number of additional filters
    excluded_count: number      // Number of stocks excluded
  }
}
```

### SavedScreen

Saved screen configuration.

```typescript
interface SavedScreen {
  screen_id: string             // Unique ID
  name: string                  // Screen name
  description?: string          // Description
  criteria: ScreenRequest       // Screen criteria
  is_public: boolean            // Public or private
  created_at: DateTimeString
  updated_at: DateTimeString
  last_run?: DateTimeString     // Last execution time
  last_results_count?: number   // Last result count
}
```

---

## Weight Configuration Models

### WeightConfig

Weight configuration for composite scoring.

```typescript
interface WeightConfig {
  config_id: string             // Unique ID
  name: string                  // Configuration name
  description?: string          // Description
  is_default: boolean           // Is default configuration
  weights: Record<string, number>  // Indicator weights
  created_at: DateTimeString
  updated_at: DateTimeString
}
```

### WeightValidation

Weight validation result.

```typescript
interface WeightValidation {
  valid: boolean                // Are weights valid
  sum: number                   // Sum of weights
  message: string               // Validation message
  adjustment_suggestion?: Record<string, number>  // Suggested adjustment
}
```

### WeightCategory

Category-level weights.

```typescript
interface WeightCategory {
  category: IndicatorCategory
  weight: number                // Category weight (0-1)
  indicators: Record<string, number>  // Individual indicator weights
}
```

---

## Trading Model Types

### TradingModel

Trading model definition.

```typescript
interface TradingModel {
  id: string                    // Model ID
  name: string                  // Model name
  description: string           // Description
  type: 'rebalancing' | 'conditional' | 'strategy'
  parameters: Record<string, TradingModelParameter>
}
```

### TradingModelParameter

Trading model parameter definition.

```typescript
interface TradingModelParameter {
  type: 'int' | 'float' | 'string' | 'bool' | 'enum' | 'array'
  options?: string[]            // For enum type
  default?: number | string | boolean
  min?: number
  max?: number
  description?: string
}
```

### PeriodicRebalanceModel

Periodic rebalancing model parameters.

```typescript
interface PeriodicRebalanceModel extends TradingModel {
  id: 'periodic_rebalance'
  parameters: {
    rebalance_period: {
      type: 'enum'
      options: ['daily', 'weekly', 'biweekly', 'monthly', 'quarterly']
      default: 'monthly'
    }
    hold_count: {
      type: 'int'
      default: 10
      min: 1
      max: 100
    }
    rebalance_threshold: {
      type: 'float'
      default: 0.05
      min: 0.01
      max: 0.20
      description: 'Trigger rebalance if drift exceeds threshold'
    }
  }
}
```

### ConditionalTriggerModel

Conditional trigger model parameters.

```typescript
interface ConditionalTriggerModel extends TradingModel {
  id: 'conditional_trigger'
  parameters: {
    trigger_conditions: {
      type: 'array'
      items: {
        indicator: string
        operator: ComparisonOperator
        value: number
      }
    }
    position_size: {
      type: 'float'
      default: 0.1
      description: 'Position size as fraction of portfolio'
    }
    max_positions: {
      type: 'int'
      default: 10
    }
  }
}
```

### MeanReversionModel

Mean reversion model parameters.

```typescript
interface MeanReversionModel extends TradingModel {
  id: 'mean_reversion'
  parameters: {
    indicator: {
      type: 'string'
      default: 'rsi_14'
    }
    oversold_threshold: {
      type: 'float'
      default: 30
    }
    overbought_threshold: {
      type: 'float'
      default: 70
    }
    exit_threshold: {
      type: 'float'
      default: 50
    }
  }
}
```

### MomentumFollowModel

Momentum following model parameters.

```typescript
interface MomentumFollowModel extends TradingModel {
  id: 'momentum_follow'
  parameters: {
    lookback_period: {
      type: 'int'
      default: 20
    }
    momentum_threshold: {
      type: 'float'
      default: 0.05
    }
    exit_on_reversal: {
      type: 'bool'
      default: true
    }
  }
}
```

---

## Strategy Models

### TradingStrategy

User-defined trading strategy.

```typescript
interface TradingStrategy {
  strategy_id: string           // Unique ID
  name: string                  // Strategy name
  model_id: string              // Base model ID
  model_name: string            // Base model name
  parameters: Record<string, any>  // Model-specific parameters
  screen_id: string             // Linked screen ID
  screen_name: string           // Linked screen name
  weight_config_id?: string     // Weight configuration ID
  status: StrategyStatus        // Current status
  created_at: DateTimeString
  updated_at: DateTimeString
  last_run?: {
    run_at: DateTimeString
    action: string
    stocks_added: number
    stocks_removed: number
    positions_adjusted: number
  }
  next_run?: DateTimeString
  performance?: {
    total_return: number        // Total return since inception
    vs_benchmark: number        // Excess return vs benchmark
    run_count: number           // Number of executions
  }
}
```

### CreateTradingStrategyRequest

Request to create a new strategy.

```typescript
interface CreateTradingStrategyRequest {
  name: string
  model_id: string              // Must be a valid model ID
  parameters: Record<string, any>  // Model-specific parameters
  screen_id: string             // Must be a valid screen ID
  weight_config_id?: string
}
```

---

## Execution Models

### StrategyRunSummary

Summary of a strategy execution.

```typescript
interface StrategyRunSummary {
  run_id: string
  strategy_id: string
  run_at: DateTimeString
  completed_at?: DateTimeString
  status: RunStatus
  action: string                // Type of action taken
  summary: {
    stocks_added: number
    stocks_removed: number
    positions_adjusted: number
    total_turnover: number
  }
}
```

### Trade

A single trade executed by a strategy.

```typescript
interface Trade {
  action: 'buy' | 'sell'
  stock: StockCode
  quantity: number
  price: number
  value: number
  target_weight?: number        // Target portfolio weight
  reason?: string               // Reason for trade
}
```

### StrategyRunDetail

Detailed results of a strategy execution.

```typescript
interface StrategyRunDetail {
  run_id: string
  strategy_id: string
  run_at: DateTimeString
  completed_at: DateTimeString
  status: RunStatus
  action: string
  details: {
    screen_results: {
      total_screened: number
      passed_filters: number
      top_selected: number
    }
    portfolio_before: {
      holdings: number
      cash: number
      total_value: number
    }
    portfolio_after: {
      holdings: number
      cash: number
      total_value: number
    }
    trades: Trade[]
    total_turnover: number
    transaction_costs: number
  }
}
```

### RunStrategyResponse

Response from triggering a strategy run.

```typescript
interface RunStrategyResponseAsync {
  status: 'started'
  run_id: string
}

interface RunStrategyResponseSync {
  status: 'completed'
  run_id: string
  result: {
    action: string
    stocks_added: Array<{
      code: StockCode
      name: string
      weight: number
    }>
    stocks_removed: Array<{
      code: StockCode
      name: string
      weight: number
    }>
    positions_adjusted: Array<{
      code: StockCode
      old_weight: number
      new_weight: number
    }>
    total_turnover: number
    timestamp: DateTimeString
  }
}
```

---

## Error Models

### ErrorResponse

Standard error response format.

```typescript
interface ErrorResponse {
  status: 'error'
  error: {
    code: string                // Error code
    message: string             // Human-readable message
  }
}
```

### ErrorCodes

Standard error codes.

```typescript
type ErrorCode =
  | 'INVALID_INDICATOR'         // Invalid indicator ID
  | 'INVALID_OPERATOR'          // Invalid comparison operator
  | 'INVALID_WEIGHT_SUM'        // Weights do not sum to 1.0
  | 'SCREEN_NOT_FOUND'          // Saved screen not found
  | 'STRATEGY_NOT_FOUND'        // Trading strategy not found
  | 'MODEL_NOT_FOUND'           // Trading model not found
  | 'INVALID_DATE_RANGE'        // Start date after end date
  | 'INSUFFICIENT_DATA'         // Not enough data for calculation
  | 'SCREEN_EXECUTION_FAILED'   // Screen execution failed
  | 'INTERNAL_ERROR'            // Internal server error
```

---

## Response Envelope

All API responses follow this envelope structure:

### Success Response

```typescript
interface SuccessResponse<T> {
  status: 'success'
  data: T
}
```

### Paginated Response

```typescript
interface PaginatedResponse<T> {
  status: 'success'
  data: {
    items: T[]
    total: number
    limit: number
    offset: number
  }
}
```

---

## MoonBit Type Mappings

For implementation in MoonBit, here are the type mappings:

```moonbit
// Common types
pub type StockCode = String
pub type DateString = String  // YYYY-MM-DD
pub type DateTimeString = String  // ISO 8601

// Enumerations
pub enum IndicatorCategory {
  Technical
  Fundamental
  Market
  Sentiment
  Volatility
}

pub enum SignalType {
  Bullish
  Bearish
  Neutral
  Overbought
  Oversold
  Undervalued
  Overvalued
}

pub enum ComparisonOperator {
  Eq
  Neq
  Gt
  Gte
  Lt
  Lte
  Between
  AbovePrice
  BelowPrice
  CrossAbove
  CrossBelow
}

pub enum RebalancePeriod {
  Daily
  Weekly
  Biweekly
  Monthly
  Quarterly
}

pub enum StrategyStatus {
  Active
  Inactive
  Paused
}

pub enum RunStatus {
  Pending
  Running
  Completed
  Failed
}

// Core structs
pub struct Indicator {
  id : String
  name : String
  category : IndicatorCategory
  description : String
  parameters : Map[String, IndicatorParameter]
  output_type : String
  tags : Array[String]
}

pub struct IndicatorParameter {
  param_type : String
  default : Option[Value]
  min : Option[Float]
  max : Option[Float]
  options : Option[Array[String]]
  description : String
}

pub struct StockIndicatorValue {
  value : Float
  signal : SignalType
  history : Array[HistoricalValue]
}

pub struct HistoricalValue {
  date : DateString
  value : Float
}

pub struct IndicatorFilter {
  id : String
  operator : ComparisonOperator
  value : Option[Value]
  values : Option[(Float, Float)]
}

pub struct ScreenResult {
  code : StockCode
  name : String
  score : Float
  rank : Int
  indicators : Map[String, Float]
  current_price : Float
  signals : Map[String, SignalType]
}

pub struct WeightConfig {
  config_id : String
  name : String
  description : String
  is_default : Bool
  weights : Map[String, Float]
  created_at : DateTimeString
  updated_at : DateTimeString
}

pub struct TradingStrategy {
  strategy_id : String
  name : String
  model_id : String
  parameters : Map[String, Value]
  screen_id : String
  weight_config_id : Option[String]
  status : StrategyStatus
  created_at : DateTimeString
  updated_at : DateTimeString
}

pub struct Trade {
  action : String  // "buy" or "sell"
  stock : StockCode
  quantity : Float
  price : Float
  value : Float
  target_weight : Option[Float]
  reason : Option[String]
}
```

---

*Last updated: 2024-03-28*
