# Startup Equity Analysis Dashboard
# A Shiny app to analyze startup equity offers vs. salary reductions

library(shiny)
library(bslib)
library(ggplot2)
library(plotly)
library(DT)
library(scales)
library(dplyr)

# Helper function to calculate Australian tax (2024-25 brackets)
calculate_aus_tax <- function(taxable_income) {
  if (taxable_income <= 18200) {
    tax <- 0
  } else if (taxable_income <= 45000) {
    tax <- (taxable_income - 18200) * 0.16
  } else if (taxable_income <= 135000) {
    tax <- 4288 + (taxable_income - 45000) * 0.30
  } else if (taxable_income <= 190000) {
    tax <- 31288 + (taxable_income - 135000) * 0.37
  } else {
    tax <- 51638 + (taxable_income - 190000) * 0.45
  }

  # Add 2% Medicare Levy
  medicare_levy <- taxable_income * 0.02

  return(tax + medicare_levy)
}

# Define UI
ui <- page_sidebar(
  title = "Startup Equity Analysis Dashboard",
  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",
    primary = "#3498DB",
    success = "#27AE60",
    warning = "#E67E22"
  ) %>%
    bs_add_rules("
      body { zoom: 0.9; }
      .card { margin-bottom: 0.5rem !important; }
      .card-body { padding: 0.75rem !important; }
      .card-header { padding: 0.5rem 0.75rem !important; font-size: 0.95rem !important; }
      p { margin-bottom: 0.25rem !important; font-size: 0.9rem !important; }
      .value-box { padding: 0.4rem 0.6rem !important; height: 60px !important; min-height: 60px !important; max-height: 60px !important; flex-shrink: 0 !important; }
      .value-box .value-box-title { font-size: 0.7rem !important; margin-bottom: 0.1rem !important; line-height: 1.1 !important; }
      .value-box .value-box-value { font-size: 1.1rem !important; font-weight: 700 !important; line-height: 1.2 !important; }
      .value-box .value-box-showcase { font-size: 1.2rem !important; }
      .value-box .value-box-area { gap: 0.3rem !important; }
      .bslib-value-box { height: 60px !important; }
      hr { margin: 0.5rem 0 !important; }
      .bslib-sidebar-layout { gap: 0.75rem !important; }
      .form-group { margin-bottom: 0.75rem !important; }
      .form-label { margin-bottom: 0.25rem !important; font-size: 0.9rem !important; }
      .text-muted.small { font-size: 0.75rem !important; margin-top: -0.5rem !important; }
      .bslib-sidebar-input { padding: 0.75rem !important; }
      .navbar { padding: 0.5rem 1rem !important; }
      .nav-link { padding: 0.5rem 0.75rem !important; font-size: 0.9rem !important; }
      .tab-content { overflow-y: auto !important; }
      .bslib-navs-card-item { padding: 0.75rem !important; }
    "),

  # Sidebar with inputs
  sidebar = sidebar(
    width = 300,

    numericInput(
      "current_salary",
      "Current Base Salary ($)",
      value = 203000,
      min = 50000,
      max = 500000,
      step = 5000
    ),
    p(class = "text-muted small", "Super (12%) will be calculated separately"),

    numericInput(
      "company_valuation",
      "Company Valuation ($M)",
      value = 10,
      min = 1,
      max = 50,
      step = 1
    ),

    numericInput(
      "vesting_period",
      "Vesting Period (Years)",
      value = 4,
      min = 1,
      max = 10,
      step = 0.5
    ),

    numericInput(
      "annual_cpi",
      "Expected Annual CPI (%)",
      value = 3.5,
      min = 0,
      max = 10,
      step = 0.1
    ),

    sliderInput(
      "salary_percentage",
      "New Salary (% of Current)",
      value = 80,
      min = 50,
      max = 100,
      step = 5,
      post = "%"
    ),

    numericInput(
      "risk_multiplier",
      "Risk Multiplier for Equity",
      value = 4,
      min = 2,
      max = 6,
      step = 0.5
    ),
    p(class = "text-muted small", "Accounts for illiquidity and startup risk"),

    hr(),

    actionButton("reset", "Reset to Defaults", class = "btn-secondary w-100")
  ),

  # Main content area
  navset_card_tab(

    nav_panel(
      "Analysis",
      style = "overflow-y: auto; max-height: calc(100vh - 150px);",

      # Key Metrics Value Boxes
      layout_column_wrap(
        width = 1/4,

        value_box(
          title = "Monthly Take-Home Difference",
          value = textOutput("monthly_difference_display"),
          showcase = bsicons::bs_icon("calendar-minus"),
          theme = "warning"
        ),

        value_box(
          title = "Annual Package Sacrifice",
          value = textOutput("annual_sacrifice_display"),
          showcase = bsicons::bs_icon("graph-down"),
          theme = "danger"
        ),

        value_box(
          title = "Break-Even Equity",
          value = textOutput("breakeven_equity_display"),
          showcase = bsicons::bs_icon("percent"),
          theme = "success"
        ),

        value_box(
          title = "Equity Value (Current Val.)",
          value = textOutput("equity_value_display"),
          showcase = bsicons::bs_icon("trophy"),
          theme = "purple"
        )
      ),

      # Detailed Analysis - Tabbed Card
      card(
        navset_card_tab(
          height = "650px",
          nav_panel(
            "Chart",
            plotlyOutput("comparison_chart", height = "540px")
          ),

          nav_panel(
            "Table",
            DTOutput("comparison_table")
          ),

          nav_panel(
            "Take-Home",
            layout_column_wrap(
              width = 1/2,

              card(
                card_header("Current Role", class = "bg-primary text-white"),
                p(strong("Base:"), textOutput("current_base_display", inline = TRUE)),
                p(strong("Super (12%):"), textOutput("current_super_display", inline = TRUE)),
                p(strong("Total Package:"), textOutput("current_total_display", inline = TRUE)),
                hr(),
                p(strong("Tax:"), textOutput("current_tax_display", inline = TRUE)),
                p(strong("Annual Take-Home:"), textOutput("current_takehome_display", inline = TRUE)),
                p(strong("Monthly Take-Home:"), textOutput("current_monthly_display", inline = TRUE),
                  style = "font-size: 1.1rem; margin-top: 0.25rem;")
              ),

              card(
                card_header("Startup Offer", class = "bg-success text-white"),
                p(strong("Base:"), textOutput("new_base_display", inline = TRUE)),
                p(strong("Super (12%):"), textOutput("new_super_display", inline = TRUE)),
                p(strong("Total Package:"), textOutput("new_total_display", inline = TRUE)),
                hr(),
                p(strong("Tax:"), textOutput("new_tax_display", inline = TRUE)),
                p(strong("Annual Take-Home:"), textOutput("new_takehome_display", inline = TRUE)),
                p(strong("Monthly Take-Home:"), textOutput("new_monthly_display", inline = TRUE),
                  style = "font-size: 1.1rem; margin-top: 0.25rem;")
              )
            ),

            hr(),

            # Package Decrease Summary
            card(
              card_header("Package Decrease Summary"),
              layout_column_wrap(
                width = 1/3,

                div(
                  p(strong("Package Decrease (Annual):"),
                    style = "font-size: 0.9rem; margin-bottom: 0.3rem;"),
                  p(textOutput("package_decrease_display", inline = TRUE),
                    style = "font-size: 1.2rem; font-weight: 700; color: #C0392B;")
                ),

                div(
                  p(strong("Effective After Tax (Annual):"),
                    style = "font-size: 0.9rem; margin-bottom: 0.3rem;"),
                  p(textOutput("effective_decrease_display", inline = TRUE),
                    style = "font-size: 1.2rem; font-weight: 700; color: #C0392B;")
                ),

                div(
                  p(strong("Effective After Tax (Monthly):"),
                    style = "font-size: 0.9rem; margin-bottom: 0.3rem;"),
                  p(textOutput("effective_monthly_decrease_display", inline = TRUE),
                    style = "font-size: 1.2rem; font-weight: 700; color: #C0392B;")
                )
              ),
              hr(),
              p(class = "text-muted small",
                "Package Decrease = Current Total Package - Startup Total Package"),
              p(class = "text-muted small",
                "Effective Decrease = Current Take-Home - Startup Take-Home (accounts for tax savings from lower salary)")
            )
          )
        )
      )
    ),

    nav_panel(
      "Questions for Discussion",
      style = "overflow-y: auto; max-height: calc(100vh - 150px);",
      card(
        card_header("Equity Compensation Discussion Guide"),
        markdown("
# Key Questions for Discussion

## 1. My Equity Package

**What I'm getting:**
- Equity % (fully-diluted basis)?
- Type of equity (options, direct shares, RSUs)?
- Vesting schedule?
- What happens if I leave before demo/fundraise?

**For the calculator:**
- Market analysis valuation range?
- Expected valuation after fundraise (end of year)?

---

## 2. Founder & Cap Table Structure

**Before I join:**
- How will founder equity be split?
- Will founders vest their shares?
- What % is set aside for employee option pool?
- Current cap table: Founders + Uni (5%) + Option Pool + Other?

**After fundraise:**
- Expected dilution from seed round?
- How much are you planning to raise?
- Will option pool be expanded before or after raise?

---

## 3. Seed Funders & Funding

**Current seed funders:**
- Who are they and how much committed?
- Any terms agreed (valuation cap, discount rate)?
- Convertible notes or SAFE agreements?

**Bootstrap projects:**
- What other revenue is coming in?
- How does this affect runway?
- When do you absolutely need the seed round closed?

**My role in fundraising:**
- What demo needs to be built by year end?
- Is seed round contingent on demo completion?
- What's plan B if fundraise doesn't happen?

---

## 4. University Relationship

**Known: Uni has 5% equity**

**Need to know:**
- Any special rights (board seat, approval rights, veto power)?
- IP licensing: royalties or restrictions?
- Can Uni block future funding or acquisition?

---

## 5. Exit & Liquidation

**Seed round terms:**
- What liquidation preference will seed investors get?
- Participating or non-participating preferred?

**Exit scenarios:**
- Target exit valuation?
- Expected timeline to exit (5-7 years)?
- Acquisition vs IPO path?

**Example calculation:**
- If company exits at $30M, $50M, $100M, what would my equity be worth?
- After: debt repayment + seed investor preferences

---

## 6. My Protection & Terms

**Vesting:**
- Standard 4 year / 1 year cliff acceptable?
- What if demo doesn't lead to fundraise - do I stay on?

**Acceleration:**
- Single or double-trigger on acquisition?
- What % accelerates?

**Exercise window:**
- 90 days standard or longer?

**Cliff:**
- Can we discuss 6-month cliff given I'm critical for demo/fundraise?

---

## 7. Documentation

**Need to see:**
- Market analysis / valuation report
- Term sheets or LOIs from seed funders
- Current cap table
- University spinoff agreement (equity and IP terms)

---

## 8. For the Calculator

**What valuation should I use?**
- Market analysis valuation range (low/mid/high)?
- Expected post-seed valuation?

**Once I have:**
- Market analysis
- Seed funder terms
- Cap table structure
- Answers to above questions

**I can model scenarios to determine what salary/equity split makes sense for me.**
        ")
      )
    ),

    nav_panel(
      "Assumptions",
      card(
        card_header("How This Calculator Works"),
        markdown("
### Break-Even Equity Formula

The calculator determines how much equity you need to be fairly compensated for a total package reduction:

```
# Calculate total packages (including super at 12%)
current_total = current_base_salary + (current_base_salary × 0.12)
new_total = new_base_salary + (new_base_salary × 0.12)

# Calculate sacrifice and required equity
annual_sacrifice = current_total - new_total
total_sacrifice = annual_sacrifice × vesting_period
equity_value_needed = total_sacrifice × risk_multiplier
break_even_equity_pct = (equity_value_needed / valuation) × 100
```

### Key Assumptions

1. **Superannuation**: Both current and new packages include 12% super on base salary (2024-25 Australian standard).

2. **Tax Calculation**: Uses 2024-25 Australian tax brackets plus 2% Medicare Levy. Tax is calculated on base salary only (super is not taxed as income).

3. **Risk Multiplier**: Equity is riskier than cash compensation. A 4x multiplier means you need $4 of equity value to compensate for $1 of package sacrifice.

4. **Salary Growth (Both Roles)**: Both current role and startup base salaries (and super) grow with CPI each year.

5. **Equity Realization**: Equity value is realized only at the end of the vesting period (exit/liquidity event).

6. **Current Valuation**: The break-even equity is calculated based on current company valuation. Future dilution is not factored in.

### Take-Home Pay

The dashboard shows monthly take-home pay after Australian income tax (including Medicare Levy) to help you understand the real cash flow impact. This is calculated on base salary only - super contributions are not included in take-home as they go to your super fund.

### Important Considerations

- **Dilution**: Your equity percentage will likely decrease with future funding rounds
- **Exit Timeline**: Liquidity may take longer than the vesting period
- **Tax Treatment**: Equity may have different tax implications than salary
- **Super Impact**: Lower base salary means lower super contributions, which compounds over time
- **Tax Brackets**: Moving to a lower salary may put you in a lower tax bracket, partially offsetting the reduction
        ")
      )
    )
  )
)

# Define server logic
server <- function(input, output, session) {

  # Reset button functionality
  observeEvent(input$reset, {
    updateNumericInput(session, "current_salary", value = 203000)
    updateNumericInput(session, "company_valuation", value = 10)
    updateNumericInput(session, "vesting_period", value = 4)
    updateNumericInput(session, "annual_cpi", value = 3.5)
    updateSliderInput(session, "salary_percentage", value = 80)
    updateNumericInput(session, "risk_multiplier", value = 4)
  })

  # Reactive calculations
  calculations <- reactive({
    # Validate inputs - return NULL if any required input is missing or invalid
    req(input$current_salary, input$company_valuation, input$vesting_period,
        input$annual_cpi, input$salary_percentage, input$risk_multiplier)

    # Additional validation for finite numbers
    if (!is.finite(input$current_salary) || !is.finite(input$company_valuation) ||
        !is.finite(input$vesting_period) || !is.finite(input$annual_cpi) ||
        !is.finite(input$salary_percentage) || !is.finite(input$risk_multiplier)) {
      return(NULL)
    }

    # Validate ranges
    if (input$current_salary <= 0 || input$company_valuation <= 0 ||
        input$vesting_period <= 0 || input$risk_multiplier <= 0) {
      return(NULL)
    }

    # Convert valuation from millions to dollars
    valuation <- input$company_valuation * 1000000

    # Superannuation calculations (12% of base salary)
    current_super <- input$current_salary * 0.12
    current_total_package <- input$current_salary + current_super

    # Calculate new base salary and super
    new_base_salary <- input$current_salary * (input$salary_percentage / 100)
    new_super <- new_base_salary * 0.12
    new_total_package <- new_base_salary + new_super

    # Tax calculations (on base salary, not including super)
    current_tax <- calculate_aus_tax(input$current_salary)
    new_tax <- calculate_aus_tax(new_base_salary)

    # Take-home pay (base salary minus tax)
    current_takehome <- input$current_salary - current_tax
    new_takehome <- new_base_salary - new_tax

    # Monthly take-home
    current_monthly <- current_takehome / 12
    new_monthly <- new_takehome / 12
    monthly_difference <- current_monthly - new_monthly

    # Calculate annual sacrifice (total package difference)
    annual_sacrifice <- current_total_package - new_total_package

    # Calculate total sacrifice over vesting period
    total_sacrifice <- annual_sacrifice * input$vesting_period

    # Calculate equity value needed
    equity_value_needed <- total_sacrifice * input$risk_multiplier

    # Calculate break-even equity percentage
    breakeven_equity_pct <- (equity_value_needed / valuation) * 100

    # Generate year-by-year data
    years <- seq(0, input$vesting_period, by = 1)

    # Current role: total package with CPI increases
    current_role_annual <- numeric(length(years))
    current_role_cumulative <- numeric(length(years))
    current_role_annual[1] <- 0  # Year 0
    current_role_cumulative[1] <- 0

    for (i in 2:length(years)) {
      year_num <- i - 1
      base_this_year <- input$current_salary * ((1 + input$annual_cpi/100) ^ (year_num - 1))
      super_this_year <- base_this_year * 0.12
      total_this_year <- base_this_year + super_this_year
      current_role_annual[i] <- total_this_year
      current_role_cumulative[i] <- current_role_cumulative[i-1] + total_this_year
    }

    # Startup: total package with CPI increases + equity at end
    startup_annual <- numeric(length(years))
    startup_cumulative <- numeric(length(years))
    startup_annual[1] <- 0  # Year 0
    startup_cumulative[1] <- 0

    for (i in 2:length(years)) {
      year_num <- i - 1
      startup_base_this_year <- new_base_salary * ((1 + input$annual_cpi/100) ^ (year_num - 1))
      startup_super_this_year <- startup_base_this_year * 0.12
      startup_total_this_year <- startup_base_this_year + startup_super_this_year
      startup_annual[i] <- startup_total_this_year
      startup_cumulative[i] <- startup_cumulative[i-1] + startup_total_this_year

      # Add equity value in final year
      if (years[i] == input$vesting_period) {
        startup_cumulative[i] <- startup_cumulative[i] + equity_value_needed
      }
    }

    # Calculate difference
    difference <- startup_cumulative - current_role_cumulative

    # Create data frame
    comparison_df <- data.frame(
      Year = years,
      Current_Role_Annual = current_role_annual,
      Current_Role_Cumulative = current_role_cumulative,
      Startup_Annual = startup_annual,
      Startup_Cumulative = startup_cumulative,
      Difference = difference
    )

    list(
      # Current role details
      current_base = input$current_salary,
      current_super = current_super,
      current_total = current_total_package,
      current_tax = current_tax,
      current_takehome = current_takehome,
      current_monthly = current_monthly,

      # New role details
      new_base = new_base_salary,
      new_super = new_super,
      new_total = new_total_package,
      new_tax = new_tax,
      new_takehome = new_takehome,
      new_monthly = new_monthly,

      # Differences
      monthly_difference = monthly_difference,
      annual_sacrifice = annual_sacrifice,
      breakeven_equity_pct = breakeven_equity_pct,
      equity_value_needed = equity_value_needed,

      # Comparison data
      comparison_df = comparison_df
    )
  })

  # Current role outputs
  output$current_base_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    dollar(calc$current_base, accuracy = 1)
  })

  output$current_super_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    dollar(calc$current_super, accuracy = 1)
  })

  output$current_total_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    dollar(calc$current_total, accuracy = 1)
  })

  output$current_tax_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    dollar(calc$current_tax, accuracy = 1)
  })

  output$current_takehome_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    dollar(calc$current_takehome, accuracy = 1)
  })

  output$current_monthly_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    dollar(calc$current_monthly, accuracy = 1)
  })

  # New role outputs
  output$new_base_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    dollar(calc$new_base, accuracy = 1)
  })

  output$new_super_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    dollar(calc$new_super, accuracy = 1)
  })

  output$new_total_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    dollar(calc$new_total, accuracy = 1)
  })

  output$new_tax_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    dollar(calc$new_tax, accuracy = 1)
  })

  output$new_takehome_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    dollar(calc$new_takehome, accuracy = 1)
  })

  output$new_monthly_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    dollar(calc$new_monthly, accuracy = 1)
  })

  # Package decrease outputs
  output$package_decrease_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    dollar(calc$annual_sacrifice, accuracy = 1)
  })

  output$effective_decrease_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    effective_decrease <- calc$current_takehome - calc$new_takehome
    dollar(effective_decrease, accuracy = 1)
  })

  output$effective_monthly_decrease_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    effective_decrease_monthly <- (calc$current_takehome - calc$new_takehome) / 12
    dollar(effective_decrease_monthly, accuracy = 1)
  })

  # Value box outputs
  output$monthly_difference_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    dollar(calc$monthly_difference, accuracy = 1)
  })

  output$annual_sacrifice_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    dollar(calc$annual_sacrifice, accuracy = 1)
  })

  output$breakeven_equity_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    sprintf("%.2f%%", calc$breakeven_equity_pct)
  })

  output$equity_value_display <- renderText({
    calc <- calculations()
    if (is.null(calc)) return("--")
    dollar(calc$equity_value_needed, accuracy = 1)
  })

  # Comparison chart
  output$comparison_chart <- renderPlotly({
    calc <- calculations()
    if (is.null(calc)) {
      # Return empty plot with message
      return(plot_ly() %>%
        layout(
          xaxis = list(visible = FALSE),
          yaxis = list(visible = FALSE),
          annotations = list(
            text = "Enter valid inputs to see comparison",
            xref = "paper",
            yref = "paper",
            x = 0.5,
            y = 0.5,
            showarrow = FALSE,
            font = list(size = 16, color = "#999")
          )
        ))
    }

    df <- calc$comparison_df

    # Remove year 0 for plotting
    df <- df[df$Year > 0, ]

    fig <- plot_ly() %>%
      add_trace(
        data = df,
        x = ~Year,
        y = ~Current_Role_Cumulative,
        type = 'scatter',
        mode = 'lines+markers',
        name = 'Current Role (package + super, with CPI increases)',
        line = list(color = '#3498DB', width = 3),
        marker = list(size = 8),
        hovertemplate = paste(
          '<b>Year %{x}</b><br>',
          'Total Package Cumulative: %{y:$,.0f}<br>',
          '<extra></extra>'
        )
      ) %>%
      add_trace(
        data = df,
        x = ~Year,
        y = ~Startup_Cumulative,
        type = 'scatter',
        mode = 'lines+markers',
        name = 'Startup (package + super, with CPI + equity at exit)',
        line = list(color = '#27AE60', width = 3, dash = 'dash'),
        marker = list(size = 8),
        hovertemplate = paste(
          '<b>Year %{x}</b><br>',
          'Total Package Cumulative: %{y:$,.0f}<br>',
          '<extra></extra>'
        )
      ) %>%
      layout(
        xaxis = list(
          title = "Years",
          gridcolor = '#E5E5E5',
          tickmode = 'linear',
          dtick = 1
        ),
        yaxis = list(
          title = "Cumulative Compensation ($)",
          gridcolor = '#E5E5E5',
          tickformat = '$,.0f'
        ),
        hovermode = 'x unified',
        legend = list(
          x = 0.05,
          y = 0.95,
          bgcolor = 'rgba(255, 255, 255, 0.8)',
          bordercolor = '#CCCCCC',
          borderwidth = 1,
          font = list(size = 11)
        ),
        plot_bgcolor = '#FAFAFA',
        paper_bgcolor = 'white',
        margin = list(l = 60, r = 20, t = 20, b = 50),
        font = list(size = 11)
      )

    fig
  })

  # Comparison table
  output$comparison_table <- renderDT({
    calc <- calculations()
    if (is.null(calc)) {
      # Return empty data frame with message
      return(datatable(
        data.frame(Message = "Enter valid inputs to see breakdown"),
        options = list(dom = 't', ordering = FALSE),
        rownames = FALSE
      ))
    }

    df <- calc$comparison_df

    # Remove year 0 for table
    df <- df[df$Year > 0, ]

    # Format for display
    display_df <- data.frame(
      Year = df$Year,
      "Current Package (Annual)" = dollar(df$Current_Role_Annual, accuracy = 1),
      "Current Cumulative" = dollar(df$Current_Role_Cumulative, accuracy = 1),
      "Startup Package (Annual)" = dollar(df$Startup_Annual, accuracy = 1),
      "Startup Cumulative" = dollar(df$Startup_Cumulative, accuracy = 1),
      "Difference" = dollar(df$Difference, accuracy = 1),
      check.names = FALSE
    )

    # Add note for final year
    final_year_idx <- nrow(display_df)
    display_df[final_year_idx, "Startup Cumulative"] <- paste0(
      display_df[final_year_idx, "Startup Cumulative"],
      " *"
    )

    datatable(
      display_df,
      options = list(
        pageLength = 15,
        dom = 't',
        ordering = FALSE
      ),
      rownames = FALSE,
      caption = htmltools::tags$caption(
        style = 'caption-side: bottom; text-align: left; font-size: 90%; margin-top: 10px;',
        '* Includes equity value realized at exit'
      )
    ) %>%
      formatStyle(
        'Difference',
        backgroundColor = styleInterval(
          cuts = c(0),
          values = c('#ffcccc', '#ccffcc')
        )
      ) %>%
      formatStyle(
        columns = final_year_idx,
        target = 'row',
        backgroundColor = '#ffffcc'
      )
  })
}

# Run the application
shinyApp(ui = ui, server = server)
