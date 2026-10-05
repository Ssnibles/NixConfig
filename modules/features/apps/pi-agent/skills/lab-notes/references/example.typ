// Worked lab-note example (fictional). Copy the shape, not the content.
// Compiles stand-alone in a notes repo: `typst compile --root <repo> <this>`.

#import "/templates/theme.typ": *
#show: theme.with(course: "COMPX000")

#set document(title: "Lab 4 — RC transient response")
#let date = "Lab 4"

#note-title(date, "Lab 4 — RC transient response")

#card[
  *The big picture.* This lab charges a capacitor through a resistor and measures
  how the voltage across it decays. It makes the time constant $tau = R C$
  tangible: after one $tau$ the voltage has fallen to about 37% of its starting
  value, regardless of the actual $R$ and $C$.
]

== Aim

Measure the discharge curve of an RC circuit and extract its time constant, then
compare it with the value predicted from the component values.

== Method

+ *Step 1:* Assemble the series RC circuit with $R = 10 "k"Omega$ and
  $C = 100 "µF"$.
+ *Step 2:* Charge the capacitor to 5 V, then disconnect the supply.
+ *Step 3:* Log the capacitor voltage every 0.1 s for 5 s.
+ *Step 4:* Plot $V(t)$ and fit an exponential.

== Results

#figure(
  rect(width: 70%, height: 3.2cm, radius: ui-radius, stroke: 0.5pt + ui-border, fill: ui-surface)[
    #align(center + horizon)[_Oscilloscope trace placeholder_]
  ],
  caption: [Capacitor voltage decaying after the supply is removed.],
) <fig:trace>

The measured values fall on a clean exponential:

#block(radius: ui-radius, clip: true, stroke: 0.5pt + ui-border)[
  #table(
    columns: (auto, auto, auto),
    fill: (col, row) => if row == 0 { ui-surface-raised } else { none },
    inset: (x: 10pt, y: 6pt),
    stroke: (x, y) => (top: if y > 0 { 0.5pt + ui-border } else { none }, left: if x > 0 { 0.5pt + ui-border } else { none }),
    table.header([*Time (s)*], [*Voltage (V)*], [*Fraction of 5 V*]),
    [0.0], [5.00], [1.00],
    [1.0], [1.84], [0.37],
    [2.0], [0.68], [0.14],
  )
]

== Analysis

The decay is $V(t) = V_0 e^(-t\/tau)$, so at $t = tau$ the voltage is
$e^(-1) approx 37%$ of $V_0$ — see @fig:trace. The table shows 1.84 V at 1.0 s,
which is 37% of 5 V, so $tau approx 1.0 "s"$.

The predicted value is $tau = R C = 10^4 times 10^(-4) = 1 "s"$, which matches.
The small overshoot at the start is the supply switch settling, as predicted in
the handout.

#callout("📌", "Takeaway:", "#dd6b20")[
  $tau = R C$ depends only on the product, not on the individual values: doubling
  $R$ and halving $C$ gives the same curve.
]

== Lab questions

#qa[What fraction of $V_0$ remains after one time constant?][$e^(-1) approx 37%$, independent of $R$ and $C$.]

#qa[Why does the measured $tau$ match the predicted value?][The components are ideal to within tolerance; the fitted decay of 1.0 s equals $R C = 1.0$ s.]

== Self-test

#qa[How long until the voltage falls below 5% of $V_0$?][About three time constants ($e^(-3) approx 5%$), i.e. roughly 3 s here.]
