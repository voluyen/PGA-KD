# FastVLM-0.5B main results vs. paper (single seed 42, 1×H200)

| Track | This repo | Paper |
|---|---|---|
| cls ID (IN-1K, N24News, Hateful, VOC07, SUN397) | 68.6 | 69.4 |
| cls OOD (Place365, IN-A, IN-R, ObjectNet, Country211) | 34.2 | 33.7 |
| vqa ID (6 sets) | 49.7 | 54.0 |
| vqa OOD (ScienceQA, VizWiz, GQA, TextVQA) | 51.7 | 51.8 |
| ret ID (8 sets) | 60.1 | 60.2 |
| grd ID (MSCOCO) | 68.0 | 69.5 |

Table 4 ablation (vqa, mean of the 6 ID sets; paper in brackets where reported):

| Config | Avg |
|---|---|
| Full | 49.7 (54.0) |
| w/o PGA | 48.3 (51.6) |
| w/o intra | 50.5 (53.1) |
| w/o inter | 50.5 (52.5) |
| w/o PGA, intra | 48.6 (51.5) |
| w/o PGA, inter | 48.2 (51.6) |
| w/o intra, inter | 50.2 (53.2) |

Reading: removing PGA costs 1.4-2.0 points here (paper: 2.4-3.0), same direction. Removing SCL terms does not hurt here, it gives +0.5 to +0.8 (paper: -0.8 to -1.5), so the full model is not the best row; with one seed this is within noise but contradicts the paper. DocVQA and ChartQA are the sensitive sets: all w/o-PGA runs lose about 5-6 points on DocVQA, matching the paper's pattern.

Known deviations: 1 GPU with gradient accumulation (32 negatives per micro-batch vs ~256 in the paper); lambdas MSE 1.0 / PGA 2.0 / SCL 0.01 (paper Table 6 and Table A2 disagree); one seed. VQA ID is the only track with a clear gap.
