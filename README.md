# Startup Equity Analysis Dashboard

A Shiny dashboard to help analyze whether a startup equity offer fairly compensates for a salary reduction. Calculate break-even equity percentages and visualize the financial comparison over time.

## Features

- **Interactive Inputs**: Adjust salary, valuation, vesting period, CPI, and risk multiplier
- **Australian Tax Integration**: Accurate calculations using 2024-25 tax brackets + 2% Medicare Levy
- **Superannuation Breakdown**: Separate display of base salary and 12% super contributions
- **Take-Home Pay Analysis**: Monthly and annual take-home pay comparison after tax
- **Key Metrics**: Instant calculation of package differences, break-even equity, and equity value
- **Visual Comparison**: Interactive chart showing cumulative compensation over time
- **Detailed Breakdown**: Year-by-year table with color-coded differences
- **Modern UI**: Built with bslib for a clean, professional appearance

## Installation

### Prerequisites

Make sure you have R installed (version 4.0 or higher recommended). Then install the required packages:

```r
install.packages(c(
  "shiny",
  "bslib",
  "bsicons",
  "ggplot2",
  "plotly",
  "DT",
  "scales",
  "dplyr"
))
```

### Running the App

1. Clone or download this repository
2. Open R or RStudio
3. Set your working directory to the app folder:
   ```r
   setwd("path/to/sweat-equity")
   ```
4. Run the app:
   ```r
   shiny::runApp("app.R")
   ```

The dashboard will open in your default web browser.

## How to Use

### Sidebar Inputs

1. **Current Base Salary ($)**: Your current annual base salary (super calculated separately at 12%)
2. **Company Valuation ($M)**: The startup's current valuation in millions
3. **Vesting Period (Years)**: How long until your equity fully vests
4. **Expected Annual CPI (%)**: Expected inflation rate for salary growth projections
5. **New Salary (% of Current)**: The startup's salary offer as a percentage of your current base salary
6. **Risk Multiplier for Equity**: Accounts for illiquidity and startup risk (typically 2-6x)

### Understanding the Results

#### Salary & Take-Home Comparison

Side-by-side comparison cards showing:
- **Base Salary**: The salary component
- **Super (12%)**: Superannuation contribution
- **Total Package**: Base + Super
- **Annual Tax**: Income tax + Medicare Levy (2024-25 rates)
- **Take-Home (Annual)**: After-tax income
- **Take-Home (Monthly)**: Monthly cash flow in your pocket

#### Key Metrics (Value Boxes)

- **Monthly Take-Home Difference**: How much less cash you'll receive each month
- **Annual Package Sacrifice**: Total reduction in package (base + super) per year
- **Break-Even Equity**: The equity percentage needed to fairly compensate for your sacrifice
- **Equity Value**: Dollar value of the break-even equity at current valuation

#### Cumulative Compensation Chart

Compares two scenarios over the vesting period:

- **Blue Line (Solid)**: Staying at your current role with annual CPI increases
- **Green Line (Dashed)**: Taking the startup offer with salary + equity realized at exit

#### Year-by-Year Breakdown Table

Detailed table showing:
- Annual and cumulative compensation for both scenarios
- Difference column with color coding:
  - Red = worse off with startup
  - Green = better off with startup
- Final year highlighted (when equity value is realized)

## Calculation Methodology

### Break-Even Equity Formula

```r
# Calculate total packages (including super at 12%)
current_total = current_base_salary + (current_base_salary × 0.12)
new_total = new_base_salary + (new_base_salary × 0.12)

# Calculate sacrifice and required equity
annual_sacrifice = current_total - new_total
total_sacrifice = annual_sacrifice × vesting_period
equity_value_needed = total_sacrifice × risk_multiplier
break_even_equity_pct = (equity_value_needed / valuation) × 100
```

### Tax Calculation

Uses 2024-25 Australian tax brackets plus 2% Medicare Levy:
```r
# Tax brackets (applied to base salary)
$0 - $18,200: 0%
$18,201 - $45,000: 16%
$45,001 - $135,000: $4,288 + 30% over $45,000
$135,001 - $190,000: $31,288 + 37% over $135,000
$190,001+: $51,638 + 45% over $190,000

# Plus 2% Medicare Levy on all income
take_home = base_salary - (income_tax + medicare_levy)
```

### Current Role Projection

Your current total package (base + super) grows with CPI each year:
```r
year_N_base = current_base × (1 + CPI/100)^(N-1)
year_N_super = year_N_base × 0.12
year_N_total = year_N_base + year_N_super
```

### Startup Projection

Total package (base + super) grows with CPI each year, with equity value added only in the final year (at exit/liquidity event).

### Key Assumptions

1. **Risk Multiplier**: Compensates for:
   - Illiquidity (can't sell equity immediately)
   - Startup risk (company may fail)
   - Opportunity cost of guaranteed salary

2. **Salary Growth**: Both current role and startup salaries grow with CPI each year

3. **Equity Realization**: All equity value realized at end of vesting period

4. **Current Valuation**: Uses current company valuation (doesn't account for future dilution or valuation changes)

## Important Considerations

### What This Calculator DOES Account For

- Time value of money via risk multiplier
- Inflation impact on current role salary
- Cumulative sacrifice over vesting period
- Startup risk and illiquidity

### What This Calculator DOES NOT Account For

- **Future Dilution**: Your equity % will decrease with funding rounds
- **Valuation Changes**: Company value may increase or decrease
- **Tax Implications**: Different tax treatment of salary vs. equity
- **Superannuation Impact**: Lower salary = lower employer super contributions
- **Extended Exit Timeline**: Liquidity may take longer than vesting period
- **Partial Exits**: Secondary sales or early liquidity events

## Example Scenarios

### Scenario 1: Risky Early-Stage Startup

- Current Package: $203,000
- Valuation: $10M
- Vesting: 4 years
- CPI: 3.5%
- Salary Cut: 80% (20% reduction)
- Risk Multiplier: 4x

**Result**: Need ~6.5% equity to break even

### Scenario 2: Well-Funded Growth Stage

- Current Package: $203,000
- Valuation: $50M
- Vesting: 4 years
- CPI: 3.5%
- Salary Cut: 90% (10% reduction)
- Risk Multiplier: 2.5x

**Result**: Need ~0.41% equity to break even

### Scenario 3: Major Pay Cut for Founding Team

- Current Package: $203,000
- Valuation: $5M
- Vesting: 4 years
- CPI: 3.5%
- Salary Cut: 60% (40% reduction)
- Risk Multiplier: 5x

**Result**: Need ~32.5% equity to break even

## Tips for Negotiations

1. **Know Your Break-Even**: Use this calculator before negotiations to understand minimum acceptable equity

2. **Consider the Stage**: Earlier-stage = higher risk multiplier needed

3. **Factor in Dilution**: If break-even is 2%, expect it to become ~1% after Series A

4. **Get It in Writing**: Ensure equity offer includes:
   - Exact percentage (not "number of options")
   - Current fully-diluted cap table
   - Vesting schedule and cliff
   - Acceleration terms

5. **Understand the Cap Table**: Ask about:
   - Option pool size
   - Planned fundraising
   - Expected dilution

## License

MIT License - feel free to use and modify for your own analysis.

## Contributing

Suggestions and improvements welcome! Please open an issue or pull request.

## Disclaimer

This calculator is for informational purposes only and should not be considered financial advice. Consult with a financial advisor before making major career decisions. The calculations make simplifying assumptions and actual outcomes may vary significantly.
