extensions[profiler]
globals [
  ; GENERAL]
MW-block-res
MW-block-com
MW-block-price-com
MW-block-price-res
electricity-price
avg-electricity-price
kwh-kW
NY-tax-incentive
federal-itc-incentive
installed-pv
MW-block-available
adder-available
VDER-exp-rate
CBC-charge
density
CO2-kWh-avg-em
CO2-kWh-solar-pv
CO2-kWh-solar-cs
second-block-com
second-block-res
second-block-adder

strat-intv1
effect-intv2-trust
effect-intv3-trust
effect-elec-price
fac-eff-elec-price
effect-elec-price-stress
fac-observability
fac-eff-trust-others
fac-spend-rpv
init-be-time

discount-rate
MW-mult
; CS
avg-cs-size
avg-cs-cost-kW
avg-cs-benf-kW
cs-adder-block
cs-adder-price
counter-strt-develop
cs-size
potential
pot-benefits
pot-costs
pot-profit
]
breed [households household]
breed [developers developer]
breed [solar-projects solar-project]

households-own [
; GENERAL
switched-pv
wanting-rooftop-pv
start-prod-elec
counter-checking
max-counter-checking
MW-block-used
signed-to-csp
able-to-cs
wanting-cs
own-needs
own-usage
own-prod
PV-kW-price
prod-csp
no-more-cs
#-other-pvs
pvs-t-1
emissions

; hh constraints
age
gender
education
education-kn
income
financial-stress
retired
no-of-adults
no-of-children
summer-el-bills
winter-el-bills
sq-ft
years-exp-to-rem
no-of-power-out

; DEMOGRAPHICS & HOUSE CHARACTERISTICS
has-rooftop?
kW-installable
init-savings
savings

; personal dispositions
pers-norms
awareness-of-conseq
rogers-value
cns
cijm
knowledge-level

; external influences
observability
pv-marketing-aware
trust-pv
trust-others

; updateable beliefs/attitudes
pers-benf
env-benf
riskiness
exp-concerns
pv-will-improve
trialability
normative-beliefs
home-unsuitable
might-move

intent

; FINANCES
project-costs
project-costs-2
project-fin
electricity-bill
exp-benf
max-be-time
list-max-be

NPV
cash-flow
NPV-list
net-metering
VDER
CBC
]
developers-own [
capacity
]

to setup
  clear-all
  setup-globals
  setup-developers
  setup-households
  reset-ticks
end

to setup-globals
  set MW-mult 1
  set MW-block-res MW-block-init-kW-res
  set MW-block-com MW-block-init-kW-com
  set cs-adder-block CS-adder-block-init-kW
  set second-block-com false
  set second-block-res false
  set second-block-adder false
  set electricity-price 0.224                       ; price per kWh in NY : https://www.nyserda.ny.gov/Researchers-and-Policymakers/Energy-Prices/Electricity/Monthly-Avg-Electricity-Residential
  set avg-electricity-price 0.187                   ; average price over the last 5 years: https://www.nyserda.ny.gov/Researchers-and-Policymakers/Energy-Prices/Electricity/Monthly-Avg-Electricity-Residential
  set kWh-kW 978                                   ; kWh averagely generated per kW RPV installed, treshold in NY anually is 978kWh/kW :https://sunroof.withgoogle.com/data-explorer/place/ChIJqaUj8fBLzEwRZ5UY3sHGz90/#?overlay=flux
  set CO2-kWh-avg-em 0.53 * 490 +  0.218 * 12 +  0.272 * 48 ; EIA; energy sources used https://www.eia.gov/state/print.php?sid=NY
  set CO2-kWh-solar-pv 41                          ; IPCC; CO2 per energy source :https://www.ipcc.ch/site/assets/uploads/2018/02/ipcc_wg3_ar5_annex-iii.pdf#page=7
  set CO2-kWh-solar-cs 48
  ifelse region = "ConEd"                  ; population dense area
    [ set MW-block-price-res 0.2 * 1000 * MW-mult     ; https://www.nyserda.ny.gov/All-Programs/NY-Sun/Contractors/Dashboards-and-incentives/ConEd-Dashboard, price per kW
      set MW-block-price-com 1 * 1000 * MW-mult
      set density 0.70                     ; pop density determines the amount of roofs available
      set avg-cs-cost-kW random-normal (1.64 * 1.5 * 1000) 200  ; avg costs for a communtiy solar project per kW
      set avg-cs-benf-kW random-normal (1.64 * 1.5 * 1000) 200  ; avg benefits for a community solar project per kW
      set avg-cs-size 115
      set cs-adder-price 0.2 * 1000 * MW-mult     ; adder level is currently 0.2 $/Watt :https://www.nyserda.ny.gov/community-adder
       if intv3 = true [
        ifelse intv2 = true [
        set CBC-charge 0.545]
        [set CBC-charge 1.09]]            ; CBC-charges from : https://www.solarreviews.com/blog/new-york-changes-net-metering-vder
      ]
      [ifelse region = "Upstate"           ; non-dense area
      [set MW-block-price-res 0.4 * 1000 * MW-mult   ; https://www.nyserda.ny.gov/upstate-dashboard, price per kW
       set MW-block-price-com 0.12 * 1000 * MW-mult
       set density 0.30
       set avg-cs-cost-kW random-normal (1.64 * 1000) 100       ; avg costs for a communtiy solar project per kW
       set avg-cs-benf-kW random-normal (1.64 * 1000) 100       ; avg benefits for a community solar project per kW
       set avg-cs-size 230
       set cs-adder-price 0.07 * 1000 * MW-mult     ; adder level is currently 0.7 $/Watt :https://www.nyserda.ny.gov/community-adder
       if intv3 = true [
        ifelse intv2 = true[
        set CBC-charge 0.4]
        [ set CBC-charge 0.8]]
       ]
      [set MW-block-price-res 0 * 1000    ; LIPA currently has no MW-block incentive
       set density 0.50               ; CHANGE LATER TO BE DEPENDENT THE ARE
       set avg-cs-size 200            ; average size in kW of the projects https://www.ysgsolar.com/sites/default/files/nyseia_community_solar_report_-_april_2021.pdf
      if intv3 = true [
        ifelse intv2 = true[
        set CBC-charge 0.46]
        [ set CBC-charge 0.92]]
       ]
  ]
  set NY-tax-incentive 0.25           ; https://www.tax.ny.gov/pit/credits/solar_energy_system_equipment_credit.htm
  set federal-itc-incentive 0.26      ; https://www.energy.gov/eere/solar/articles/residential-and-commercial-itc-factsheets


  set fac-eff-elec-price 10
  set fac-observability 0.05
  set fac-eff-trust-others 0.5
  set fac-spend-rpv 4
  set init-be-time 10

; inervention values
  set strat-intv1 1
  set effect-intv2-trust 0.05
  set effect-intv3-trust 0.05
  set VDER-exp-rate 0.8

end

to setup-developers
  create-developers #-developers [
    set shape "building institution"
    set color blue
    set capacity 100
    setxy  who * 2 0
  ]
end

to setup-households
  create-households #-households [
    set shape "dot"
    move-to one-of patches
    set init-savings random-exponential 16690 / fac-spend-rpv       ; https://www.prnewswire.com/news-releases/average-american-has-17-135-in-a-savings-or-investment-account-according-to-new-state-by-state-survey-findings-from-slickdeals-301171993.html
    set own-usage (random-normal 973 200) * 3 / 13   ; average kWh use per week : https://www.energysage.com/local-data/electricity-cost/ny/
    set own-needs own-usage / kWh-kW * 52
    set emissions own-usage * CO2-kWh-avg-em         ; weekly emmissions
    set counter-checking random 4
    set no-more-cs false
    set MW-block-used false
    set start-prod-elec false

    create-links-with n-of ((random 3) + 1) other households

; set personal norms
    set pers-norms random-normal 0 1
    set awareness-of-conseq random-normal 0 1

; set innovativeness, consumer novelty seeking (CNS)
;    set rogers-value random 101                     ; 0 to 100 percent
;    if rogers-value <= 3 [                          ; innovators: sets a adoptionlikeness linked to the rogers-value, basically drawing a random value from a range given by teh rogers value
;      set cns (random 4 + 97) / 100 * 5 ]
;    if (rogers-value > 3 and rogers-value <= 16) [  ; early adopters
;      set cns (random 14 + 84) / 100 * 5]
;    if (rogers-value > 16 and rogers-value <= 50) [ ; early majority
;      set cns (random 35 + 50) / 100 * 5]
;    if (rogers-value > 50 and rogers-value <= 84) [ ; late majority
;      set cns (random 35 + 16) / 100 * 5]
;    if rogers-value > 84 [                          ; laggards
;      set cns (random 17) / 100 * 5]
    set cns random-normal 0 1

; set influence of others, consumer independent judgmenent making
    set cijm random-normal 0 1

; creating initial awareness, only pv-others will be influenced while running the model
    set pv-marketing-aware random-normal 0 1
    set observability random-normal 0 1

; creating trust levels
    set trust-pv random-normal 0 1
    set trust-others random-normal 0 1

    if intv2 = true
      [ifelse trust-pv > 0 [
        set trust-pv trust-pv * (1 - effect-intv2-trust)]
       [set trust-pv trust-pv * (1 + effect-intv2-trust)]
    ]
    if intv3 = true
      [ifelse trust-pv > 0 [
        set trust-pv trust-pv * (1 - effect-intv3-trust)]
       [set trust-pv trust-pv * (1 + effect-intv3-trust)]
        ]

; hh constraints
    set age random-normal 0 1
    set gender random 2
    set education random-normal 0 1
    set income random-normal 0 1
    set financial-stress random-normal 0 1

;    ; update financial stress
;    if e-price-effect = true [
;    let increase-price  ((electricity-price - avg-electricity-price ) / avg-electricity-price )
;    if increase-price > 0 [
;      ifelse financial-stress > 0 [
;      set financial-stress financial-stress * ((increase-price * effect-elec-price-stress) + 1)]
;    [ set financial-stress financial-stress + (increase-price * effect-elec-price-stress) ]
;    ]
;  ]

    set retired random 2
    set no-of-adults random-normal 0 1
    set no-of-children random-normal 0 1
    set summer-el-bills random-normal 0 1
    set winter-el-bills random-normal 0 1
    set sq-ft random-normal 0 1
    set years-exp-to-rem random-normal 0 1
    set no-of-power-out random-normal 0 1

; sets amount of info a hh gathers, affects checking if solar is an option                  ; education inlfuences knowledge phase (DOI)
    if education >= 1 [                               ; 4 levels of education: Bachelors or higher, High school ; some college or associates ; less than high school
      set knowledge-level precision (random-float 0.03 + 0.97) 4
      set max-counter-checking 4]
    if (education >= 0 and education <= 1) [
      set knowledge-level precision (random-float 0.14 + 0.84) 4
      set max-counter-checking 8]
    if (education >= -1 and education <= 0) [
      set knowledge-level precision (random-float 0.35 + 0.50) 4
      set max-counter-checking 16]
    if (education <= -1) [
      set knowledge-level precision (random-float 0.35 + 0.16) 4
      set max-counter-checking 24]


; creating hh with or without roof available
    ifelse (random-float 1 >= density )             ; determine whether a households has a roof randomly assigned dependent on the pop-density of the area
      [set color green
       set has-rooftop? true
       set switched-pv false
       set kW-installable 1 + round (random-exponential 7)   ;Google sunroof project
       if kw-installable < 5 [                           ; average price per kW installed in NY https://www.solarreviews.com/solar-panel-cost/new-york#brand
          set PV-kW-price 3 * 1000]
       if (kw-installable >= 5 and kw-installable < 9)[
          set PV-kW-price 2.9 * 1000]
       if (kw-installable >= 9 )[
          set PV-kW-price 2.7 * 1000]
       if region = "ConEd" [
          set PV-kW-price PV-kW-price * 1.1 ]
       set max-be-time init-be-time + random 7                ; maximum break even time households allow in years.
       set discount-rate 0.05
       set wanting-cs false
       set signed-to-csp false
        set wanting-rooftop-pv false]
      [set color yellow
       set has-rooftop? false
       set wanting-cs false
       set signed-to-csp false]
  ]
end

to go
  if ticks = 520                                        ; 15 years
  [ stop ]
  update-globals
  if ticks < 520 [
  ask households[
    update-finances
    ifelse has-rooftop? = true [
      if signed-to-csp = false and switched-pv = false[
        update-awareness] ]
      [if signed-to-csp = false [
      update-awareness] ]
    ifelse intv2 = true
     [set VDER true
      set net-metering false]
     [set net-metering true
      set VDER false]
    ifelse intv3 = true
      [set CBC true]
      [set CBC false]
  ]
  ]
  if csp-true = true [
    cs-calculate-financials]
  tick
end

to update-globals
set avg-cs-cost-kW avg-cs-cost-kW * (0.5 ^ ( 1 / 520 ))  ;https://www.energy.gov/eere/solar/articles/2030-solar-cost-targets
set avg-cs-benf-kW avg-cs-benf-kW * (0.6 ^ ( 1 / 520 ))
if second-block-com = false [                   ; prices received from https://www.youtube.com/watch?v=rRRIP8KKq1o
    if MW-block-com <= 0 [
    set second-block-com true
    if  region = "ConEd" [
    set MW-block-com 300
    set MW-block-price-com 1.05 * 1000 * MW-mult ]
    if region = "Upstate"[
     set MW-block-com 800
     set MW-block-price-com 0.17 * 1000 * MW-mult ]
  ]
  ]
  if second-block-res = false [
  if MW-block-res <= 0 [
    set second-block-res true
    if  region = "ConEd" [
    set MW-block-res 150
    set MW-block-price-res 0.15 * 1000 * MW-mult ]
    if region = "Upstate"[
     set MW-block-res 800
     set MW-block-price-res 0 * 1000 * MW-mult ]
  ]
  ]
  if second-block-adder = false [
   if cs-adder-block <= 0 [
    set second-block-adder true
    if  region = "ConEd" [
    set cs-adder-block 0.7 * 300
    set cs-adder-price 0.1 * 1000 * MW-mult ]
    if region = "Upstate"[
     set cs-adder-block 0.7 * 800
     set cs-adder-price 0.07 * 1000 * MW-mult ]
  ]
  ]
end

to update-finances
  ifelse ticks = 0 [
    set savings init-savings]
  [set savings (init-savings + (ticks * 2)) - (ln(0.015 * ticks )* sin (ticks) * 10) ]  ; create a growing savings value for households
  set electricity-bill own-usage * electricity-price
  set PV-kW-price PV-kW-price * (0.5 ^ ( 1 / 520 ))

  if signed-to-csp = true[
     set electricity-bill (prod-csp * electricity-price * 0.9 )
     ;print electricity-bill
     ;print who
  ]

  if start-prod-elec = true [
    set emissions (own-usage * CO2-kWh-avg-em) + (own-prod * CO2-kWh-solar-pv)
    ifelse VDER = true [
;      print electricity-bill
      set electricity-bill electricity-bill - (exp-benf / 52)
      ;print electricity-bill
    ]
     [let NEt-met-value 2
      set electricity-bill electricity-bill - (exp-benf / 52)]
   ifelse project-fin = true [
          set project-costs-2 project-costs
          set project-fin false]
    [ set project-costs-2 0]
  ]

  ifelse e-price-effect = true [
    let increase-price  ((electricity-price - avg-electricity-price ) / avg-electricity-price )
    if increase-price > 0
      [set effect-elec-price fac-eff-elec-price * increase-price] ]
   [set effect-elec-price 0]
end

to update-awareness
  set counter-checking counter-checking + 1
  if counter-checking > max-counter-checking [

  ;observability (check other houses with RPV)
  set #-other-pvs sum [count other households-here with [switched-pv = true]] of households in-radius 5

  if #-other-pvs > pvs-t-1 [
    ;print "agent:" print who
    ;print "single-agent-test observability (before): " print observability
    set observability observability + fac-observability
    ;print "agent:" print who
    ;print "single-agent-test observability (after): " print observability
    ]
  set pvs-t-1 #-other-pvs

  ;trust
   let relevant-neighbors link-neighbors with [switched-pv = true]
     if count relevant-neighbors > 0 [
      if mean [trust-pv] of relevant-neighbors > ([trust-pv] of self)[
        if cijm > 0 [
          set trust-pv trust-pv + (((mean [trust-pv] of relevant-neighbors) - [trust-pv] of self) * fac-eff-trust-others)    ; updates the trust of the relevant agent to half of what others belief
        ]
      ]
    ]
  ifelse has-rooftop? = true [
      if signed-to-csp = false and switched-pv = false[
        update-attitudes] ]
      [if signed-to-csp = false [
      update-attitudes] ]
  set counter-checking 0
  ]

end

to update-attitudes
  ifelse hh-constraints = true [
  ;determining personal benf
  set pers-benf ( 0.35 * pers-norms + 0.08 * awareness-of-conseq + 0.06 * cns  - 0.03 * cijm + 0.03 * observability - 0.03 * pv-marketing-aware + 0.23 * trust-pv + 0.03 * trust-others
      - 0.18 * age + 0.01 * gender - 0.06 * education - 0.08 * income + 0.07 * financial-stress + 0.03 * retired - 0.01 * no-of-adults  + 0.01 * no-of-children + 0.1 * summer-el-bills
      + 0.02 * winter-el-bills - 0.05 * sq-ft + 0.01 * years-exp-to-rem + 0.06 * no-of-power-out) + (effect-elec-price)

  ;env. benf
  set env-benf ( 0.42 * pers-norms + 0.34 * awareness-of-conseq + 0.02 * cns  + 0.01 * cijm - 0.01 * observability + 0.01 * pv-marketing-aware + 0.15 * trust-pv + 0.05 * trust-others
      - 0.14 * age - 0.03 * gender + 0.05 * education - 0.04 * income + 0.02 * financial-stress + 0.02 * retired + 0.04 * no-of-adults  + 0.0 * no-of-children + 0.05 * summer-el-bills
      - 0.01 * winter-el-bills - 0.05 * sq-ft - 0.02 * years-exp-to-rem + 0.03 * no-of-power-out)

  ; riskiness
  set riskiness ( -0.02 * pers-norms - 0.06 * awareness-of-conseq - 0.04 * cns  - 0.04 * cijm - 0.09 * observability + 0.01 * pv-marketing-aware - 0.24 * trust-pv - 0.01 * trust-others
      - 0.05 * age - 0.03 * gender + 0.07 * education - 0.04 * income + 0.03 * financial-stress + 0.01 * retired - 0.01 * no-of-adults  + 0.01 * no-of-children + 0.03 * summer-el-bills
      - 0.02 * winter-el-bills + 0.01 * sq-ft + 0.02 * years-exp-to-rem - 0.02 * no-of-power-out)

  ;exp-concerns
  set exp-concerns ( - 0.01 * pers-norms + 0.02 * awareness-of-conseq - 0.03 * cns  - 0.05 * cijm - 0.13 * observability + 0.04 * pv-marketing-aware - 0.21 * trust-pv + 0.1 * trust-others
      - 0.07 * age + 0.04 * gender - 0.01 * education - 0.12 * income + 0.24 * financial-stress - 0.04  * retired - 0.05 * no-of-adults  - 0.03 * no-of-children + 0.3 * summer-el-bills
      + 0.03 * winter-el-bills - 0.02 * sq-ft + 0.02 * years-exp-to-rem - 0.04 * no-of-power-out)

  ; pv-will improve
  set pv-will-improve ( -0.03 * pers-norms + 0.04 * awareness-of-conseq + 0.04 * cns  - 0.03 * cijm + 0.01 * observability + 0.03 * pv-marketing-aware - 0.08 * trust-pv + 0.05 * trust-others
      + 0.05 * age - 0.04 * gender + 0.07 * education + 0.01 * income + 0.03 * financial-stress - 0.01 * retired - 0.03 * no-of-adults  - 0.02 * no-of-children + 0.05 * summer-el-bills
      - 0.06 * winter-el-bills + 0.01 * sq-ft + 0.02 * years-exp-to-rem - 0.05 * no-of-power-out)


  ;trialability
  set trialability ( 0.01 * pers-norms + 0.02 * awareness-of-conseq + 0.03 * cns  - 0.16 * cijm - 0.02 * observability - 0.0 * pv-marketing-aware - 0.16 * trust-pv + 0.17 * trust-others
      + 0.02 * age - 0.01 * gender + 0.07 * education - 0.08 * income + 0.0 * financial-stress - 0.01 * retired - 0.05 * no-of-adults  - 0.05 * no-of-children + 0.07 * summer-el-bills
      - 0.07 * winter-el-bills + 0.07 * sq-ft + 0.02 * years-exp-to-rem + 0.01 * no-of-power-out)

  ;normative-beliefs
  set normative-beliefs ( 0.18 * pers-norms + 0.09 * awareness-of-conseq + 0.13 * cns  + 0.06 * cijm + 0.05 * observability - 0.01 * pv-marketing-aware + 0.17 * trust-pv + 0.11 * trust-others
      - 0.11 * age - 0.05 * gender + 0.05 * education - 0.02 * income - 0.04 * financial-stress + 0.03 * retired + 0.01 * no-of-adults  + 0.04 * no-of-children - 0.1 * summer-el-bills
      + 0.06  * winter-el-bills - 0.01 * sq-ft - 0.02 * years-exp-to-rem + 0.02 * no-of-power-out)

  ;home-unsuitable
  set home-unsuitable ( - 0.02 * pers-norms - 0.04 * awareness-of-conseq - 0.01 * cns  - 0.06 * cijm - 0.08 * observability - 0.08 * pv-marketing-aware -  0.01 * trust-pv - 0.08 * trust-others
      + 0.02 * age + 0.02 * gender + 0.04 * education + 0.03 * income + 0.01 * financial-stress + 0.09 * retired - 0.0 * no-of-adults  - 0.02 * no-of-children + 0.1 * summer-el-bills
      + 0.02 * winter-el-bills - 0.05 * sq-ft + 0.01 * years-exp-to-rem - 0.06 * no-of-power-out)

  ;might - move
  set might-move ( 0.01 * pers-norms - 0.09 * awareness-of-conseq - 0.13 * cns  - 0.01 * cijm - 0.01 * observability - 0.02 * pv-marketing-aware - 0.12 * trust-pv - 0.01 * trust-others
      + 0.04 * age + 0.01 * gender + 0.02 * education - 0.02 * income + 0.05 * financial-stress + 0.05 * retired - 0.03 * no-of-adults  - 0.08 * no-of-children + 0.05 * summer-el-bills
      - 0.07 * winter-el-bills + 0.07 * sq-ft - 0.41 * years-exp-to-rem + 0.06 * no-of-power-out)]
  [
    ;determining personal benf
  set pers-benf ( 0.35 * pers-norms + 0.08 * awareness-of-conseq + 0.06 * cns  - 0.03 * cijm + 0.03 * observability - 0.03 * pv-marketing-aware + 0.23 * trust-pv + 0.03 * trust-others) + (effect-elec-price)

  ;env. benf
  set env-benf ( 0.42 * pers-norms + 0.34 * awareness-of-conseq + 0.02 * cns  + 0.01 * cijm - 0.01 * observability + 0.01 * pv-marketing-aware + 0.15 * trust-pv + 0.05 * trust-others)

  ; riskiness
  set riskiness ( -0.02 * pers-norms - 0.06 * awareness-of-conseq - 0.04 * cns  - 0.04 * cijm - 0.09 * observability + 0.01 * pv-marketing-aware - 0.24 * trust-pv - 0.01 * trust-others)

  ;exp-concerns
  set exp-concerns ( - 0.01 * pers-norms + 0.02 * awareness-of-conseq - 0.03 * cns  - 0.05 * cijm - 0.13 * observability + 0.04 * pv-marketing-aware - 0.21 * trust-pv + 0.1 * trust-others)

  ; pv-will improve
  set pv-will-improve ( -0.03 * pers-norms + 0.04 * awareness-of-conseq + 0.04 * cns  - 0.03 * cijm + 0.01 * observability + 0.03 * pv-marketing-aware - 0.08 * trust-pv + 0.05 * trust-others)

  ;trialability
  set trialability ( 0.01 * pers-norms + 0.02 * awareness-of-conseq + 0.03 * cns  - 0.16 * cijm - 0.02 * observability - 0.0 * pv-marketing-aware - 0.16 * trust-pv + 0.17 * trust-others)

  ;normative-beliefs
  set normative-beliefs ( 0.18 * pers-norms + 0.09 * awareness-of-conseq + 0.13 * cns  + 0.06 * cijm + 0.05 * observability - 0.01 * pv-marketing-aware + 0.17 * trust-pv + 0.11 * trust-others)

  ;home-unsuitable
  set home-unsuitable ( - 0.02 * pers-norms - 0.04 * awareness-of-conseq - 0.01 * cns  - 0.06 * cijm - 0.08 * observability - 0.08 * pv-marketing-aware -  0.01 * trust-pv - 0.08 * trust-others)

  ;might - move
  set might-move ( 0.01 * pers-norms - 0.09 * awareness-of-conseq - 0.13 * cns  - 0.01 * cijm - 0.01 * observability - 0.02 * pv-marketing-aware - 0.12 * trust-pv - 0.01 * trust-others)
  ]
  update-intent
end

to update-intent
  ifelse hh-constraints = true[
  set intent ( 0.29 * pers-benf - 0.02 * env-benf - 0.02 * riskiness -  0.09 * exp-concerns - 0.02 * pv-will-improve + 0.08 * trialability + 0.1 * normative-beliefs + 0.13 * home-unsuitable
     - 0.04 * might-move + 0.5 * pers-norms - 0.08 * awareness-of-conseq + 0.14 * cns + 0.08 * cijm + 0.05 * observability - 0.02 * pv-marketing-aware + 0.14 * trust-pv - 0.02 * trust-others
      - 0.11 * age - 0.011 * gender + 0.02 * education - 0.04 * income - 0.01 * financial-stress + 0.0 * retired - 0.02 * no-of-adults + 0.0 * no-of-children + 0.05 * summer-el-bills
      - 0.0 * winter-el-bills + 0.0 * sq-ft + 0.03 * years-exp-to-rem - 0.01 * no-of-power-out)]
  [set intent ( 0.29 * pers-benf - 0.02 * env-benf - 0.02 * riskiness -  0.09 * exp-concerns - 0.02 * pv-will-improve + 0.08 * trialability + 0.1 * normative-beliefs + 0.13 * home-unsuitable
     - 0.04 * might-move + 0.5 * pers-norms - 0.08 * awareness-of-conseq + 0.14 * cns + 0.08 * cijm + 0.05 * observability - 0.02 * pv-marketing-aware + 0.14 * trust-pv - 0.02 * trust-others)
  ]
  update-behaviour
end

to update-behaviour
  if intent > 0 [
    ifelse has-rooftop? = true
     [check-finances]
     [set wanting-cs true
       check-community-solar
      ]
  ]
end

to check-finances
  ;print "check fin"
  set project-costs kW-installable * PV-kW-price
  let NY-tax-benf 0                                                        ; calculate the tax break received from the NY-tax incentive
  ifelse (project-costs * (1 - NY-tax-incentive)) >= 5000 [
    set NY-tax-benf 5000]
  [set NY-tax-benf project-costs * (NY-tax-incentive) ]
   let FED-tax-benf project-costs * (federal-itc-incentive)                ; calculate the tax break received from the Federal-tax incentive

   let MW-benf 0
   if MW-block-res >= 0 [
    set MW-benf kW-installable * MW-block-price-res
    ;print MW-benf
  ]
   set project-costs project-costs - NY-tax-benf - FED-tax-benf - MW-benf   ; both taxes are reducted from the costs after the MW-block rebate (https://www.ny-engineers.com/blog/solar-panel-installation-in-new-york)

  ; calculate expected profits with both net-metering and VDER
  if net-metering = true and CBC = false [
    set exp-benf (kW-installable * kWh-KW * electricity-price)  ; expected yearly benefit
    set list-max-be (range 0 (max-be-time + 1))
    set NPV-list []
    foreach list-max-be [x -> set cash-flow ((exp-benf) / ((1 + discount-rate ) ^ x))
                              set NPV-list insert-item 0 NPV-list round cash-flow]
   set NPV sum NPV-list
   ;print NPV
   set NPV NPV - project-costs
   ;print NPV
  ]

  if net-metering = true and CBC = true [
    set exp-benf (kW-installable * kWh-kW * electricity-price) - (kW-installable * CBC-charge * 12)  ; expected yearly benefit
    set list-max-be (range 0 (max-be-time + 1))
    set NPV-list []
    foreach list-max-be [x -> set cash-flow ((exp-benf) / ((1 + discount-rate ) ^ x))
                              set NPV-list insert-item 0 NPV-list round cash-flow]
   set NPV sum NPV-list
   set NPV NPV - project-costs
  ]

  if VDER = true and CBC = false [
    set exp-benf (kW-installable * kWh-kW * electricity-price) * VDER-exp-rate ; expected yearly benefit
    set list-max-be (range 0 (max-be-time + 1))
    set NPV-list []
    foreach list-max-be [x -> set cash-flow ((exp-benf) / ((1 + discount-rate ) ^ x))
                              set NPV-list insert-item 0 NPV-list round cash-flow]
    set NPV sum NPV-list
    set NPV NPV - project-costs
  ]

  if VDER = true and CBC = true [
    set exp-benf ((kW-installable * kWh-kW * electricity-price) * VDER-exp-rate) - (kW-installable * CBC-charge * 12) ; expected yearly benefit
    set list-max-be (range 0 (max-be-time + 1))
    set NPV-list []
    foreach list-max-be [x -> set cash-flow ((exp-benf) / ((1 + discount-rate ) ^ x))
                              set NPV-list insert-item 0 NPV-list round cash-flow]
    set NPV sum NPV-list
   set NPV NPV - project-costs
   ; if NPV > 0 []
  ]

  ifelse (savings >= project-costs  and NPV >= 1 )[
    set wanting-rooftop-pv true
    if MW-block-res >= 0 [
     set MW-block-used true
     ]
    switch-or-not-pv
   ; print "wanting rooftop"
    ]
   [set wanting-cs true
    set wanting-rooftop-pv false
    set switched-pv false
    check-community-solar
    ;print "rooftop checking solar"
  ]
end

to update-perceived-control
  ;unsuitable home
  ;might move
  ;money
end

to check-community-solar
  if csp-true = true [
  if any? developers with [capacity >= ([own-needs] of myself) ] [
    set able-to-cs true
    switch-to-cs]
  ]
end

to switch-or-not-pv
  if wanting-rooftop-pv = true
       [ if MW-block-used = true [
         set MW-block-res (MW-block-res - kW-installable)
         ; "used block"
        ]
         set installed-pv installed-pv + kW-installable
         set own-prod (kW-installable * (kWh-kW / 52))              ; weekly own production
         set own-usage own-usage - own-prod
         set wanting-rooftop-pv false
         set switched-pv true
         set wanting-cs false
         set able-to-cs false
         set start-prod-elec true
         set project-fin true
  ]
end

to switch-to-cs

  if any? developers with [capacity >= [own-needs ] of myself] [
        let relevant-developer one-of developers with [capacity >= ([own-needs] of myself)]
        ask relevant-developer
        [set capacity capacity - [own-needs] of myself]
         set wanting-cs false
         set able-to-cs false
         set no-more-cs false
         set wanting-rooftop-pv false
         set signed-to-csp true
         ;print emissions
         set emissions (own-usage) * CO2-kWh-solar-cs
         ;print own-usage
         set prod-csp own-usage
         set own-usage 0
         ;print prod-csp
         ;print who
  ]
end

;;;; DEVELOPERS ACTIVITY
to cs-calculate-financials
set counter-strt-develop counter-strt-develop + 1
if counter-strt-develop >= 13 - random 2 [                      ; every 1 tick equals 1 week
    set potential (sum [own-needs] of households with [wanting-cs = true]) - (sum [capacity] of other developers)
set cs-size random-normal avg-cs-size (avg-cs-size / 8)

ifelse potential > cs-size [
set pot-benefits cs-size * avg-cs-benf-kW]
[ set pot-benefits potential * avg-cs-benf-kW ]

if intv1 = true [                              ; this means that the intervention in which the utility is allowed first pick of the CS's produced green electricity
   set pot-benefits pot-benefits * (1 - (ticks / 520 ) * strat-intv1 * 0.1) ]

let MW-benf 0
ifelse cs-size <= MW-block-com [
  set MW-benf cs-size * MW-block-price-com
  set MW-block-available true]
 [set MW-benf MW-block-com * MW-block-price-com
  set MW-block-available false ]


let cs-adder-benf 0
ifelse cs-size <= cs-adder-block [
  set cs-adder-benf cs-size * cs-adder-price
  set adder-available true]
  [set cs-adder-benf cs-adder-block * cs-adder-price
   set adder-available false ]

set pot-costs (cs-size * avg-cs-cost-kW) - MW-benf - cs-adder-benf

set pot-profit (pot-benefits - pot-costs)

if pot-profit >= 10 [
  create-developers 1 [
         set shape "building institution"
         set color blue
         set capacity cs-size
         setxy  who * 2 0
        ifelse MW-block-available = true [
         set MW-block-com MW-block-com - capacity]
        [set MW-block-com MW-block-com - MW-block-com]
        ifelse adder-available  = true [
         set cs-adder-block cs-adder-block - capacity]
        [ set cs-adder-block cs-adder-block - cs-adder-block]
  ]
 ]
set counter-strt-develop 0]
end
@#$#@#$#@
GRAPHICS-WINDOW
269
10
758
500
-1
-1
14.6
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
7
10
74
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
8
48
71
81
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
5
283
143
328
region
region
"ConEd" "Upstate" "LIPA"
0

SLIDER
8
211
141
244
#-households
#-households
0
2000
2000.0
1
1
NIL
HORIZONTAL

MONITOR
179
326
267
371
NIL
MW-block-res
17
1
11

BUTTON
7
85
70
118
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
780
470
863
515
installed RPV
installed-pv
17
1
11

MONITOR
780
425
924
470
potential installable RPV
sum [ kW-installable ]  of households
17
1
11

SLIDER
8
246
143
279
#-developers
#-developers
0
5
0.0
1
1
NIL
HORIZONTAL

SLIDER
6
331
153
364
MW-block-init-kW-res
MW-block-init-kW-res
0
400
150.0
50
1
NIL
HORIZONTAL

PLOT
784
10
984
160
Capacity of developers
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [capacity] of developers"

PLOT
809
531
1034
681
Savings of households
NIL
NIL
0.0
10.0
0.0
20.0
true
true
"set-plot-x-range 0 round (max [init-savings] of households)\nset-histogram-num-bars count households" ""
PENS
"Savings" 1.0 1 -5298144 true "" "if ticks > 0 [histogram [savings] of households ]"

MONITOR
783
228
882
273
Hh, roof, signed
count households with [has-rooftop? = true ] with [signed-to-csp = true ]
17
1
11

MONITOR
990
230
1112
275
Hh, no roof, signed
count households with [has-rooftop? = false ] with [signed-to-csp = true ]
17
1
11

MONITOR
784
377
888
422
Hh switched to pv
count households with [has-rooftop? = true ] with [switched-pv = true]
17
1
11

MONITOR
991
107
1121
152
Capactity of developers
round sum [capacity] of developers
17
1
11

MONITOR
982
10
1063
55
# developers
count developers
17
1
11

MONITOR
993
59
1136
104
MW-block used developers
count developers with [MW-block-available = true]
17
1
11

MONITOR
1068
10
1181
55
Potential CS in kW
round potential
17
1
11

MONITOR
992
330
1169
375
Hh, no roof, not-signed, wanting
count households with [has-rooftop? = false ] with [wanting-cs = true]
17
1
11

MONITOR
991
279
1201
324
Hh, no roof, not-signed, not wanting
count households with [has-rooftop? = false ] with [wanting-cs = false] with [signed-to-csp = false]
17
1
11

MONITOR
990
180
1111
225
Total: hh, no rooftop
count households with [ has-rooftop? = false]
17
1
11

MONITOR
784
329
945
374
Hh, roof, not-signed, wanting
count households with [has-rooftop? = true ] with [wanting-cs = true] with [switched-pv = false] with [signed-to-csp = false]
17
1
11

MONITOR
783
179
900
224
Total: hh with rooftop
count households with [has-rooftop? = true]
17
1
11

MONITOR
783
279
981
324
Hh, roof, not-signed, not-wanting
count households with [has-rooftop? = true ] with [wanting-cs = false] with [signed-to-csp = false] with [switched-pv = false]
17
1
11

TEXTBOX
801
164
951
182
Households with rooftops
11
0.0
1

TEXTBOX
992
164
1170
182
Households without rooftop\n
11
0.0
1

MONITOR
178
418
262
463
CS-adder block
round cs-adder-block
17
1
11

SWITCH
92
10
182
43
intv1
intv1
1
1
-1000

SWITCH
91
47
181
80
intv2
intv2
1
1
-1000

SWITCH
92
84
182
117
intv3
intv3
1
1
-1000

PLOT
1247
178
1447
328
intent of households
NIL
NIL
-5.0
5.0
0.0
15.0
false
false
"set-plot-x-range -5 5\n\nset-histogram-num-bars count households" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks > 0 [histogram [intent] of households ]"

SWITCH
7
126
122
159
hh-constraints
hh-constraints
0
1
-1000

PLOT
471
529
645
656
kw-installable of HH
NIL
NIL
0.0
30.0
2.0
30.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [kw-installable] of households with [has-rooftop? = true]"

MONITOR
1187
10
1240
55
sanity
round sum [own-needs] of households with [wanting-cs = true]
17
1
11

MONITOR
904
179
958
224
sanity
count households with [has-rooftop? = true ] with [signed-to-csp = true ] + count households with [has-rooftop? = true ] with [wanting-cs = false] with [signed-to-csp = false] with [switched-pv = false] + count households with [has-rooftop? = true ] with [wanting-cs = true] with [switched-pv = false] with [signed-to-csp = false] + count households with [has-rooftop? = true ] with [switched-pv = true]
17
1
11

MONITOR
1117
181
1167
226
sanity
count households with [has-rooftop? = false ] with [signed-to-csp = true ] + count households with [has-rooftop? = false ] with [wanting-cs = false] with [signed-to-csp = false] + count households with [has-rooftop? = false ] with [wanting-cs = true] with [signed-to-csp = false ]+ count households with [has-rooftop? = false] with [no-more-cs = true]
17
1
11

MONITOR
865
472
922
517
sanity
sum [kw-installable] of households with [switched-pv = true]
17
1
11

MONITOR
651
530
769
575
median kw-installable
median [kw-installable] of households with [has-rooftop? = true]
17
1
11

SLIDER
7
375
156
408
MW-block-init-kW-com
MW-block-init-kW-com
0
400
120.0
50
1
NIL
HORIZONTAL

MONITOR
176
373
269
418
NIL
MW-block-com
17
1
11

SLIDER
6
420
159
453
CS-adder-block-init-kW
CS-adder-block-init-kW
200
2000
1000.0
200
1
NIL
HORIZONTAL

MONITOR
652
581
749
626
avg project-cost
round (mean [project-costs] of households)
17
1
11

MONITOR
653
628
753
673
avg savings hh
round (mean [savings] of households)
17
1
11

PLOT
1214
351
1504
561
#-rpv and csp
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"RPV" 1.0 0 -4079321 true "" "plot count households with [ start-prod-elec = true]"
"CSP" 1.0 0 -13345367 true "" "plot count households with [signed-to-csp = true]"

SWITCH
124
127
235
160
e-price-effect
e-price-effect
1
1
-1000

MONITOR
1491
218
1571
263
median intent
median [intent] of households
17
1
11

MONITOR
236
535
445
580
NIL
mean [project-costs] of households
17
1
11

MONITOR
235
634
392
679
NIL
mean [npv] of households
17
1
11

MONITOR
238
582
388
627
NIL
max [npv] of households
17
1
11

SWITCH
8
169
112
202
csp-true
csp-true
0
1
-1000

BUTTON
18
481
89
514
profiler
setup                  ;; set up the model\nprofiler:start         ;; start profiling\nrepeat 400 [ go ]       ;; run something you want to measure\nprofiler:stop          ;; stop profiling\nprint profiler:report  ;; view the results\nprofiler:reset         ;; clear the data
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1247
10
1538
160
Potential profits for developers
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot  pot-profit"

MONITOR
1041
437
1111
482
kpi5
count households with [has-rooftop? = true] with [project-costs > 0] with [savings > project-costs] with [signed-to-csp = False]
17
1
11

MONITOR
1046
489
1103
534
kpi5.2
count households with [signed-to-csp = true]
17
1
11

MONITOR
1142
585
1485
630
NIL
count households with [NPV > 0] with [has-rooftop? = true]
17
1
11

MONITOR
1125
652
1553
697
NIL
count households with [savings > project-costs] with [has-rooftop? = true]
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

building institution
false
0
Rectangle -7500403 true true 0 60 300 270
Rectangle -16777216 true false 130 196 168 256
Rectangle -16777216 false false 0 255 300 270
Polygon -7500403 true true 0 60 150 15 300 60
Polygon -16777216 false false 0 60 150 15 300 60
Circle -1 true false 135 26 30
Circle -16777216 false false 135 25 30
Rectangle -16777216 false false 0 60 300 75
Rectangle -16777216 false false 218 75 255 90
Rectangle -16777216 false false 218 240 255 255
Rectangle -16777216 false false 224 90 249 240
Rectangle -16777216 false false 45 75 82 90
Rectangle -16777216 false false 45 240 82 255
Rectangle -16777216 false false 51 90 76 240
Rectangle -16777216 false false 90 240 127 255
Rectangle -16777216 false false 90 75 127 90
Rectangle -16777216 false false 96 90 121 240
Rectangle -16777216 false false 179 90 204 240
Rectangle -16777216 false false 173 75 210 90
Rectangle -16777216 false false 173 240 210 255
Rectangle -16777216 false false 269 90 294 240
Rectangle -16777216 false false 263 75 300 90
Rectangle -16777216 false false 263 240 300 255
Rectangle -16777216 false false 0 240 37 255
Rectangle -16777216 false false 6 90 31 240
Rectangle -16777216 false false 0 75 37 90
Line -16777216 false 112 260 184 260
Line -16777216 false 105 265 196 265

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment2" repetitions="4" runMetricsEveryStep="true">
    <setup>set-up</setup>
    <go>go</go>
    <metric>mean [electricity-bill] of households</metric>
    <metric>mean [project-costs-2] of households</metric>
    <metric>mean [own-usage] of households</metric>
    <metric>mean [own-prod] of households</metric>
    <metric>mean [emissions] of households</metric>
    <metric>[switched-pv] of households</metric>
    <metric>[signed-to-csp] of households</metric>
    <enumeratedValueSet variable="intv1">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv2">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="region">
      <value value="&quot;ConEd&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-developers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-res">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-com">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv3">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment3" repetitions="10" runMetricsEveryStep="true">
    <setup>set-up</setup>
    <go>go</go>
    <metric>sum [electricity-bill] of households</metric>
    <metric>sum [project-costs-2] of households</metric>
    <metric>sum [own-usage] of households</metric>
    <metric>sum [own-prod] of households</metric>
    <metric>sum [prod-csp] of households</metric>
    <metric>sum [emissions] of households</metric>
    <metric>count households with [switched-pv = true]</metric>
    <metric>count households with [signed-to-csp = true]</metric>
    <enumeratedValueSet variable="intv1">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv2">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv3">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="region">
      <value value="&quot;ConEd&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-developers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-res">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-com">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="effect-intv1">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="VDER-exp-rate">
      <value value="0.8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment4" repetitions="10" runMetricsEveryStep="true">
    <setup>set-up</setup>
    <go>go</go>
    <metric>sum [electricity-bill] of households</metric>
    <metric>sum [project-costs-2] of households</metric>
    <metric>sum [own-usage] of households</metric>
    <metric>sum [own-prod] of households</metric>
    <metric>sum [prod-csp] of households</metric>
    <metric>sum [emissions] of households</metric>
    <metric>count households with [switched-pv = true]</metric>
    <metric>count households with [signed-to-csp = true]</metric>
    <enumeratedValueSet variable="intv1">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv2">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv3">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="region">
      <value value="&quot;ConEd&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-developers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-households">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-res">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-com">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="effect-intv1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="VDER-exp-rate">
      <value value="0"/>
      <value value="0.4"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="e-price-effect">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment_csp_false" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [electricity-bill] of households</metric>
    <metric>sum [project-costs-2] of households</metric>
    <metric>sum [own-usage] of households</metric>
    <metric>sum [own-prod] of households</metric>
    <metric>sum [prod-csp] of households</metric>
    <metric>sum [emissions] of households</metric>
    <metric>count households with [switched-pv = true]</metric>
    <metric>count households with [signed-to-csp = true]</metric>
    <metric>count households with [able-to-cs = true]</metric>
    <metric>count households with [NPV &gt; 0] with [has-rooftop? = true]</metric>
    <metric>count households with [savings &gt; project-costs] with [has-rooftop? = true]</metric>
    <metric>mean [age] of households</metric>
    <metric>mean [income] of households</metric>
    <metric>mean [education] of households</metric>
    <metric>mean [savings] of households</metric>
    <metric>count developers</metric>
    <metric>pot-profit</metric>
    <enumeratedValueSet variable="intv1">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv2">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv3">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="region">
      <value value="&quot;ConEd&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-developers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-households">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-res">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-com">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="e-price-effect">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csp-true">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="VDER-exp-rate">
      <value value="0.6"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strat-intv1">
      <value value="0.33"/>
      <value value="0.67"/>
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment_csp_true_intv1_false" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [electricity-bill] of households</metric>
    <metric>sum [project-costs-2] of households</metric>
    <metric>sum [own-usage] of households</metric>
    <metric>sum [own-prod] of households</metric>
    <metric>sum [prod-csp] of households</metric>
    <metric>sum [emissions] of households</metric>
    <metric>count households with [switched-pv = true]</metric>
    <metric>count households with [signed-to-csp = true]</metric>
    <metric>count households with [able-to-cs = true]</metric>
    <metric>count households with [NPV &gt; 0] with [has-rooftop? = true]</metric>
    <metric>count households with [savings &gt; project-costs] with [has-rooftop? = true]</metric>
    <metric>mean [age] of households</metric>
    <metric>mean [income] of households</metric>
    <metric>mean [education] of households</metric>
    <metric>mean [savings] of households</metric>
    <metric>count developers</metric>
    <metric>pot-profit</metric>
    <enumeratedValueSet variable="intv1">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv2">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv3">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="region">
      <value value="&quot;ConEd&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-developers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-households">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-res">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-com">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="e-price-effect">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csp-true">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="VDER-exp-rate">
      <value value="0.6"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strat-intv1">
      <value value="0.33"/>
      <value value="0.67"/>
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment_csp_true_intv1_true" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [electricity-bill] of households</metric>
    <metric>sum [project-costs-2] of households</metric>
    <metric>sum [own-usage] of households</metric>
    <metric>sum [own-prod] of households</metric>
    <metric>sum [prod-csp] of households</metric>
    <metric>sum [emissions] of households</metric>
    <metric>count households with [switched-pv = true]</metric>
    <metric>count households with [signed-to-csp = true]</metric>
    <metric>count households with [able-to-cs = true]</metric>
    <metric>count households with [NPV &gt; 0] with [has-rooftop? = true]</metric>
    <metric>count households with [savings &gt; project-costs] with [has-rooftop? = true]</metric>
    <metric>mean [age] of households</metric>
    <metric>mean [income] of households</metric>
    <metric>mean [education] of households</metric>
    <metric>mean [savings] of households</metric>
    <metric>count developers</metric>
    <metric>pot-profit</metric>
    <enumeratedValueSet variable="intv1">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv2">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv3">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="region">
      <value value="&quot;ConEd&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-developers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-households">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-res">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-com">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="e-price-effect">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csp-true">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="VDER-exp-rate">
      <value value="0.6"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strat-intv1">
      <value value="0.33"/>
      <value value="0.67"/>
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="VERIFICATION" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [electricity-bill] of households</metric>
    <metric>sum [project-costs-2] of households</metric>
    <metric>sum [own-usage] of households</metric>
    <metric>sum [own-prod] of households</metric>
    <metric>sum [prod-csp] of households</metric>
    <metric>sum [emissions] of households</metric>
    <metric>count households with [switched-pv = true]</metric>
    <metric>count households with [signed-to-csp = true]</metric>
    <metric>count households with [able-to-cs = true]</metric>
    <metric>count households with [NPV &gt; 0] with [has-rooftop? = true]</metric>
    <metric>count households with [savings &gt; project-costs] with [has-rooftop? = true]</metric>
    <metric>mean [age] of households</metric>
    <metric>mean [income] of households</metric>
    <metric>mean [education] of households</metric>
    <metric>mean [savings] of households</metric>
    <metric>count developers</metric>
    <metric>pot-profit</metric>
    <enumeratedValueSet variable="intv1">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv2">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv3">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="region">
      <value value="&quot;ConEd&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-developers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-households">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-res">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-com">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="e-price-effect">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csp-true">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="VERIFICATION2" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [electricity-bill] of households</metric>
    <metric>sum [project-costs-2] of households</metric>
    <metric>sum [own-usage] of households</metric>
    <metric>sum [own-prod] of households</metric>
    <metric>sum [prod-csp] of households</metric>
    <metric>sum [emissions] of households</metric>
    <metric>count households with [switched-pv = true]</metric>
    <metric>count households with [signed-to-csp = true]</metric>
    <metric>count households with [able-to-cs = true]</metric>
    <metric>count households with [NPV &gt; 0] with [has-rooftop? = true]</metric>
    <metric>count households with [savings &gt; project-costs] with [has-rooftop? = true]</metric>
    <metric>mean [age] of households</metric>
    <metric>mean [income] of households</metric>
    <metric>mean [education] of households</metric>
    <metric>mean [savings] of households</metric>
    <metric>count developers</metric>
    <metric>pot-profit</metric>
    <enumeratedValueSet variable="intv1">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv2">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv3">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="region">
      <value value="&quot;ConEd&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-developers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-households">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-res">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-com">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="e-price-effect">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csp-true">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="VERIFICATION3" repetitions="200" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [electricity-bill] of households</metric>
    <metric>sum [project-costs-2] of households</metric>
    <metric>sum [own-usage] of households</metric>
    <metric>sum [own-prod] of households</metric>
    <metric>sum [prod-csp] of households</metric>
    <metric>sum [emissions] of households</metric>
    <metric>count households with [switched-pv = true]</metric>
    <metric>count households with [signed-to-csp = true]</metric>
    <metric>count households with [able-to-cs = true]</metric>
    <metric>count households with [NPV &gt; 0] with [has-rooftop? = true]</metric>
    <metric>count households with [savings &gt; project-costs] with [has-rooftop? = true]</metric>
    <metric>mean [age] of households</metric>
    <metric>mean [income] of households</metric>
    <metric>mean [education] of households</metric>
    <metric>mean [savings] of households</metric>
    <metric>count developers</metric>
    <metric>pot-profit</metric>
    <enumeratedValueSet variable="intv1">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv2">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv3">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="region">
      <value value="&quot;ConEd&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-developers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-households">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-res">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-com">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="e-price-effect">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csp-true">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="VERIFICATION4" repetitions="500" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [electricity-bill] of households</metric>
    <metric>sum [project-costs-2] of households</metric>
    <metric>sum [own-usage] of households</metric>
    <metric>sum [own-prod] of households</metric>
    <metric>sum [prod-csp] of households</metric>
    <metric>sum [emissions] of households</metric>
    <metric>count households with [switched-pv = true]</metric>
    <metric>count households with [signed-to-csp = true]</metric>
    <metric>count households with [able-to-cs = true]</metric>
    <metric>count households with [NPV &gt; 0] with [has-rooftop? = true]</metric>
    <metric>count households with [savings &gt; project-costs] with [has-rooftop? = true]</metric>
    <metric>mean [age] of households</metric>
    <metric>mean [income] of households</metric>
    <metric>mean [education] of households</metric>
    <metric>mean [savings] of households</metric>
    <metric>count developers</metric>
    <metric>pot-profit</metric>
    <enumeratedValueSet variable="intv1">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv2">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intv3">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="region">
      <value value="&quot;ConEd&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-developers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-households">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-res">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MW-block-init-kW-com">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="e-price-effect">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csp-true">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
