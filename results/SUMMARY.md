# FastVLM-0.5B main results vs. paper (single seed 42, 1×H200)

| Track | This repo | Paper |
|---|---|---|
| cls ID (IN-1K, N24News, Hateful, VOC07, SUN397) | 68.6 | 69.4 |
| cls OOD (Place365, IN-A, IN-R, ObjectNet, Country211) | 34.2 | 33.7 |
| vqa ID (6 sets) | 49.7 | 54.0 |
| vqa OOD (ScienceQA, VizWiz, GQA, TextVQA) | 51.7 | 51.8 |
| ret ID (8 sets) | 60.1 | 60.2 |
| grd ID (MSCOCO) | 68.0 | 69.5 |

Table 4 ablation (vqa, mean of the 6 ID sets): no_pga 48.3, no_intra 50.5, no_inter 50.5, no_pga_intra 48.6 (paper: 51.6 / 53.1 / 52.5); no_pga_inter and no_intra_inter still running.

Known deviations: 1 GPU with gradient accumulation (32 negatives per micro-batch vs ~256 in the paper); lambdas MSE 1.0 / PGA 2.0 / SCL 0.01 (paper Table 6 and Table A2 disagree); one seed. VQA ID is the only track with a clear gap.
- no_pga_inter: 48.2 (6 sets)
