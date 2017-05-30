breed [ flowers flower ]
breed [ bees bee]
breed [ beehives beehive]

globals
[
  scale-factor  ;; to control the form of the slower field
  days-elapsed
  i
]

flowers-own
[
  intensity
  caffenation
]

bees-own
[
  ;; +1 means the bees turn to the right to try to evade a bright light
  ;; (and thus circle the light source clockwise). -1 means the moths
  ;; turn to the left (and circle the light counter-clockwise)
  ;; The direction tendency is assigned to each bee when it is created and does not
  ;; change during the moth's lifetime.
  direction
]

beehives-own
[
  capacity
  visit-chance
]

patches-own
[
  ;; represents the total smell/attraction from all flower sources
  total-flower-attraction
]

to setup
  clear-all
  set-default-shape flowers "flower"
  set-default-shape bees "bee 2"
  set-default-shape beehives "beehive1"
  set scale-factor 50
  set days-elapsed 0
  set i 0
  if number-flowers > 0
  [
    make-flowers number-flowers
    ask patches [ generate-field ]
  ]
  make-bees number-bees
  make-beehives 1
  reset-ticks
end

to go
  ask bees [ move-thru-field ]
  set days-elapsed (ticks / 100)
  tick
end

;;;;;;;;;;;;;;;;;;;;;;
;; Setup Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;

to make-flowers [ number ]
  create-flowers number [
    set color white
    jump 10 + random-float (max-pxcor - 30)
    set intensity (random luminance + 20)
    set size 20
    loop [
    if (i >= caffeine-flowers)
      [
        stop
      ]
      ;set i (i + 1)
      set color red
    ]
  ]
end

to make-bees [ number ]
  create-bees number [
    ifelse (random 2 = 0)
      [ set direction 1 ]
      [ set direction -1 ]
    set color white
    jump random-float max-pxcor
    set size 5
  ]
end

to make-beehives [ number ]
  create-beehives number [
    set color red
    jump 10 + random-float (max-pxcor - 30)
    set size 40
  ]
end

to generate-field ;; patch procedure
  set total-flower-attraction 0
  ;; every patch needs to check in with every flower
  ask flowers
    [ set-field myself ]
  ;;set pcolor scale-color blue (sqrt total-flower-attraction) 0.1 ( sqrt ( 20 * max [intensity] of flowers ) )
end

;; do the calculations for the flower on one patch due to one flower
;; which is proportional to the distance from the flower squared.
to set-field [p]  ;; turtle procedure; input p is a patch
  let rsquared (distance p) ^ 2
  let amount intensity * scale-factor
  ifelse rsquared = 0
    [ set amount amount * 1000 ]
    [ set amount amount / rsquared ]
  ask p [ set total-flower-attraction total-flower-attraction + amount ]
end

;;;;;;;;;;;;;;;;;;;;;;;;
;; Runtime Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;;;

to move-thru-field    ;; turtle procedure
  ifelse (total-flower-attraction <= ( 1 / (10 * sensitivity) ))
  [
    ;; if there are no detectable flowers -> move randomly
    rt flutter-amount 45
  ]
  [
    ifelse (random 25 = 0)
    ;; add some additional randomness to the moth's movement, this allows some small
    ;; probability that the bee might "escape" from the flower.
    ;; Increase this value so that bees can leave the flower and go to the hive
    [
      rt flutter-amount 60
    ]
    [
      ;; turn toward the most attractive flower (as long as it is a reasonable distance away)
      maximize
      ;; if the flower ahead is not above the sensitivity threshold head towards the flower
      ;; otherwise move randomly
      ifelse ( [total-flower-attraction] of patch-ahead 1 / total-flower-attraction > ( 1 + 1 / (10 * sensitivity) ) )
      [
        lt ( direction * turn-angle )
      ]
      [
        rt flutter-amount 60
      ]
    ]
  ]
  if not can-move? 1
    [ maximize ]
  fd 1
end

to maximize  ;; turtle procedure
  face max-one-of patches in-radius 1 [total-flower-attraction]
end

to-report flutter-amount [limit]
  ;; This routine takes a number as an input and returns a random value between
  ;; (+1 * input value) and (-1 * input value).
  ;; It is used to add a random flutter to the moth's movements
  report random-float (2 * limit) - limit
end

; Copyright 2017 Otakar Andrysek and Stanislov Lyakhov
; Copyright 2005 Uri Wilensky.
; See Info tab or GitHub repository for full copyright and license.
; https://github.com/otakar-sst/bee-model
@#$#@#$#@
GRAPHICS-WINDOW
280
10
690
421
-1
-1
2.0
1
10
1
1
1
0
0
0
1
-100
100
-100
100
1
1
1
ticks
30.0

BUTTON
40
157
106
190
Reset
setup
NIL
1
T
OBSERVER
NIL
R
NIL
NIL
1

SLIDER
124
290
246
323
luminance
luminance
1
10
3.0
1
1
NIL
HORIZONTAL

BUTTON
110
157
243
190
Run Simulation
go
T
1
T
OBSERVER
NIL
R
NIL
NIL
0

SLIDER
47
76
169
109
number-flowers
number-flowers
0
5
5.0
1
1
NIL
HORIZONTAL

SLIDER
46
356
218
389
number-bees
number-bees
1
20
17.0
1
1
NIL
HORIZONTAL

SLIDER
45
198
230
231
sensitivity
sensitivity
1
3
1.75
0.25
1
NIL
HORIZONTAL

SLIDER
45
233
230
266
turn-angle
turn-angle
45
180
125.0
5
1
degrees
HORIZONTAL

MONITOR
59
28
153
73
Days Elapsed
days-elapsed
0
1
11

SLIDER
29
111
201
144
caffeine-flowers
caffeine-flowers
0
number-flowers
4.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model demonstrates moths flying in circles around a light.  Each moth follows a set of simple rules.  None of the rules specify that the moth should seek and then circle a light.  Rather, the observed pattern arises out of the combination of the moth's random flight and the simple behavioral rules described below.

Scientists have proposed several explanations for why moths are attracted to and then circle lights. For example, scientists once believed that moths navigated through the sky by orienting themselves to the moon, and that the moths' attraction to nearby, earthly light sources (such as a street lamp) arose because they mistook the terrestrial lights for the moon.  However, while this explanation may seem reasonable, it is not supported by available scientific evidence.

## HOW IT WORKS

Moths exhibit two basic kinds of behavior.  When they detect a light source from a distance (as far as 200 feet away) moths tend to fly straight toward the light.  Then, when moths get close to the light, they tend to turn away from the light in order to avoid it.

First, moths sense the light in their immediate vicinity and turn toward the direction where the light is greatest.

Second, moths compare the light immediately ahead of them with the light at their current position.  If the ratio of 'light just ahead' to 'light here' is below a threshold value, then the moths fly forward toward the light.  If the ratio of 'light just ahead' to 'light here' is above a threshold value, then moths turns away from the light.  The threshold is determined by the moths' sensitivity to light.

If the moths do not detect any light, or if there simply are no lights in the space where the moths are flying, then the moths flutter about randomly.

Note that light energy is represented in this model as decreasing with the square of the distance from the light source.  This characteristic is known as a "one over r-squared relationship," and is comparable to the way electrical field strength decreases with the distance from an electrical charge and the way that gravitational field strength decreases with the distance from a massive body.

## HOW TO USE IT

Click the SETUP button to create NUMBER-LIGHTS with LUMINANCE and NUMBER-MOTHS.  Click the GO button to start the simulation.

NUMBER-MOTHS:  This slider determines how many lights will be created when the SETUP button is pressed.

NUMBER-LIGHTS:  This slider determines how many lights will be created when the SETUP button pressed.  Note that this value only affects the model at setup.

LUMINANCE:  This slider influences how bright the lights will be.  When a light is created, it is assigned a luminance of 20 plus a random value between 0 and LUMINANCE. Lights with a higher luminance can be sensed by moths from farther away.  Note that changing LUMINANCE while the model is running has no effect.

SENSITIVITY:  This slider determines how sensitive the moths are to light.  When SENSITIVITY is higher, moths are able to detect a given light source from a greater distance and will turn away from the light source at a greater distance.

TURN-ANGLE:  This slider determines the angle that moths turn away when they sense that the ratio of 'light ahead' to 'light here' is above their threshold value.

## THINGS TO NOTICE

When the model begins, notice how moths are attracted to the two lights.  What happens when the lights are created very close together?  What happens when the lights are created very far apart?

Do all of the moths circle the same light?  When a moth begins to circle one light, does it ever change to circling the other light?  Why or why not?

## THINGS TO TRY

Run the simulation without any lights.  What can you say about the moths' flight patterns?

With the simulation stopped, use the following values:
- NUMBER-LIGHTS: 1
- LUMINANCE: 1
- NUMBER-MOTHS: 10
- SENSITIVITY: 1.00
- TURN-ANGLE: 95
Notice that, at first, some moths might fly about randomly while others are attracted to the light immediately.  Why?

While the model is running increase SENSITIVITY.  What happens to the moths' flight patterns?  See if you can create conditions in which one or more of the moths can 'escape' from its state of perpetually circling the light.

Vary the TURN-ANGLE.  What happens?  Why do you think the moths behave as observed with different values of TURN-ANGLE?  What value or values do you think are most realistic?

It would be interesting to better understand the flight patterns of the moths in the model.  Add code to the model that allows you to track the movements of one or more moths (for example, by using the pen features).  Do you see a pattern?  Why might such a pattern appear and how can it be altered?

## EXTENDING THE MODEL

This model offers only one set of rules for generating moths' circular flight around a light source.  Can you think of different ways to define the rules?

Alternatively, can you imagine a way to model an earlier theory of moth behavior in which moths navigate straight lines by orienting themselves to the moon?  Do rules that allow moths to navigate according to their position relative to the moon lead to the observed circling behavior around light sources that are much, much closer than the far-away moon?

## NETLOGO FEATURES

This model creates a field of light across the patches, using `scale-color` to display the value, and the moths use `face` and `max-one-of` to traverse the light field.

## RELATED MODELS

Ants, Ant Lines, Fireflies, Flocking

## CREDITS AND REFERENCES

Adams, C.  (1989).  Why are moths attracted to bright lights?  Retrieved May 1, 2005, from http://www.straightdope.com/columns/read/1071/why-are-moths-attracted-to-bright-lights

* Wilensky, U. (2005).  NetLogo Moths model.  http://ccl.northwestern.edu/netlogo/models/Moths.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Andrysek, O. Lyakhov, S. (20017).  NetLogo Bees model.  http://sstctf.org/models/Bees.  SST Capture the Flag Club, School of Science and Technology, Beaverton, OR.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright (©) 2017 Otakar Andrysek and Stanislov Lyakhov.
Copyright (©) 2005 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2017 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

bee 2
true
0
Polygon -1184463 true false 195 150 105 150 90 165 90 225 105 270 135 300 165 300 195 270 210 225 210 165 195 150
Rectangle -16777216 true false 90 165 212 185
Polygon -16777216 true false 90 207 90 226 210 226 210 207
Polygon -16777216 true false 103 266 198 266 203 246 96 246
Polygon -6459832 true false 120 150 105 135 105 75 120 60 180 60 195 75 195 135 180 150
Polygon -6459832 true false 150 15 120 30 120 60 180 60 180 30
Circle -16777216 true false 105 30 30
Circle -16777216 true false 165 30 30
Polygon -7500403 true true 120 90 75 105 15 90 30 75 120 75
Polygon -16777216 false false 120 75 30 75 15 90 75 105 120 90
Polygon -7500403 true true 180 75 180 90 225 105 285 90 270 75
Polygon -16777216 false false 180 75 270 75 285 90 225 105 180 90
Polygon -7500403 true true 180 75 180 90 195 105 240 195 270 210 285 210 285 150 255 105
Polygon -16777216 false false 180 75 255 105 285 150 285 210 270 210 240 195 195 105 180 90
Polygon -7500403 true true 120 75 45 105 15 150 15 210 30 210 60 195 105 105 120 90
Polygon -16777216 false false 120 75 45 105 15 150 15 210 30 210 60 195 105 105 120 90
Polygon -16777216 true false 135 300 165 300 180 285 120 285

beehive1
false
3
Rectangle -6459832 true true 15 135 285 270
Rectangle -7500403 true false 0 105 300 135
Line -16777216 false 15 240 285 240
Rectangle -16777216 true false 120 240 180 255

beehive1super
false
3
Rectangle -6459832 true true 15 195 150 300
Rectangle -7500403 true false 0 180 165 195
Line -16777216 false 15 285 150 285
Rectangle -16777216 true false 60 285 105 300
Line -16777216 false 15 225 150 225

beehive2
false
3
Rectangle -6459832 true true 15 30 285 270
Rectangle -7500403 true false 0 0 300 30
Line -16777216 false 15 240 285 240
Rectangle -16777216 true false 120 240 180 255
Line -16777216 false 15 135 285 135

beehive2super
false
3
Rectangle -6459832 true true 15 165 150 300
Rectangle -7500403 true false 0 150 165 165
Line -16777216 false 15 285 150 285
Rectangle -16777216 true false 60 285 105 300
Line -16777216 false 15 225 150 225
Line -16777216 false 15 195 150 195

beehive3super
false
3
Rectangle -6459832 true true 15 135 150 300
Rectangle -7500403 true false 0 120 165 135
Line -16777216 false 15 285 150 285
Rectangle -16777216 true false 60 285 105 300
Line -16777216 false 15 225 150 225
Line -16777216 false 15 195 150 195
Line -16777216 false 15 165 150 165

bumblebeenest
false
0
Circle -6459832 true false 135 105 90
Circle -6459832 true false 15 135 90
Circle -6459832 true false 150 180 90
Circle -6459832 true false 75 150 90
Circle -6459832 true false 90 210 90
Circle -6459832 true false 195 120 90
Circle -16777216 true false 45 136 42
Circle -16777216 true false 109 151 42
Circle -16777216 true false 166 181 42
Circle -6459832 true false 15 195 90

fadedflower
false
0
Polygon -6459832 true false 75 195 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 10 252 38
Circle -7500403 true true 70 132 38
Circle -7500403 true true 102 175 38
Circle -7500403 true true 87 237 38
Circle -7500403 true true -5 145 38
Circle -7500403 true true 6 156 108
Circle -16777216 true false 23 173 74
Polygon -6459832 true false 189 233 210 225 240 225 225 285 210 240
Polygon -6459832 true false 180 240 150 240 105 240 90 285 120 255

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

flowerorange
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
Circle -955883 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

honeyjar
false
15
Circle -1184463 true false 39 69 42
Circle -1184463 true false 219 69 42
Circle -1184463 true false 219 204 42
Circle -1184463 true false 39 204 42
Rectangle -1184463 true false 45 75 255 240
Rectangle -1184463 true false 39 87 54 222
Rectangle -1184463 true false 246 85 261 220
Rectangle -1184463 true false 60 70 243 98
Rectangle -1184463 true false 57 218 240 246
Rectangle -7500403 true false 75 29 226 72
Rectangle -1 true true 51 107 246 218
Line -16777216 false 63 129 63 186
Line -16777216 false 80 129 80 186
Line -16777216 false 65 158 79 158
Circle -16777216 false false 85 140 43
Line -16777216 false 134 135 135 185
Line -16777216 false 134 137 154 184
Line -16777216 false 154 185 153 135
Line -16777216 false 168 134 168 186
Line -16777216 false 169 136 182 136
Line -16777216 false 169 160 179 160
Line -16777216 false 168 185 183 185
Line -16777216 false 193 134 205 150
Line -16777216 false 206 152 217 132
Line -16777216 false 207 154 208 185

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

pete
false
13
Polygon -2064490 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -2064490 true true 110 5 80
Rectangle -2064490 true true 127 79 172 94
Polygon -1 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -1 true false 115 2 112 19 70 31 70 38 108 46 116 32 143 25 179 24 187 34 223 21 221 12 177 14 166 -2
Rectangle -7500403 true false 225 209 258 255
Rectangle -16777216 false false 115 24 182 99
Line -16777216 false 127 26 127 95
Line -16777216 false 142 24 143 96
Line -16777216 false 156 27 157 96
Line -16777216 false 167 25 168 96
Line -16777216 false 115 76 181 75
Line -16777216 false 115 85 182 85
Line -16777216 false 117 60 180 60
Line -16777216 false 116 45 179 45
Circle -7500403 true false 222 188 36
Polygon -7500403 true false 249 211 257 217 276 188 268 184 247 195
Polygon -6459832 true false 226 204 199 205 227 250
Circle -16777216 true false 143 173 10
Circle -16777216 true false 142 151 10
Line -16777216 false 120 195 179 195
Line -16777216 false 115 34 178 34

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

queen
true
6
Circle -13840069 true true 114 48 72
Circle -13840069 true true 101 112 98
Circle -16777216 true false 107 79 86
Line -13840069 true 150 70 105 30
Line -13840069 true 150 70 195 30
Circle -13840069 true true 109 170 78
Circle -13840069 true true 125 230 50
Polygon -7500403 true false 120 120 60 195 60 210 75 225 105 225 120 210 135 135 120 120
Polygon -7500403 true false 180 120 240 195 240 210 225 225 195 225 180 210 165 135 180 120
Circle -16777216 true false 116 58 19
Circle -16777216 true false 163 56 19
Circle -16777216 true false 112 69 19
Circle -16777216 true false 168 67 19
Circle -13840069 true true 115 199 70
Circle -13791810 true false 121 95 60
Circle -13840069 true true 137 267 26
Circle -13840069 true true 132 253 34
Line -16777216 false 117 228 181 227
Line -16777216 false 126 258 174 256
Line -16777216 false 166 275 133 276
Line -16777216 false 123 192 176 190

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.1
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
