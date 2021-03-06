;==================================================================================================================================
;Create 'agents' breed that represents male and female individuals ================================================================
;This definition of a new breed is technically not necessary, as it would also be possible to work with the standard turtle breed;=
;however, defining a new breed called 'agents' better aligns the model code with the model description ============================
;==================================================================================================================================
breed [agents agent]

;==================================================================================================================================
;Defines global variables =========================================================================================================
;The variables defined here can be accessed from anywhere in the model ============================================================
;==================================================================================================================================
globals
[
  interactants        ;which agents have been selected for interaction?
  interactant_i       ;who is interactant 1?
  interactant_j       ;who is interactant 2?
  supported_belief    ;auxiliary variable that stores information about the belief that has been supported by the interaction of interactant_i and interactant_j
  resource_data       ;external resource data on the education levels of the population
  resource_cohort     ;part of the external resource data that is relevant for the current simulation year
  power_data          ;external resource on the share of board members in the population
  power_cohort        ;part of the external power data that is relevant for the current simulation year
  year                ;current simulation year
  Ms_died             ;how many male agents have died in the current year and need to be replaced?
  Fs_died             ;how many female agents have died in the current year and need to be replaced?
  adults              ;which agents are older than A_i_adult?
  M_adults            ;which male agents are older than A_i_adult?
  F_adults            ;which female agents are older than A_i_adult?

  ;defines variables that provide information about model outcomes in each simulation step
  share_M_rich        ;share of male agents older than A_i_adult who have high resource level
  share_F_rich        ;share of female agents older than A_i_adult who have high resource level
  share_believe_M     ;share of agents older than A_i_adult who believe M
  share_believe_F     ;share of agents older than A_i_adult who believe F
  share_believe_O     ;share of agents older than A_i_adult who believe O
  share_M_power       ;share of male agents older than A_i_adult who have high power level
  share_F_power       ;share of female agents older than A_i_adult who have high power level
]

;==================================================================================================================================
;Defines agent-level variables ====================================================================================================
;The variables defined here are properties of the agents in the model =============================================================
;==================================================================================================================================
agents-own
[
  S_i                 ;agents' sex
  e_i                 ;agents' interaction memory
  B_i                 ;agents' status belief
  R_i                 ;agents' resource level
  A_i                 ;agents' age
  M_i                 ;agents' power level based on whether or not they are a directorial board member
]

;==================================================================================================================================
;Initializes the simulation run ===================================================================================================
;==================================================================================================================================
to setup
  __clear-all-and-reset-ticks
  do_read_input
  do_read_input2
  do_update_year
  do_get_cohort_data
  do_get_cohort_data2
  do_create_agents I_M I_F
  do_assign_initial_age
  do_identify_adults
  do_update_outcomes
  update-plots
end

;==================================================================================================================================
;The actual simulation procedure ==================================================================================================
;==================================================================================================================================
to go
  if year = Y_end [stop]

  do_update_year
  do_get_cohort_data
  do_get_cohort_data2
  do_identify_adults

  if count M_adults > 0 and count F_adults > 0
  [
    let interaction_counter 0

    while [interaction_counter < (count M_adults + count F_adults) ]
    [

      do_select_interactants
      do_interaction
      do_update_memory
      do_update_status_beliefs
      set interaction_counter interaction_counter + 1

    ]
  ]

  do_aging
  do_mortality
  do_create_agents Ms_died Fs_died

  do_update_outcomes
  tick
end

;==================================================================================================================================
;The different subroutines=====================================================================================================
;==================================================================================================================================

to do_read_input
  if model_type = "simulation"
  [
    file-open "DK_data_GET.txt"
    set resource_data file-read
    file-close
  ]
  if model_type = "sensitivity"
  [
  file-open "edu_sen.txt"
    set resource_data file-read
    file-close
  ]
end

to do_read_input2
  if intervention = "null"
  [
    file-open "power_data_null.txt"
    set power_data file-read
    file-close
  ]

  if intervention = "30/70"
  [
    file-open "30_70.txt"
    set power_data file-read
    file-close
  ]

  if intervention = "40/60"
  [
    file-open "40_60.txt"
    set power_data file-read
    file-close
  ]

  if intervention = "50/50"
  [
    file-open "50_50.txt"
    set power_data file-read
    file-close
  ]

  if intervention = "60/40"
  [
    file-open "60_40.txt"
    set power_data file-read
    file-close
  ]

  if intervention = "70/30"
  [
    file-open "70_30.txt"
    set power_data file-read
    file-close
  ]

  if intervention = "sensitivity analysis"
  [
    file-open "power_sensitivity.txt"
    set power_data file-read
    file-close
  ]

end


to do_update_year
  set year ticks + Y_start
end

to do_get_cohort_data
  ifelse year >= 1938 and year <= 2018
  [
    set resource_cohort filter [first ? = year] resource_data
  ]
  [
    ifelse year < 1938
    [
      set resource_cohort filter [first ? = 1938] resource_data
    ]
    [
      set resource_cohort filter [first ? = 2018] resource_data
    ]
  ]
end

to do_get_cohort_data2
  ifelse year >= 1938 and year < 1966
  [
    set power_cohort filter [first ? = 1938] power_data
  ]
  [
    set power_cohort filter [first ? = 1966] power_data
  ]
end

to do_create_agents [#M #F]
  create-agents #M
  [
    set S_i "M"
    set e_i []
    set B_i "O"
    set A_i 0
    ifelse random-float 1 < item 1 item 0 resource_cohort [set R_i "H"][set R_i "L"]
    ifelse random-float 1 < item 2 item 0 power_cohort [set M_i "H"][set M_i "L"]

    ;the assignment of visual and spatial properties  to agents is not necessary, but makes identification in the world view window easier
    setxy random-xcor random-ycor
    set color 8
    set shape "triangle"
    set size .7
  ]

  create-agents #F
  [
    set S_i "F"
    set e_i []
    set B_i "O"
    set A_i 0
    ifelse random-float 1 < item 2 item 0 resource_cohort [set R_i "H"][set R_i "L"]
    ifelse random-float 1 < item 1 item 0 power_cohort [set M_i "H"][set M_i "L"]

    ;the assignment of visual and spatial properties  to agents is not necessary, but makes identification in the world view window easier
    setxy random-xcor random-ycor
    set color 8
    set shape "circle"
    set size .7
  ]
end

to do_assign_initial_age
  ask agents
  [
    set A_i random (A_i_max + 1)
  ]
end

to do_aging
  ask agents
  [
    set A_i A_i + 1
  ]
end

to do_identify_adults
  set adults   agents with [A_i >= A_i_adult]
  set M_adults adults with [S_i = "M"]
  set F_adults adults with [S_i = "F"]
end

to do_update_outcomes
  set share_M_rich count M_adults with [R_i = "H"] / count M_adults
  set share_F_rich count F_adults with [R_i = "H"] / count F_adults
  set share_believe_M count adults with [B_i = "M"] / count adults
  set share_believe_F count adults with [B_i = "F"] / count adults
  set share_believe_O count adults with [B_i = "O"] / count adults
  set share_M_power count M_adults with [M_i = "H"] / count M_adults
  set share_F_power count F_adults with [M_i = "H"] / count F_adults
end

to do_select_interactants
  set interactant_i one-of M_adults
  set interactant_j one-of F_adults
  set interactants (turtle-set interactant_i interactant_j)
end

to do_interaction
  set supported_belief "NA"

  let P_i 0     ;what is the expectation standing of interactant_i?
  let P_j 0     ;what is the expectation standing of interactant_j?

  ;status beliefs affect interactions
  if [S_i] of interactant_i = [B_i] of interactant_i [set P_i P_i + 1]
  if [S_i] of interactant_i = [B_i] of interactant_j [set P_i P_i + 1]

  if [S_i] of interactant_j = [B_i] of interactant_i [set P_j P_j + 1]
  if [S_i] of interactant_j = [B_i] of interactant_j [set P_j P_j + 1]

  ;resources matter affect interactions
  if [R_i] of interactant_i = "H" and [R_i] of interactant_j = "L" [set P_i P_i + 2]
  if [R_i] of interactant_i = "L" and [R_i] of interactant_j = "H" [set P_j P_j + 2]

  ;power matters affect interactions
  if [M_i] of interactant_i = "H" and [M_i] of interactant_j = "L" [set P_i P_i + 4]
  if [M_i] of interactant_i = "L" and [M_i] of interactant_j = "H" [set P_j P_j + 4]

  if P_i > P_j [set supported_belief "M"]
  if P_i < P_j [set supported_belief "F"]
  if P_i = P_j [ifelse random-float 1 < .5 [set supported_belief "M"][set supported_belief "F"]]
end

to do_update_memory
  ask interactants
  [
    ifelse length e_i < E_remember
    [
      set e_i fput supported_belief e_i
    ]
    [
      set e_i butlast e_i
      set e_i fput supported_belief e_i
    ]
  ]
end

to do_update_status_beliefs
  ask interactants
  [
    let experience_M 0     ;how many experiences have supported the belief M?
    let experience_F 0     ;how many experiences have supported the belief F?

    foreach e_i
    [
      if ? = "M" [set experience_M experience_M + 1]
      if ? = "F" [set experience_F experience_F + 1]
    ]

    let dom "O"            ;which experience is dominant? If none is dominant, the default belief is O.
    if experience_M >  experience_F [set dom "M"]
    if experience_F >  experience_M [set dom "F"]

    set B_i dom

    if B_i = "M" [set color 95]
    if B_i = "O" [set color 8]
    if B_i = "F" [set color 15]
  ]
end

to do_mortality
 set Ms_died 0
 set Fs_died 0

 ask agents
 [
   if A_i >= A_i_max
   [
     ifelse S_i = "M"
     [
       set Ms_died Ms_died + 1
     ]
     [
       set Fs_died Fs_died + 1
     ]
     die
   ]
 ]
end
@#$#@#$#@
GRAPHICS-WINDOW
392
14
853
496
16
16
13.67
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
41
19
104
52
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
110
19
173
52
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

INPUTBOX
46
291
202
351
I_M
1000
1
0
Number

INPUTBOX
46
356
202
416
I_F
1000
1
0
Number

PLOT
867
66
1249
216
belief distribution
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"share believe F" 1.0 0 -2674135 true "" "if count agents > 0 [plot share_believe_F]"
"share believe M" 1.0 0 -13791810 true "" "if count agents > 0 [plot share_believe_M]"
"share believers O" 1.0 0 -3026479 true "" "if count agents > 0 [plot share_believe_O]"

PLOT
867
221
1226
371
resource distribution
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"share M rich" 1.0 0 -13791810 true "" "if count agents > 0 [plot share_M_rich]"
"share F rich" 1.0 0 -2674135 true "" "if count agents > 0 [plot share_F_rich]"

SLIDER
46
604
199
637
E_remember
E_remember
1
20
20
1
1
NIL
HORIZONTAL

MONITOR
866
14
923
59
NIL
year
17
1
11

INPUTBOX
44
171
199
231
Y_end
2050
1
0
Number

TEXTBOX
46
253
407
295
population parameters\n------------------------------------------------------------------------------------
11
0.0
1

TEXTBOX
44
565
419
600
interaction parameters\n------------------------------------------------------------------------------------
11
0.0
1

TEXTBOX
213
294
325
322
number of male agents
11
0.0
1

TEXTBOX
211
354
329
390
number of female agents
11
0.0
1

INPUTBOX
47
492
202
552
A_i_max
80
1
0
Number

TEXTBOX
211
490
329
532
maximum age (in years) that agents can reach
11
0.0
1

TEXTBOX
210
168
360
238
year until which simulation should run (for years >= 2020 the input data for 2020 will be used)
11
0.0
1

TEXTBOX
211
603
361
645
number of interactions that agents memorize (i.e. parameter E)
11
0.0
1

INPUTBOX
47
423
202
483
A_i_adult
16
1
0
Number

TEXTBOX
211
423
361
465
age (in years) from which on agents take part in interactions
11
0.0
1

INPUTBOX
44
106
199
166
Y_start
1938
1
0
Number

TEXTBOX
210
106
360
162
year in which the simulation should start (for years <= 1936 the input data for 1936 will be used)
11
0.0
1

TEXTBOX
44
68
385
110
simulation period\n------------------------------------------------------------------------------------
11
0.0
1

PLOT
869
384
1228
534
power distribution
NIL
NIL
0.0
10.0
0.0
0.1
true
true
"" ""
PENS
"share M power" 1.0 0 -13791810 true "" "if count agents > 0 [plot share_M_power]"
"share F power" 1.0 0 -2674135 true "" "if count agents > 0 [plot share_F_power]"

TEXTBOX
404
516
843
572
intervention size & sensitivity analysis\n-------------------------------------------------------------------------------------------------------------
11
0.0
1

CHOOSER
403
550
554
595
intervention
intervention
"null" "30/70" "40/60" "50/50" "60/40" "70/30" "sensitivity analysis"
0

CHOOSER
612
601
750
646
model_type
model_type
"simulation" "sensitivity"
1

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
NetLogo 5.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>year</metric>
    <metric>share_M_rich</metric>
    <metric>share_F_rich</metric>
    <metric>share_believe_M</metric>
    <metric>share_believe_F</metric>
    <metric>share_believe_O</metric>
    <enumeratedValueSet variable="Y_start">
      <value value="1986"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Y_end">
      <value value="2020"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="model_version">
      <value value="&quot;full&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A_i_adult">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A_i_max">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="E_remember">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="I_M">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="I_F">
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>year</metric>
    <metric>share_M_rich</metric>
    <metric>share_F_rich</metric>
    <metric>share_believe_M</metric>
    <metric>share_believe_F</metric>
    <metric>share_believe_O</metric>
    <metric>share_M_power</metric>
    <metric>share_F_power</metric>
    <enumeratedValueSet variable="Y_start">
      <value value="1938"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Y_end">
      <value value="2050"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A_i_adult">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A_i_max">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="E_remember">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="I_M">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="I_F">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intervention">
      <value value="&quot;null&quot;"/>
      <value value="&quot;30/70&quot;"/>
      <value value="&quot;40/60&quot;"/>
      <value value="&quot;50/50&quot;"/>
      <value value="&quot;60/40&quot;"/>
      <value value="&quot;70/30&quot;"/>
      <value value="&quot;sensitivity analysis&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="model_type">
      <value value="&quot;simulation&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="education sensitivity" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>year</metric>
    <metric>share_M_rich</metric>
    <metric>share_F_rich</metric>
    <metric>share_believe_M</metric>
    <metric>share_believe_F</metric>
    <metric>share_believe_O</metric>
    <metric>share_M_power</metric>
    <metric>share_F_power</metric>
    <enumeratedValueSet variable="Y_start">
      <value value="1938"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Y_end">
      <value value="2050"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A_i_adult">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A_i_max">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="E_remember">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="I_M">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="I_F">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intervention">
      <value value="&quot;null&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="model_type">
      <value value="&quot;sensitivity&quot;"/>
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
