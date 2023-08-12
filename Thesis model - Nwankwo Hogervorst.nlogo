globals [
  gender-divide
  political-affiliation-divide
  age-divide
  socio-economic-status-divide

  pro-nuclear-gender-male
  pro-nuclear-gender-female
  pro-nuclear-political-affiliation-left
  pro-nuclear-political-affiliation-right
  pro-nuclear-age-young
  pro-nuclear-age-old
  pro-nuclear-ses-low
  pro-nuclear-ses-high

  identities

  num-groups
  max-group-size

  decimals
  decimals-round
  distinct-opinions

  edge-margin
  person-size
  group-locations
]

turtles-own [
  opinion
  opinion-round

  gender
  socio-economic-status
  political-affiliation
  age

  dominant-identity
  salient-identity

  group-id
]

to setup
  clear-all
  initialize-country                                   ;; Germany or France
  set num-groups round (num-agents / avg-group-size)
  set decimals 9                                       ;; set the number of decimals of the opinions
  create-turtles num-agents [                          ;; create population
    give-social-identities                             ;; set gender, ses, political affiliation, and age (per individual)
    give-initial-opinion                               ;; set initial opinion toward nuclear energy
    set shape "person"
    set person-size (5 - 0.002 * num-agents)
    set size person-size
  ]
  layout-circle turtles 30
  set group-locations patches with [group-location?]
  create-opinion-plots
  reset-ticks
end

to go
  create-groups                               ;; individuals come together in social group
  ask group-locations [
    if ( count turtles-here > 1 ) [           ;; run only when there is more than 1 person in the group
      set-salient-identity                    ;; a social identity becomes salient
      discuss-and-update-opinion              ;; the topic of nuclear energy is discussed and afterwards people update their opinion
    ]
  ]
  ask turtles [ spread-out-horizontally ]     ;; to make all the agents visible on the display
  create-opinion-plots
  tick
  check-distinct-opinions
  if length distinct-opinions <= 2 [ stop ]   ;; if there are only 2 or less distinct opinions, stop running
end

to initialize-country
  if country = "Germany" [
    ;; population distribution in Germany
    set gender-divide 0.482                             ;; percentage of German population that is male
    set political-affiliation-divide 0.474
    set age-divide 0.345
    set socio-economic-status-divide 0.492
    ;; opinion distribution in Germany
    set pro-nuclear-gender-male 0.379                   ;; percentage of pro-nuclear men in German population
    set pro-nuclear-gender-female 0.304
    set pro-nuclear-political-affiliation-left 0.248
    set pro-nuclear-political-affiliation-right 0.414
    set pro-nuclear-age-young 0.283
    set pro-nuclear-age-old 0.373
    set pro-nuclear-ses-low 0.357
    set pro-nuclear-ses-high 0.323
  ]
  if country = "France" [
    ;; population distribution in France
    set gender-divide 0.475                              ;; percentage of French population that is male
    set political-affiliation-divide 0.311
    set age-divide 0.487
    set socio-economic-status-divide 0.5
    ;; opinion distribution in France
    set pro-nuclear-gender-male 0.83                     ;; percentage of pro-nuclear men in French population
    set pro-nuclear-gender-female 0.68
    set pro-nuclear-political-affiliation-left 0.572
    set pro-nuclear-political-affiliation-right 0.861
    set pro-nuclear-age-young 0.698
    set pro-nuclear-age-old 0.802
    set pro-nuclear-ses-low 0.72
    set pro-nuclear-ses-high 0.87
  ]
  ask patch (min-pxcor + max-pxcor / 8) (max-pycor - 1) [ set plabel country ]
end

to give-social-identities
  ;; select the social identities that will be considered in this run of the model
  set identities []
  if gender? [ set identities lput "gender" identities ]
  if political? [ set identities lput "political-affiliation" identities ]
  if age? [ set identities lput "age" identities ]
  if ses? [ set identities lput "socio-economic-status" identities ]

  ;; Give an individual their social identities, given the population distribution of the country
  if gender? [ ifelse random-float 1 < gender-divide  [set gender "male"] [set gender "female"]]
  if political? [ ifelse random-float 1 < political-affiliation-divide [set political-affiliation "left"] [set political-affiliation "right"]]
  if age? [ ifelse random-float 1 < age-divide [set age "young"] [set age "old"]]
  if ses? [ ifelse random-float 1 < socio-economic-status-divide [set socio-economic-status "low"] [set socio-economic-status "high"]]

  set dominant-identity one-of identities   ;; assign each person an identity they identify with most, that will determine their initial opinion
end

to give-initial-opinion
  let pro-nuclear-threshold 0   ;; this parameter will contain the percentage of people that are pro-nuclear within the dominant identity of the individual

  if dominant-identity = "gender" [
    ifelse gender = "male" [
      set pro-nuclear-threshold pro-nuclear-gender-male
    ] [
      set pro-nuclear-threshold pro-nuclear-gender-female
    ]
  ]
  if dominant-identity = "political-affiliation" [
    ifelse political-affiliation = "left" [
      set pro-nuclear-threshold pro-nuclear-political-affiliation-left
    ] [
      set pro-nuclear-threshold pro-nuclear-political-affiliation-right
    ]
  ]
  if dominant-identity = "age" [
    ifelse age = "young" [
      set pro-nuclear-threshold pro-nuclear-age-young
    ] [
      set pro-nuclear-threshold pro-nuclear-age-old
    ]
  ]
  if dominant-identity = "socio-economic-status" [
    ifelse socio-economic-status = "low" [
      set pro-nuclear-threshold pro-nuclear-ses-low
    ] [
      set pro-nuclear-threshold pro-nuclear-ses-high
    ]
  ]

  ifelse random-float 1 < pro-nuclear-threshold [   ;; set initial opinon, scale 0-1, completely anti (0) to completely pro (0.999999999)
    set opinion 0.5 + random-float 0.5              ;; the percentage of people that is pro-nuclear gets an opinion between 0.5-1
  ] [
    set opinion random-float 0.5                    ;; the percentage of people that is anti-nuclear gets an opinion between 0-0.5
  ]

  set opinion round( opinion * (10 ^ decimals) ) / (10 ^ decimals)
  set color ifelse-value (opinion < 0.5) [violet] [orange]   ;; anti-nuclear people are violet, pro-nuclear are orange
end

to-report group-location? ;; display-locations of the group
  ;; the origin (0,0) is the bottom left corner
  set edge-margin 5 ;; margin to keep the edges free
  ;; determine the distance between groups
  let group-interval floor ((2 * world-height - 4 * edge-margin) / num-groups)   ;; when an odd number of groups is given, 1 group will be added/subtracted, to be able to create 2 even columns
  report
    (pxcor = (min-pxcor + edge-margin)) or                                       ;; two columns of groups are created
    (pxcor = ((max-pxcor / 2) + edge-margin)) and
    (pycor > (min-pycor + edge-margin)) and                                      ;; between top and bottom edge
    (pycor < (max-pycor - edge-margin)) and
    (pycor mod group-interval = 0) and                                           ;; spread the groups evenly over the y-axis
    (floor (2 * (pycor - edge-margin) / group-interval) <= num-groups)           ;; to ensure that the empty space is not filled with extra groups
end

to create-opinion-plots
  create-opinion-plot ("public-opinion") (turtles)
  create-opinion-plot ("opinion-male") (turtles with [gender = "male"])
  create-opinion-plot ("opinion-female") (turtles with [gender = "female"])
  create-opinion-plot ("opinion-left-wing") (turtles with [political-affiliation = "left"])
  create-opinion-plot ("opinion-right-wing") (turtles with [political-affiliation = "right"])
  create-opinion-plot ("opinion-young") (turtles with [age = "young"])
  create-opinion-plot ("opinion-old") (turtles with [age = "old"])
  create-opinion-plot ("opinion-low-ses") (turtles with [socio-economic-status = "low"])
  create-opinion-plot ("opinion-high-ses") (turtles with [socio-economic-status = "high"])
end

to create-opinion-plot [title turtles-subset]
  set-current-plot title
  set-current-plot-pen "default"
  clear-plot
  set-plot-x-range 0 1
  ifelse title = "public-opinion" [set-plot-y-range 0 30] [set-plot-y-range 0 60]
  set-plot-pen-mode 1
  ifelse title = "public-opinion" [set-histogram-num-bars 9] [set-histogram-num-bars 2]
  histogram [opinion] of turtles-subset
end

to create-groups
  set max-group-size 9
  ask turtles [ setxy 0 (max-pycor / 2) ]           ;; first clear the field
  ask turtles [                                     ;; then go to new group location
    set group-id one-of group-locations
    move-to group-id
    while [count turtles-here > max-group-size] [   ;; do not exceed the maximum group size
     set group-id one-of group-locations
     move-to group-id
    ]
  ]
  update-labels   ;; display the country, agents in total, and number of groups
end

to update-labels
  ask group-locations [ set plabel count turtles-here ]
  ask patch (min-pxcor + max-pxcor / 8) (max-pycor - 1) [ set plabel country ]
  ask patch (min-pxcor + max-pxcor / 2) (max-pycor - 1) [ set plabel word ( sum [plabel] of group-locations ) " individuals " ]
  ask patch (max-pxcor - max-pxcor / 6) (max-pycor - 1) [ set plabel word ( count group-locations ) " groups " ]
end

to spread-out-horizontally ;; to line up the agents next to each other
  set heading 90
  fd 4
  while [any? other turtles-here] [
    ifelse [pxcor] of group-id = (min-pxcor + edge-margin) [           ;; left column of groups
      ifelse pxcor < ((max-pxcor / 2) - person-size - edge-margin) [
        fd (person-size / 2)
      ]
      [ ;; if too close to the right column, make a new row below
        set ycor ycor - person-size
        set xcor (min-pxcor + edge-margin)
        fd 4
      ]
    ]
    [                                                                  ;; right column of groups
      ifelse can-move? (person-size + edge-margin) [
        fd (person-size / 2)
      ]
      [ ;; if it does not fit on the display, make a new row below
        set ycor ycor - person-size
        set xcor ((max-pxcor / 2) + edge-margin)
        fd 4
      ]
    ]
  ]
end

to set-salient-identity ;; the salient identity is set to the most common dominant identity in the group
  let dom-ids [dominant-identity] of turtles-here
  let common-dom-ids modes dom-ids
  let most-common-dominant-identity one-of common-dom-ids
  ask turtles-here [ set salient-identity most-common-dominant-identity ]
end

to discuss-and-update-opinion
  let salient-identity-group ( one-of ([salient-identity] of turtles-here))

  let men turtles-here with [gender = "male"]
  let women turtles-here with [gender = "female"]
  let lefties turtles-here with [political-affiliation = "left"]
  let righties turtles-here with [political-affiliation = "right"]
  let youngsters turtles-here with [age = "young"]
  let oldies turtles-here with [age = "old"]
  let lowclass turtles-here with [socio-economic-status = "low"]
  let highclass turtles-here with [socio-economic-status = "high"]

  let zero-agents nobody      ;; the salient identity divides the group in two, group 0
  let one-agents nobody       ;; and group 1
  let zero-prototype nobody   ;; both groups will have a prototype, which is one of the agents whose dominant identity is the same as the salient identity of the group
  let one-prototype nobody

  if salient-identity-group = "gender" [
    set zero-agents men
    set one-agents women
    set zero-prototype ( one-of men with [dominant-identity = "gender"] )
    if zero-prototype = nobody [ set zero-prototype one-of men ]             ;; if there is no prototype, select a random agent in the group to be the prototype
    set one-prototype ( one-of women with [dominant-identity = "gender"] )
    if one-prototype = nobody [ set one-prototype one-of women ]
  ]
  if salient-identity-group = "political-affiliation" [
    set zero-agents lefties
    set one-agents righties
    set zero-prototype ( one-of lefties with [dominant-identity = "political-affiliation"] )
    if zero-prototype = nobody [ set zero-prototype one-of lefties ]
    set one-prototype ( one-of righties with [dominant-identity = "political-affiliation"] )
    if one-prototype = nobody [ set one-prototype one-of righties ]
  ]
  if salient-identity-group = "age" [
    set zero-agents youngsters
    set one-agents oldies
    set zero-prototype ( one-of youngsters with [dominant-identity = "age"] )
    if zero-prototype = nobody [ set zero-prototype one-of youngsters ]
    set one-prototype ( one-of oldies with [dominant-identity = "age"] )
    if one-prototype = nobody [ set one-prototype one-of oldies ]
  ]
  if salient-identity-group = "socio-economic-status" [
    set zero-agents lowclass
    set one-agents highclass
    set zero-prototype ( one-of lowclass with [dominant-identity = "socio-economic-status"] )
    if zero-prototype = nobody [ set zero-prototype one-of lowclass ]
    set one-prototype ( one-of highclass with [dominant-identity = "socio-economic-status"] )
    if one-prototype = nobody [ set one-prototype one-of highclass ]
  ]

  ;; update opinion
  if model-version = "Converge-on-prototype" [                      ;; VERSION 1
    ask zero-agents [
      let opinion-diff ( [opinion] of zero-prototype - opinion )
      set opinion opinion + ( opinion-diff * opinion-changerate )   ;; move closer to the opinion of the prototype
    ]
    ask one-agents [
      let opinion-diff ( [opinion] of one-prototype - opinion )
      set opinion opinion + ( opinion-diff * opinion-changerate )
    ]
  ]

  if model-version = "Prototype-repulsion" [                                                                            ;; VERSION 2
    let sign-pd 1
    if zero-prototype != nobody and one-prototype != nobody [
      let prototype-difference ([opinion] of zero-prototype - [opinion] of one-prototype)
      ifelse prototype-difference = 0 [set sign-pd 1][set sign-pd (prototype-difference / abs(prototype-difference))]   ;; returns the sign of the prototype-difference (-1 or 1)
      ask zero-prototype [
        set opinion opinion + (sign-pd * (1 - abs(prototype-difference)) * opinion-changerate)                          ;; prototypes move their opinion away from each other
        set opinion max( list min( list opinion (1 - (1 / (10 ^ decimals)))) 0)                                         ;; to make sure that the opinions stay within range 0-1
      ]
      ask one-prototype [
        set opinion opinion - (sign-pd * (1 - abs(prototype-difference)) * opinion-changerate)
        set opinion max( list min( list opinion (1 - (1 / (10 ^ decimals)))) 0)
      ]
    ]

    ask zero-agents [
      let opinion-diff ( [opinion] of zero-prototype - opinion )
      set opinion opinion + ( opinion-diff * opinion-changerate )                                                        ;; the other agents move closer to the opinion of the prototype
    ]
    ask one-agents [
      let opinion-diff ( [opinion] of one-prototype - opinion )
      set opinion opinion + ( opinion-diff * opinion-changerate )
    ]
  ]

  if model-version = "Balance-inclusion-differentiation" [                                        ;; VERSION 3
    let sign-od 1
    let opinion-diff 0
    ask zero-agents [
      ifelse count zero-agents > 1 [                                                              ;; if there are 2 or more group members, move closer to the opinion of the prototype
        set opinion-diff ( [opinion] of zero-prototype - opinion )
        set opinion opinion + ( opinion-diff * opinion-changerate )
      ][
        set opinion-diff ( [opinion] of one-prototype - opinion )                                 ;; if there is only one member in the group, move opinion away from the prototype of the other group
        ifelse opinion-diff = 0 [set sign-od 1][set sign-od (opinion-diff / abs(opinion-diff))]   ;; returns the sign of the opinion-difference (-1 or 1)
        set opinion opinion - ( sign-od * (1 - abs(opinion-diff)) * opinion-changerate )
        set opinion max( list min( list opinion (1 - (1 / (10 ^ decimals)))) 0)                   ;; to make sure that the opinions stay within range 0-1
      ]
    ]
    ask one-agents [
      ifelse count one-agents > 1 [
        set opinion-diff ( [opinion] of one-prototype - opinion )
        set opinion opinion + ( opinion-diff * opinion-changerate )
      ][
        ifelse count zero-agents > 1 [set opinion-diff ( [opinion] of zero-prototype - opinion )][set opinion-diff (-1 * opinion-diff)]
        ifelse opinion-diff = 0 [set sign-od 1][set sign-od (opinion-diff / abs(opinion-diff))]
        set opinion opinion - ( sign-od * (1 - abs(opinion-diff)) * opinion-changerate )
        set opinion max( list min( list opinion (1 - (1 / (10 ^ decimals)))) 0)
      ]
    ]
  ]

  ask turtles-here [ set opinion round( opinion * (10 ^ decimals) ) / (10 ^ decimals) ]   ;; make sure number of decimals stays the same
  ask turtles-here [ set color ifelse-value (opinion < 0.5) [violet] [orange] ]           ;; update color
end

to check-distinct-opinions
  set decimals-round 2
  ask turtles [ set opinion-round round( opinion * (10 ^ decimals-round) ) / (10 ^ decimals-round) ]   ;; round the opinions
  set distinct-opinions remove-duplicates ([opinion-round] of turtles)                                 ;; returns list of distinct opinions
end

; Copyright 2023 Nwankwo Hogervorst
@#$#@#$#@
GRAPHICS-WINDOW
192
10
655
1524
-1
-1
5.0
1
10
1
1
1
0
0
1
1
0
90
0
300
0
0
1
ticks
30.0

BUTTON
18
117
81
150
NIL
Go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

BUTTON
91
117
154
150
NIL
Setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

PLOT
1174
10
1487
267
opinion of individuals
time
opinion
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot [opinion] of turtle 0"
"pen-1" 1.0 0 -7500403 true "" "plot [opinion] of turtle 1"
"pen-2" 1.0 0 -2674135 true "" "plot [opinion] of turtle 2"
"pen-3" 1.0 0 -955883 true "" "Plot [opinion] of turtle 3"
"pen-4" 1.0 0 -6459832 true "" "plot [opinion] of turtle 4"
"pen-5" 1.0 0 -1184463 true "" "plot [opinion] of turtle 5"
"pen-6" 1.0 0 -10899396 true "" "plot [opinion] of turtle 6"
"pen-7" 1.0 0 -11221820 true "" "plot [opinion] of turtle 7"
"pen-8" 1.0 0 -8630108 true "" "plot [opinion] of turtle 8"
"pen-9" 1.0 0 -2064490 true "" "plot [opinion] of turtle 9"

PLOT
1174
271
1487
528
public-opinion
opinion
#agents
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

CHOOSER
6
10
98
55
Country
Country
"Germany" "France"
1

OUTPUT
852
602
1322
750
10

MONITOR
113
429
170
474
#pro
count turtles with [ opinion >= 0.5 ]
17
1
11

MONITOR
112
479
169
524
#anti
count turtles with [ opinion < 0.5 ]
17
1
11

BUTTON
52
154
115
187
Go once
go
NIL
1
T
OBSERVER
NIL
A
NIL
NIL
1

SLIDER
5
238
177
271
avg-group-size
avg-group-size
2
8
5.0
1
1
NIL
HORIZONTAL

SLIDER
5
198
177
231
num-agents
num-agents
100
1000
1000.0
100
1
NIL
HORIZONTAL

SLIDER
4
279
179
312
opinion-changerate
opinion-changerate
0.1
1
0.3
0.1
1
NIL
HORIZONTAL

PLOT
675
10
872
153
opinion-male
NIL
#agents
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13791810 true "" ""

PLOT
875
10
1068
153
opinion-female
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
"default" 1.0 0 -2064490 true "" ""

PLOT
675
156
872
299
opinion-left-wing
NIL
#agents
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -10899396 true "" ""

PLOT
875
156
1068
299
opinion-right-wing
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
"default" 1.0 0 -5825686 true "" ""

PLOT
675
302
872
445
opinion-young
NIL
#agents
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -1184463 true "" ""

PLOT
875
302
1068
445
opinion-old
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
"default" 1.0 0 -6459832 true "" ""

PLOT
675
449
872
592
opinion-low-ses
opinion
#agents
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -8630108 true "" ""

PLOT
876
449
1068
592
opinion-high-ses
opinion
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -11221820 true "" ""

MONITOR
1079
10
1136
55
men
count turtles with [gender = \"male\"]
17
1
11

MONITOR
1079
56
1136
101
women
count turtles with [gender = \"female\"]
17
1
11

MONITOR
1078
157
1135
202
lefties
count turtles with [political-affiliation = \"left\"]
17
1
11

MONITOR
1078
203
1135
248
righties
count turtles with [political-affiliation = \"right\"]
17
1
11

MONITOR
1079
303
1136
348
young
count turtles with [age = \"young\"]
17
1
11

MONITOR
1079
350
1136
395
old
count turtles with [age = \"old\"]
17
1
11

MONITOR
1079
449
1136
494
low-ses
count turtles with [socio-economic-status = \"low\"]
17
1
11

MONITOR
1078
494
1137
539
high-ses
count turtles with [socio-economic-status = \"high\"]
17
1
11

MONITOR
57
561
132
606
avg opinion
mean [opinion] of turtles
3
1
11

MONITOR
5
319
90
364
avg group size
mean [plabel] of group-locations
2
1
11

MONITOR
5
366
90
411
max group size
max [plabel] of group-locations
2
1
11

MONITOR
92
345
165
390
NIL
num-groups
17
1
11

SWITCH
3
419
106
452
gender?
gender?
1
1
-1000

SWITCH
3
452
106
485
political?
political?
0
1
-1000

SWITCH
3
485
106
518
age?
age?
1
1
-1000

SWITCH
3
518
106
551
ses?
ses?
1
1
-1000

MONITOR
1332
539
1476
584
max opinion
max [opinion] of turtles
17
1
11

MONITOR
1188
539
1328
584
min opinion
min [opinion] of turtles
17
1
11

CHOOSER
6
58
163
103
Model-version
Model-version
"Converge-on-prototype" "Prototype-repulsion" "Balance-inclusion-differentiation"
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
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
