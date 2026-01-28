# Startup Equity Analysis Dashboard

## Overview
Build a Shiny dashboard in R that helps analyze whether a startup equity offer fairly compensates for a salary reduction. The app should calculate break-even equity percentages and visualize the financial comparison over time.

## Layout

### Sidebar Panel (Left)
Input controls for all key variables:

1. **Current Salary (inc. Super)**: Numeric input
   - Default: 203000
   - Label: "Current Total Package ($)"
   - Min: 50000, Max: 500000
   - Step: 5000

2. **Company Valuation**: Numeric input
   - Default: 10000000
   - Label: "Company Valuation ($M)"
   - Min: 1000000, Max: 50000000
   - Step: 1000000
   - Display in millions (e.g., show "10" for 10M)

3. **Vesting Period**: Numeric input
   - Default: 4
   - Label: "Vesting Period (Years)"
   - Min: 1, Max: 10
   - Step: 0.5

4. **Annual CPI**: Numeric input
   - Default: 3.5
   - Label: "Expected Annual CPI (%)"
   - Min: 0, Max: 10
   - Step: 0.1

5. **Salary Percentage**: Slider input
   - Default: 80
   - Label: "New Salary (% of Current)"
   - Min: 50, Max: 100
   - Step: 5
   - Display with % symbol

6. **Risk Multiplier**: Numeric input
   - Default: 4
   - Label: "Risk Multiplier for Equity"
   - Min: 2, Max: 6
   - Step: 0.5
   - Help text: "Accounts for illiquidity and startup risk"

### Main Panel (Right)

#### Section 1: Key Metrics (Value Boxes)
Display 4 value boxes in a row:

1. **New Annual Package**: 
   - Show new salary amount based on slider
   - Format: $XXX,XXX
   - Color: Blue

2. **Annual Sacrifice**: 
   - Difference between current and new salary
   - Format: $XX,XXX
   - Color: Orange

3. **Break-Even Equity**: 
   - Required equity % to compensate for sacrifice
   - Format: X.XX%
   - Color: Green
   - Formula: (Annual Sacrifice × Vesting Period × Risk Multiplier) / Valuation × 100

4. **Equity Value at Current Valuation**:
   - Dollar value of break-even equity at current valuation
   - Format: $XXX,XXX
   - Color: Purple

#### Section 2: Comparison Chart
Interactive line chart showing cumulative value over the vesting period:

**Two scenarios to plot:**

1. **Scenario A - Stay at Current Role**:
   - Starting value: Current salary
   - Each year: Previous year × (1 + CPI/100)
   - Line: Solid, Blue
   - Label: "Current Role (with CPI increases)"

2. **Scenario B - Take Startup Equity**:
   - Annual value: New salary amount (fixed, no CPI increases in startup)
   - Final year add: Break-even equity value (assume exit at end of vesting)
   - Line: Dashed, Green
   - Label: "Startup (salary + equity at exit)"

**Chart specifications:**
- X-axis: Years (0 to vesting period)
- Y-axis: Cumulative compensation ($)
- Title: "Cumulative Compensation Comparison"
- Format Y-axis as currency ($XXX,XXX)
- Include grid lines
- Legend positioned at top-left
- Interactive tooltips showing exact values
- Use ggplot2 or plotly for visualization

#### Section 3: Detailed Table
Create a year-by-year breakdown table with columns:

| Year | Current Role Salary | Current Role Cumulative | Startup Salary | Startup Cumulative | Difference |
|------|--------------------|-----------------------|----------------|-------------------|------------|
| 1    | ...                | ...                   | ...            | ...               | ...        |
| 2    | ...                | ...                   | ...            | ...               | ...        |
| ...  | ...                | ...                   | ...            | ...               | ...        |
| N    | ... (+ equity)     | ...                   | ...            | ...               | ...        |

**Table specifications:**
- Format all currency values as $XXX,XXX
- Highlight final year (when equity value is realized)
- Make Difference column conditional formatting:
  - Red if negative (worse off with startup)
  - Green if positive (better off with startup)
- Use DT::datatable for interactivity

## Calculations

### Break-Even Equity Formula
```
total_sacrifice = (current_salary - new_salary) × vesting_period
equity_value_needed = total_sacrifice × risk_multiplier
break_even_equity_pct = (equity_value_needed / valuation) × 100
```

### Current Role Cumulative Value (Year N)
```
year_1 = current_salary
year_2 = year_1 × (1 + CPI/100)
year_3 = year_2 × (1 + CPI/100)
...
cumulative_year_N = sum(year_1 to year_N)
```

### Startup Cumulative Value (Year N)
```
cumulative_year_N = new_salary × N
# Add equity value only in final year:
if (N == vesting_period) {
  cumulative_year_N = cumulative_year_N + equity_value_needed
}
```

## Styling Requirements

1. **Color Scheme**: 
   - Primary: Blues (#2C3E50, #3498DB)
   - Success: Green (#27AE60)
   - Warning: Orange (#E67E22)
   - Clean, professional appearance

2. **Theme**: Use `shinythemes::shinytheme("flatly")` or similar modern theme

3. **Responsiveness**: Dashboard should work on desktop and tablet

4. **Value Boxes**: Use `shinydashboard::valueBox()` or similar

5. **Typography**: Clear, readable fonts with good spacing

## Additional Features (Optional but Nice to Have)

1. **Dilution Calculator**: Add optional input for expected dilution per funding round
   - Show equity % after Series A/B dilution

2. **Tax Comparison**: 
   - Show after-tax comparison
   - Include super tax advantage (15% vs marginal rate)

3. **Download Button**: Allow user to download comparison table as CSV

4. **Reset Button**: Reset all inputs to defaults

## Testing Scenarios

Ensure the dashboard handles these test cases correctly:

1. **Current role better**: Salary slider at 95%, low equity offer
2. **Startup better**: Salary slider at 60%, high valuation
3. **Break-even**: Adjust to find exact break-even point
4. **Long vesting**: 6-10 year periods
5. **High CPI**: 5-7% inflation scenarios

## Package Requirements
```r
library(shiny)
library(shinydashboard)  # or bslib for modern UI
library(ggplot2)        # for charts
library(plotly)         # for interactive charts
library(DT)             # for interactive tables
library(scales)         # for currency formatting
library(tidyverse)      # for data manipulation
```

## File Structure
Create a single-file Shiny app (app.R) with:
- UI definition
- Server logic
- Helper functions for calculations
- Embedded CSS for custom styling (if needed)

## Deliverables
1. A fully functional Shiny app (app.R)
2. README.md with:
   - Installation instructions
   - How to run the app
   - Explanation of calculations
   - Screenshot of the dashboard

## Notes
- All currency values should be formatted with $ and commas
- Percentages should show 2 decimal places
- Chart should be publication-quality (could screenshot for negotiations)
- Inputs should validate (e.g., salary % can't exceed 100%)
- Consider adding explanatory text/tooltips for complex inputs
