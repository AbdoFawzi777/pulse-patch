import json
import math
import numpy as np

with open('app/assets/ml/model_meta.json', 'r', encoding='utf-8') as f:
    meta = json.load(f)

# Session 1 features from DB (sess-1792996240842):
features = {
    'mean_hr': 71.83076923076923,
    'std_hr': 1.305866938680378,
    'start_hr': 72.0,
    'end_hr': 73.0,
    'recovery_drop': -1.0
}

scaler_mean = meta['scaler']['mean']
scaler_scale = meta['scaler']['scale']
feat_names = meta['features']

zVector = []
for i, name in enumerate(feat_names):
    val = features[name]
    m = scaler_mean[i]
    s = scaler_scale[i]
    z = (val - m) / s
    zVector.append(z)

print('Session 1 Stored Features:')
for k, v in features.items():
    print(f'  {k:<16}: {v:.4f}')

print('\nStandardized Z-Vector:')
for name, z in zip(feat_names, zVector):
    print(f'  {name:<16}: {z:+.4f}')

# Layer 1
c0 = meta['weights']['coefs'][0]
b0 = meta['weights']['intercepts'][0]
h1 = []
for j in range(16):
    s = b0[j]
    for i in range(len(zVector)):
        s += zVector[i] * c0[i][j]
    h1.append(max(0.0, s))

# Layer 2
c1 = meta['weights']['coefs'][1]
b1 = meta['weights']['intercepts'][1]
h2 = []
for j in range(8):
    s = b1[j]
    for i in range(16):
        s += h1[i] * c1[i][j]
    h2.append(max(0.0, s))

# Layer 3
c2 = meta['weights']['coefs'][2]
b2 = meta['weights']['intercepts'][2]
logit = b2[0]
for i in range(8):
    logit += h2[i] * c2[i][0]

prob_different = 1.0 / (1.0 + math.exp(-logit))
is_typical = prob_different < 0.5
label = 'Typical pattern' if is_typical else 'Different pattern'

print(f'\nNeural Network Forward Pass:')
print(f'  Logit:                     {logit:+.4f}')
print(f'  probDifferent (Sigmoid):   {prob_different:.6f} (Threshold = 0.50)')
print(f'  isTypical (probDiff < 0.5): {is_typical}')
print(f'  Model Output Label:        {label}')
explanation = (
    'Similar to your last 5 rest sessions. A pattern label, not a health rating.'
    if is_typical
    else 'Varied from your typical resting baseline pattern. A statistical pattern label, not a health rating.'
)
print(f'  Generated Explanation:     "{explanation}"')
