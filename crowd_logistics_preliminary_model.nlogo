extensions [profiler csv]

breed [senders sender]
breed [carriers carrier]
breed [destinations destination]

senders-own [
  IDS
  SParticipation
  Sparticipation_history
  Sfriends
  Spickup_requests
  Spickup_requests_counter
  Spickup_request_list
  Sevaluation_period
  Sdecision_rule
  Assigned_carrier_ID
]

carriers-own [
  IDC
  home_xcor
  home_ycor
  CParticipation
  Cparticipation_history
  Cfriends
  trip_income
  target_distance
  target_Sender_ID
  target
  trip_limit
  Cevaluation_period
  Cdecision_rule
  profit_percentage
]

destinations-own[
  visitors
]

globals [
  ID
  X_COR
  Y_COR
  Participating_senders
  Participating_carriers
  Assigned_senders
  Assigned_carriers
  Unassigned_senders
  Unassigned_carriers
  dummy
  sumof_Cdaily_trip_limit
  Total_trip_requests_per_day
  Carriers_trip_limit_per_day
  Carrier_counter
  Sender_counter
  Packages_delivered
]

to setup

  clear-all

  file-open "Input_data.txt"

  set ID []
  set X_COR []
  set Y_COR []

  while [not file-at-end?] ; read data from text file
  [
    set ID lput file-read ID
    set X_COR lput file-read X_COR
    set Y_COR lput file-read Y_COR
  ]
  file-close

  create-senders 250 [
    set shape "person"
    set color black
    set Sparticipation_history []
    set Sfriends []
    set Assigned_carrier_ID []
    set Spickup_requests_counter []

    if(Decision_rule_distribution = "Normal")
    [
      let x ((Min_evaluation_period + Max_evaluation_period) / 2)
      set Sevaluation_period ceiling random-normal x 2
      set Sdecision_rule ceiling random-normal Max_Participation_decision_rule 2
    ]

    if(Decision_rule_distribution = "Random")
    [
      set Sevaluation_period (Min_evaluation_period + random (Max_evaluation_period - Min_evaluation_period + 1))
      set Sdecision_rule (1 + random Max_Participation_decision_rule)
    ]

    if(Decision_rule_distribution = "Constant")
    [
      set Sevaluation_period Max_evaluation_period
      set Sdecision_rule Max_Participation_decision_rule
    ]

    if (Sevaluation_period <= 0) [set Sevaluation_period 1]
    if (Sdecision_rule <= 0) [set Sdecision_rule 1]
  ]
  create-carriers 250 [
    set shape "person"
    set color black
    set Cparticipation_history []
    set Cfriends []
    set target_Sender_ID []
    set profit_percentage ceiling random-normal Max_carrier_profit 2
    set trip_limit Max_Carrier_trip_limit

    if(Decision_rule_distribution = "Normal")
    [
      let x ((Min_evaluation_period + Max_evaluation_period) / 2)
      set trip_limit ceiling random-normal (Max_Carrier_trip_limit / 2) 2
      set Cevaluation_period ceiling random-normal x 2
      set Cdecision_rule ceiling random-normal Max_Participation_decision_rule 2
    ]

    if(Decision_rule_distribution = "Random")
    [
      set trip_limit (1 + random Max_Carrier_trip_limit)
      set Cevaluation_period (Min_evaluation_period + random (Max_evaluation_period - Min_evaluation_period + 1))
      set Cdecision_rule (1 + random Max_Participation_decision_rule)
    ]

    if(Decision_rule_distribution = "Constant")
    [
      set trip_limit Max_Carrier_trip_limit
      set Cevaluation_period Max_evaluation_period
      set Cdecision_rule Max_Participation_decision_rule
    ]

    if (trip_limit <= 0) [set trip_limit 1]
    if (Cevaluation_period <= 0) [set Cevaluation_period 1]
    if (Cdecision_rule <= 0) [set Cdecision_rule 1]
  ]

  create-destinations Number_of_Destinations [setxy random-xcor random-ycor set shape "triangle 2" set size 2 set visitors []]

  let j 0
  while [j < 250] ; Assign coordinates to senders
  [
    ask one-of senders with [xcor = 0 and ycor = 0]
    [
      set xcor item j X_COR set ycor item j Y_COR
      set IDS item j ID
    ]
    set j j + 1
  ]

  let k 250
  while [k < 500] ; Assign coordinates to Carriers
  [
    ask one-of carriers with [xcor = 0 and ycor = 0]
    [
      set xcor item k X_COR set ycor item k Y_COR
      set home_xcor xcor
      set home_ycor ycor
      set IDC item k ID
    ]
    set k k + 1
  ]

  ask n-of Senders_participating_initially senders [Set SParticipation "Y" set color red]
  ask n-of Carriers_participating_initially carriers [Set CParticipation "Y" set color green]

  ask senders with [SParticipation != "Y"] [set SParticipation "N"]
  ask carriers with [CParticipation != "Y"] [set CParticipation "N"]

  ask senders [
    let i 0
    let r round random-normal Average_friendship_size 2
    while [i < r]
    [
      set Sfriends lput [IDS] of one-of other senders Sfriends
      set i i + 1
    ]
  ]

  ask carriers [
    let i 0
    let r round random-normal Average_friendship_size 2
    while [i < r]
    [
      set Cfriends lput [IDC] of one-of other carriers Cfriends
      set i i + 1
    ]
  ]

  set Assigned_senders []
  set Assigned_carriers []
  set Packages_delivered []

  set Unassigned_senders n-values count senders with [SParticipation = "Y"] [a -> a + 1]
  set Unassigned_carriers n-values count carriers with [CParticipation = "Y"] [a -> a + 1]

  reset-ticks

end


to go

  if ticks = iterations [stop]

  leave_or_join

  set Packages_delivered []

  ask carriers
  [
    set target_Sender_ID []
    set trip_income []
    set target_distance []
    set target_Sender_ID []
    set target []
  ] ; Reset carrier assignment to zero

  let s one-of n-values Number_of_Destinations [a -> a + 1]

  ask senders
  [
    set Assigned_carrier_ID  []

    let sr (1 + random Number_of_Destinations)
    set Spickup_requests sr

    set Spickup_request_list []
  ] ; Reset sender assignment to zero

  ask senders with [SParticipation = "Y"] [set Spickup_request_list n-of Spickup_requests [who] of destinations] ;generate sender requests

  set Participating_senders []
  set Participating_carriers []

  ask carriers with [CParticipation = "Y"] [set Participating_carriers lput IDC Participating_carriers] ;generate list of participating carriers

  if (Destinations_are_stationary? = False)
  [
    ask destinations [setxy random-xcor random-ycor set shape "triangle 2" set visitors []] ;Choosing random coordinates for destinations
  ]

  ask senders with [SParticipation = "Y"] [set Participating_senders lput IDS Participating_senders] ;generate list of participating senders

  set Assigned_senders []
  set Assigned_carriers []

  match_senders_and_carriers

  update_participation_history

  ask senders [set Packages_delivered lput item ticks Sparticipation_history Packages_delivered]

  tick

end

to update_participation_history

  ask carriers [set Cparticipation_history lput length target_Sender_ID Cparticipation_history]

  ask senders [set Sparticipation_history lput length Assigned_carrier_ID Sparticipation_history]

end

to leave_or_join

  ask senders with [SParticipation = "Y" and ticks >= Sevaluation_period and remainder (length SParticipation_history) Sevaluation_period = 1] ;Senders leave the platform
  [
    let l Continued_participation_decision_rule
    if (l > Spickup_requests)[set l Spickup_requests]
    if (sum sublist Sparticipation_history (ticks - Sevaluation_period) ticks < Sevaluation_period * l) [set SParticipation "N" set color black]
  ]

  ask carriers with [CParticipation = "Y" and ticks >= Cevaluation_period and remainder (length CParticipation_history) Cevaluation_period = 1] ;carriers leave the platform
  [
    let l Continued_participation_decision_rule
    if (l > trip_limit)[set l trip_limit]
    if (sum sublist Cparticipation_history (ticks - Cevaluation_period) ticks <  Cevaluation_period * l) [set CParticipation "N" set color black]
  ]


  ask senders with [SParticipation = "N" and ticks >= Sevaluation_period and remainder (length SParticipation_history) Sevaluation_period = 1] ;Senders join the platform
  [
    let s Sfriends
    if (count senders with [SParticipation = "Y" and member? IDS s = true] >= Sdecision_rule)
    [set SParticipation "Y" set color red]
  ]

  ask carriers with [CParticipation = "N" and ticks >= Cevaluation_period and remainder (length CParticipation_history) Cevaluation_period = 1] ;carriers join the platform
  [
    let c Cfriends
    if (count carriers with [CParticipation = "Y" and member? IDC c = true]  >= Cdecision_rule )
    [set CParticipation "Y" set color green]
  ]

end


to match_Senders_and_carriers

  let l 0

  set Unassigned_senders Participating_senders
  set Unassigned_carriers Participating_carriers
  set Carrier_counter Participating_carriers

  let ctl []
  ask carriers with [Cparticipation = "Y"] [set ctl lput trip_limit ctl]
  set Carriers_trip_limit_per_day sum ctl

  while [l < Carriers_trip_limit_per_day and length Carrier_counter != 0] ;Assign participating senders with destinations to carriers
  [
    let Carrier_ID one-of Carrier_counter
    ask senders with [Sparticipation = "Y"][set Spickup_requests_counter Spickup_request_list]
    set Sender_counter Unassigned_senders

    ask carriers with [IDC = Carrier_ID]
    [
      let j 0
      let sl []
      ask senders with [Sparticipation = "Y"] [set sl lput length Spickup_request_list sl]
      set Total_trip_requests_per_day sum sl
      while [j < Total_trip_requests_per_day]
      [
        ifelse (length Sender_counter != 0)
        [
          let y one-of Sender_counter
          let r one-of [Spickup_requests_counter] of one-of senders with [IDS = y]
          let sdist_dest precision ([distance one-of senders with [IDS = y]] of one-of destinations with [who = r]) 2
          let strip_cost precision (2 * sdist_dest * Sender_cost) 2
          let d precision (distance one-of senders with [IDS = y] + sdist_dest ) 2

          if (precision (d * Carrier_cost * (1 + (profit_percentage / 100))) 2 <= strip_cost)
          [
            set trip_income lput precision (d * Carrier_cost * (1 + (profit_percentage / 100))) 2 trip_income
            set target_Sender_ID lput y target_Sender_ID
            set target lput r target
            set target_distance lput d target_distance

            let z IDC
            ask one-of senders with [IDS = y]
            [
              set Assigned_carrier_ID lput z Assigned_carrier_ID
              set Spickup_request_list remove r Spickup_request_list
              set Spickup_requests_counter remove r Spickup_requests_counter
              if (length Spickup_request_list = 0)
              [
                set Assigned_senders lput IDS Assigned_senders ;Update the assigned senders list with senders ID that choose a carrier
                set Unassigned_senders remove IDS Unassigned_senders ;Remove the sender who has been assigned from the Unassaigned senders list
              ]
              if (length Spickup_requests_counter = 0)[set Sender_counter remove IDS Sender_counter]
            ]
            move-to one-of senders with [ IDS = y]
            move-to one-of destinations with [who = r]
            let x IDC
            ask one-of destinations with [who = r] ;Destinations record visitors (Carriers who visited them)
            [
              set shape "triangle"
              set visitors lput x visitors
            ]
            if (length target_Sender_ID = trip_limit)
            [
              set Assigned_carriers lput IDC Assigned_carriers ; Update the assigned carriers list with carrier ID that choose a sender
              set Unassigned_carriers remove IDC Unassigned_carriers; Remove the carrier who has been assigned from the Unassigned carriers list
              set Carrier_counter remove IDC Carrier_counter
              move-to patch home_xcor home_ycor
            ]
            set j Total_trip_requests_per_day + 1
          ]
          ask one-of senders with [IDS = y][
            set Spickup_requests_counter remove r Spickup_requests_counter
            set Sender_counter remove IDS Sender_counter
          ]
          set j j + 1
        ]
        [set j Total_trip_requests_per_day + 1]
      ]
      if (j =  Total_trip_requests_per_day)[set Carrier_counter remove IDC Carrier_counter] ; Remove the carrier who has had a chance select a sender
    ]
    set l l + 1
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
800
10
1668
879
-1
-1
12.84
1
10
1
1
1
0
0
0
1
-33
33
-33
33
0
0
1
ticks
30.0

BUTTON
267
13
349
46
Initialize
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
386
14
458
47
START
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

SLIDER
6
10
252
43
Senders_participating_initially
Senders_participating_initially
5
250
20.0
1
1
NIL
HORIZONTAL

SLIDER
4
62
255
95
Carriers_participating_initially
Carriers_participating_initially
5
250
22.0
1
1
NIL
HORIZONTAL

SLIDER
8
122
214
155
Number_of_Destinations
Number_of_Destinations
2
10
8.0
1
1
NIL
HORIZONTAL

SLIDER
272
171
444
204
Iterations
Iterations
2
1000
100.0
1
1
Days
HORIZONTAL

BUTTON
321
64
406
97
Go Once
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

SLIDER
484
58
728
91
Carrier_cost
Carrier_cost
1
5
1.0
0.5
1
$ per unit distance
HORIZONTAL

SLIDER
484
16
727
49
Sender_cost
Sender_cost
1
5
1.0
0.5
1
$ per unit distance
HORIZONTAL

PLOT
278
559
528
726
Senders being served
Day
# of Senders
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Served by carrier" 1.0 0 -2674135 true "" "plot count senders with [length Assigned_carrier_ID > 0]"

PLOT
11
369
262
542
Carriers participating
Day
# of carriers
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13840069 true "" "plot count carriers with [Cparticipation = \"Y\"]"

PLOT
277
370
530
540
Senders participating
Day
# of senders
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot count senders with [Sparticipation = \"Y\"]"

SLIDER
0
224
441
257
Max_Participation_decision_rule
Max_Participation_decision_rule
2
7
3.0
1
1
Friends during evaluation
HORIZONTAL

SLIDER
267
128
464
161
Average_friendship_size
Average_friendship_size
2
10
7.0
1
1
NIL
HORIZONTAL

SLIDER
501
162
745
195
Max_Carrier_trip_limit
Max_Carrier_trip_limit
1
20
10.0
1
1
jobs/day
HORIZONTAL

SLIDER
505
108
715
141
Max_carrier_profit
Max_carrier_profit
2
20
12.0
1
1
Percent
HORIZONTAL

PLOT
8
561
255
723
Carriers delivering packages
Day
# of Carriers
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13840069 true "" "plot count carriers with [length target_Sender_ID > 0]"

SWITCH
6
176
241
209
Destinations_are_stationary?
Destinations_are_stationary?
0
1
-1000

SLIDER
478
203
706
236
Max_evaluation_period
Max_evaluation_period
3
10
7.0
1
1
days
HORIZONTAL

SLIDER
419
319
775
352
Continued_participation_decision_rule
Continued_participation_decision_rule
1
5
2.0
1
1
Jobs per day
HORIZONTAL

CHOOSER
23
284
211
329
Decision_rule_distribution
Decision_rule_distribution
"Random" "Normal" "Constant"
0

SLIDER
472
257
696
290
Min_evaluation_period
Min_evaluation_period
1
9
2.0
1
1
days
HORIZONTAL

MONITOR
539
560
795
613
% of Carriers working at max capacity
((Count carriers with [length target_Sender_ID = trip_limit]) / count carriers with [Cparticipation = \"Y\"])  * 100
0
1
13

MONITOR
580
622
751
675
% of senders fully served
((count senders with [length Assigned_carrier_ID = Spickup_requests and Spickup_requests != 0] / count senders with [Sparticipation = \"Y\"])) * 100
0
1
13

PLOT
546
372
791
539
Packages delivered
Day
# of deliveries
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum Packages_delivered"

MONITOR
598
680
725
733
Total participants
count carriers with [Cparticipation = \"Y\"] + count senders with [Sparticipation = \"Y\"]
0
1
13

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
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count carriers with [Cparticipation = "Y"] + count senders with [Sparticipation = "Y"]</metric>
    <metric>((Count carriers with [length target_Sender_ID = trip_limit]) / count carriers with [Cparticipation = "Y"])  * 100</metric>
    <metric>((count senders with [length Assigned_carrier_ID = Spickup_requests and Spickup_requests != 0] / count senders with [Sparticipation = "Y"])) * 100</metric>
    <metric>sum Packages_delivered</metric>
    <enumeratedValueSet variable="Decision_rule_distribution">
      <value value="&quot;Random&quot;"/>
      <value value="&quot;Normal&quot;"/>
      <value value="&quot;Constant&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sender_cost">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_carrier_profit">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Senders_participating_initially">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_Carrier_trip_limit">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Carriers_participating_initially">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_evaluation_period">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Iterations">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Min_evaluation_period">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number_of_Destinations">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Destinations_are_stationary?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Continued_participation_decision_rule">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Average_friendship_size">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Carrier_cost">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_Participation_decision_rule">
      <value value="3"/>
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
