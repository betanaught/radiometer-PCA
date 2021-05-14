---
author: "Brendan Wakefield"
title: "TriOS RAMSES Radiometer PCA and Water Chemistry Regression"
date: "14 May 2021"
---

# Project Summary
The purpose of this project was to construct an analysis pipeline for performing a Principal Component Analysis (PCA) on the raw hyperspectral data exported from [TriOS RAMSES](https://www.trios.de/en/ramses.html) radiometer sensors and subsequent linear regerssion of water chemistry constituents on the principal components using the Julia language. The data was collected during a summer deployment of two sensors (`sensor_1` and `sensor_2`) on the Delaware River from August 13 - October 27, 2020. This was a trial deployment by the USGS and NASA to test a real-time data pipeline developed by the USGS California Water Science Center (CAWSC, housed right on CSUS capus!), assessing the feasability of reporting measurements within 30 minutes of being recorded (this pipeline involves a PostgreSQL database in AWS RDS and a live Tableau Server dashboard for user-access to the data).

The raw radiometer data was not as processed as is usually the case in radiometer deployments due to the project being centered around feasability. For example, TriOS RAMSES sensors are specifically designed to measure "water-leaving radiance," which is the amount of photons being radiated *out* of the water after absorption. This measurement is highly confounded by light reflectance off the surface and scattered light in the atmostphere, so ideal deployments use three sensors and an algorithm to filter the measurements to corrected spectrograms. In this project, however, only two sensors were deployed, and no filtering algorithm was applied to the data. So the three data sets referenced in the code are from `sensor_1` (pointed up 45° towards the sky), `sensor_2` (pointed down, 45°, at the water's surface). and `full_data`, which is a UNION of the two data sets. The two sensors measure offset wavelengths in their respective spectrograms (so, `sensor_1` measures λ = 315, 317, 319, ... nm; `sensor_2` measures λ = 316, 318, 320, ... nm)

Nevertheless, I was interested in using this raw data to design an analysis capable of handling the raw output data from the sensors and perform a PCA and regression using Julia. The code I developed successfully reads the data from either the individual sensors or the combined set, performs a PCA, and has code for regressing individual water chemistry constituents against the principal components and/or the wavelengths (λ) with the highest loadings.

There is a large amount of coliearity between the individual wavelengths (the intensities of adjacent wavelengths such as 415 nm and 417 nm are nearly perfectly correlated), which makes sense because the general shape of spectra are similar accross timestamps. Because of this, PCAs on both data sets extracted two principal components, each, explaining ~ 99% of the heterogeneity in the spectral data. As I researched PCA and principal component regression (PCR), I learned that these spectral characteristics make PCA and PCR very common techniques for spectral data sets (see References).

The full code is in `rad.jl`. The data files are `rad_sensor1.csv`, `rad_sensor2.csv`, and `full_data.csv`.

# Data Import and Preprocessing
```julia
using CSV, DataFrames

sensor1_data = CSV.read("data/rad_sensor1.csv", DataFrame)
sensor2_data = CSV.read("data/rad_sensor2.csv", DataFrame)
full_data = CSV.read("data/rad_all.csv", DataFrame)

full_data[full_data[:, "sensor_id"].==1, :] # full_data WHERE sensor_id == 1

show(names(sensor1_data)[1:20])
sensor1_data
sensor1_data[1:10, ["datetime_15", "datetime_5", "Turbidity, FNU"]]

sum(completecases(sensor1_data, [:"Turbidity, FNU"]))
sum(completecases(sensor1_data, [:"azimuth"]))
completecases(sensor1_data, names(sensor1_data)[1:20])

# Show number of missing values for non-wavelength columns
function show_missing(df)
    for i in 1:20
        col_name = names(df)[i]
        not_missing = sum(completecases(df, i))
        num_missing = length(df[!, i]) - not_missing
        println(col_name, " - ", num_missing)
    end
end

show_missing(sensor1_data)
show_missing(sensor2_data)

dropmissing!(sensor1_data)
dropmissing!(sensor2_data)
```

```
["datetime_str_UTC", "datetime_UTC", "datetime_EST", "datetime", "datetime_
15", "datetime_5", "sample_id", "azimuth", "solar_alt", "Diss Oxygen Satura
tion, %", "Dissolved Oxygen, mg/L", "Gage Height, ft", "Relative fDOM, wate
r, in situ, RFU", "Specific Cond at 25C, uS/cm", "Temperature, deg C", "Tur
bidity, FNU", "fChl, water, in situ, RFU", "fDOM, water, in situ, QSE", "pH
, pH Units", "315.90247"]datetime_str_UTC - 0
datetime_UTC - 0
datetime_EST - 0
datetime - 0
datetime_15 - 0
datetime_5 - 0
sample_id - 0
azimuth - 97
solar_alt - 97
Diss Oxygen Saturation, % - 45
Dissolved Oxygen, mg/L - 45
Gage Height, ft - 5
Relative fDOM, water, in situ, RFU - 45
Specific Cond at 25C, uS/cm - 45
Temperature, deg C - 45
Turbidity, FNU - 45
fChl, water, in situ, RFU - 45
fDOM, water, in situ, QSE - 45
pH, pH Units - 45
315.90247 - 0
datetime_str_UTC - 0
datetime_UTC - 0
datetime_EST - 0
datetime - 0
datetime_15 - 0
datetime_5 - 0
sample_id - 0
azimuth - 97
solar_alt - 97
Diss Oxygen Saturation, % - 45
Dissolved Oxygen, mg/L - 45
Gage Height, ft - 5
Relative fDOM, water, in situ, RFU - 45
Specific Cond at 25C, uS/cm - 45
Temperature, deg C - 45
Turbidity, FNU - 45
fChl, water, in situ, RFU - 45
fDOM, water, in situ, QSE - 45
pH, pH Units - 45
316.69122 - 0
5450×210 DataFrame
  Row │ datetime_str_UTC  datetime_UTC           datetime_EST            da
tet ⋯
      │ Int64             String                 String                  St
rin ⋯
──────┼────────────────────────────────────────────────────────────────────
─────
    1 │   20200813192638  8/13/2020 7:26:00 PM   8/13/2020 2:26:00 PM    8/
13/ ⋯
    2 │   20200813201140  8/13/2020 8:11:00 PM   8/13/2020 3:11:00 PM    8/
13/
    3 │   20200813202641  8/13/2020 8:26:00 PM   8/13/2020 3:26:00 PM    8/
13/
    4 │   20200813204141  8/13/2020 8:41:00 PM   8/13/2020 3:41:00 PM    8/
13/
    5 │   20200813205641  8/13/2020 8:56:00 PM   8/13/2020 3:56:00 PM    8/
13/ ⋯
    6 │   20200813214144  8/13/2020 9:41:00 PM   8/13/2020 4:41:00 PM    8/
13/
    7 │   20200813215644  8/13/2020 9:56:00 PM   8/13/2020 4:56:00 PM    8/
13/
    8 │   20200813222644  8/13/2020 10:26:00 PM  8/13/2020 5:26:00 PM    8/
13/
  ⋮   │        ⋮                    ⋮                      ⋮               
    ⋱
 5444 │   20201027155808  10/27/2020 3:58:00 PM  10/27/2020 10:58:00 AM  10
/27 ⋯
 5445 │   20201027161307  10/27/2020 4:13:00 PM  10/27/2020 11:13:00 AM  10
/27
 5446 │   20201027162808  10/27/2020 4:28:00 PM  10/27/2020 11:28:00 AM  10
/27
 5447 │   20201027164308  10/27/2020 4:43:00 PM  10/27/2020 11:43:00 AM  10
/27
 5448 │   20201027165808  10/27/2020 4:58:00 PM  10/27/2020 11:58:00 AM  10
/27 ⋯
 5449 │   20201027171308  10/27/2020 5:13:00 PM  10/27/2020 12:13:00 PM  10
/27
 5450 │   20201027172807  10/27/2020 5:28:00 PM  10/27/2020 12:28:00 PM  10
/27
                                               207 columns and 5435 rows om
itted
```




Not too many rows with missing water chemistry data, so I decided to just drop them for now rather than looking into impute methods (e.g., `Impute.jl`)

# Exploratory Data Visualization and Exploration
Can we see any relationships right off-the-bat?
```julia
using Plots
plotly()

scatter(sensor1_data[:, "fChl, water, in situ, RFU"],
        sensor1_data[:, "315.90247"], legend = false,
        ylabel = "fChl", xlabel = "λ 315 nm",
        title = "Fringe λ (315 nm) on Edge of Spectrum")
```


```julia
scatter(sensor1_data[:, "fChl, water, in situ, RFU"],
        sensor1_data[:, "412.67889"], legend = false,
        ylabel = "fChl", xlabel = "λ 412 nm",
        title = "More Average λ (412 nm)")
```


```julia
scatter(sensor1_data[:, "fChl, water, in situ, RFU"],
        sensor1_data[:, "913.04602"], legend = false,
        ylabel = "fChl", xlabel = "λ 913 nm")
```


```julia
scatter(sensor1_data[:, "362.55771"],
        sensor1_data[:, "365.89523"], legend = false,
        ylabel = "λ 362 nm", xlabel = "λ 365 nm",
        title = "Adjacent λ's; Perfect Correlation")
```


```julia
scatter(sensor1_data[:, "734.18652"],
        sensor1_data[:, "750.85486"], legend = false,
        ylabel = "λ 734 nm", xlabel = "λ 750 nm",
        title = "Neighboring λ's; Less Correlation")
```


```julia
scatter(sensor1_data[:, "399.30185"],
        sensor1_data[:, "750.85486"], legend = false,
        ylabel = "λ 399 nm", xlabel = "λ 750 nm",
        title = "Distant λ's; Lower Correlation")
```


```julia
scatter(Array(sensor1_data[10, 20:end]))
scatter!(Array(sensor1_data[30, 20:end]))
scatter!(Array(sensor1_data[70, 20:end]))
scatter!(Array(sensor1_data[100, 20:end]))
scatter!(Array(sensor1_data[200, 20:end]))
scatter!(Array(sensor1_data[300, 20:end]))
scatter!(Array(sensor1_data[400, 20:end]), legend = false)
xlabel!("Wavelength λ")
ylabel!("Intensity")
title!("Spectrograms at Varying Timestamps")
```



So, it's clear that many of the observations in the data table do not contribute information to the analysis. For example, the "fringe" wavelengths at the ends of the spectrograms have zero intensity for all timestamps. Also, it's important to note the perfect colinearity between similar wavelengths, since this is why the PCA can reduce the radiometer data matrix down to only two principal components (see PCA below). The column space (rank) of this matrix is quite low due to the high linear dependence of the columns.

I couldn't resist exploring the relationship between solar `azumuth` and some variables in polar coordinates:
```julia
θ = (π/180) * sensor1_data[1:1000, "azimuth"]
r = sensor1_data[1:1000, "fChl, water, in situ, RFU"]
scatter(θ, r, proj = :polar, m = 2, legend = false)
```


```julia
θ = (π/180) * sensor1_data[1:1000, "azimuth"]
r = sensor2_data[1:1000, "solar_alt"]
scatter(θ, r, proj = :polar, m = 2, legend = false)
```


```julia
θ = (π/180) * sensor1_data[1:1000, "azimuth"]
r = sensor2_data[1:1000, 46]
scatter(θ, r, proj = :polar, m = 2, legend = false)
```



Not much of a relationship between `azimuth` (time of day) and `fChl` measurements. Perfect relationship between `azimuth` and `solar_alt` (obviously) and λ 402 nm.

# Principal Component Analysis
```julia
using Statistics, StatsBase, MultivariateStats
# Sensor 1 data
pca_s1_data = transpose(Matrix(sensor1_data[:, 20:end]))
fit_s1 = fit(PCA, pca_s1_data, maxoutdim = 10)
fit_s1.proj
# Sensor 2 data
pca_s2_data = transpose(Matrix(sensor2_data[:, 20:end]))
fit_s2 = fit(PCA, pca_s2_data, maxoutdim = 10)
fit_s2.proj
```

```
191×2 Matrix{Float64}:
 -0.0142635   -0.0143537
 -0.0177346   -0.0187583
 -0.0223889   -0.0249335
 -0.026566    -0.0309111
 -0.0296123   -0.0357521
 -0.0300321   -0.0375895
 -0.0307402   -0.039842
 -0.0315381   -0.0421342
 -0.0322097   -0.0442427
 -0.0327704   -0.0462476
  ⋮           
 -0.0117899   -0.0500712
 -0.00932096  -0.037935
 -0.00650043  -0.023933
 -0.0046385   -0.0152227
 -0.00413637  -0.0130638
 -0.0041055   -0.01341
 -0.00411436  -0.0136608
 -0.00414631  -0.0141943
 -0.00434579  -0.0156346
```



191-element Vector{Int64}:
  79
  80
  78
  77
  76
  75
  81
  74
  73
  72
   ⋮
 183
 184
 185
 186
 191
 190
 187
 189
 188


```julia
scatter(sensor1_data[:, "azimuth"], sensor1_data[:, loaded_waves_s1[1]],
        legend = false, xlabel = "ϕ solar azimuth", ylabel = "λ 395 nm",
        title = "Azimuth and Highest-Loaded λ 395 nm")
```



Very interesting bivariate characteristics, which could have something to do with the angle with which light hits the sensor.

# Principal Component Regression
Prepare DataFrames for PCR:
5450×10 DataFrame
  Row │ λ581      λ585      λ578      λ575      pc1        pc2        fChl     ⋯
      │ Float64   Float64   Float64   Float64   Float64    Float64    Float64  ⋯
──────┼─────────────────────────────────────────────────────────────────────────
    1 │  4.50204   4.3569    4.51449   4.47702  -20.9288   -3.42005      0.45  ⋯
    2 │  4.00588   3.88152   4.02123   3.99219  -16.5679   -3.33129      0.45
    3 │  3.02644   2.93134   3.03881   3.01685   -8.06414  -2.79424      0.45
    4 │  2.41427   2.33619   2.42291   2.40394   -2.23738  -1.93657      0.41
    5 │  3.46081   3.35699   3.4733    3.44782  -11.8552   -3.09282      0.44  ⋯
    6 │  1.77984   1.72738   1.78592   1.7732     3.57804  -1.19776      0.45
    7 │  1.95211   1.89978   1.95633   1.94106    1.92374  -1.28348      0.41
    8 │  1.63684   1.59235   1.63682   1.62055    4.75483  -0.874427     0.46
  ⋮   │    ⋮         ⋮         ⋮         ⋮          ⋮          ⋮         ⋮     ⋱
 5444 │  9.09125   8.85478   9.1629    9.16148  -54.1377   -3.12805      0.47  ⋯
 5445 │  5.65465   5.50109   5.70242   5.70549  -26.5595   -1.68912      0.46
 5446 │  8.74675   8.54346   8.79045   8.76625  -49.0942    1.69931      0.45
 5447 │  7.86277   7.69318   7.8916    7.86634  -48.5837   -5.52516      0.48
 5448 │  7.52499   7.36416   7.55528   7.53217  -44.4423   -4.07093      0.46  ⋯
 5449 │  4.86951   4.7456    4.90438   4.89938  -20.8424   -1.76945      0.45
 5450 │  4.8626    4.74664   4.89528   4.89425  -25.1522   -6.34717      0.47
                                                 3 columns and 5435 rows omitted



## Modeling Results
1. __Sensor 1__
```julia
lm1_Chl = lm(@formula(fChl ~ pc1), lm_s1_data)
```

```
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Vector{Float64}}, G
LM.DensePredChol{Float64, LinearAlgebra.CholeskyPivoted{Float64, Matrix{Flo
at64}}}}, Matrix{Float64}}

fChl ~ 1 + pc1

Coefficients:
───────────────────────────────────────────────────────────────────────────
──────
                   Coef.   Std. Error       t  Pr(>|t|)    Lower 95%    Upp
er 95%
───────────────────────────────────────────────────────────────────────────
──────
(Intercept)   0.494738    0.000725968  681.49    <1e-99   0.493315     0.49
6162
pc1          -2.20124e-6  5.58219e-7    -3.94    <1e-04  -3.29557e-6  -1.10
691e-6
───────────────────────────────────────────────────────────────────────────
──────
```



```julia
lm1_Turbidity = lm(@formula(Turbidity ~ pc1), lm_s1_data)
```

```
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Vector{Float64}}, G
LM.DensePredChol{Float64, LinearAlgebra.CholeskyPivoted{Float64, Matrix{Flo
at64}}}}, Matrix{Float64}}

Turbidity ~ 1 + pc1

Coefficients:
───────────────────────────────────────────────────────────────────────────
──
                 Coef.  Std. Error       t  Pr(>|t|)   Lower 95%    Upper 9
5%
───────────────────────────────────────────────────────────────────────────
──
(Intercept)  8.52871    0.0503327   169.45    <1e-99  8.43004     8.62738
pc1          7.6817e-5  3.87023e-5    1.98    0.0472  9.45042e-7  0.0001526
89
───────────────────────────────────────────────────────────────────────────
──
```



```julia
lm1_DO = lm(@formula(DO ~ pc1), lm_s1_data)
```

```
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Vector{Float64}}, G
LM.DensePredChol{Float64, LinearAlgebra.CholeskyPivoted{Float64, Matrix{Flo
at64}}}}, Matrix{Float64}}

DO ~ 1 + pc1

Coefficients:
───────────────────────────────────────────────────────────────────────────
────
                   Coef.  Std. Error       t  Pr(>|t|)    Lower 95%   Upper
 95%
───────────────────────────────────────────────────────────────────────────
────
(Intercept)  6.10183      0.00889685  685.84    <1e-99  6.08439      6.1192
7
pc1          0.000125059  6.84106e-6   18.28    <1e-71  0.000111648  0.0001
3847
───────────────────────────────────────────────────────────────────────────
────
```





1. __Sensor 2__
```julia
lm2_Chl = lm(@formula(fChl ~ pc1), lm_s2_data)
```

```
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Vector{Float64}}, G
LM.DensePredChol{Float64, LinearAlgebra.CholeskyPivoted{Float64, Matrix{Flo
at64}}}}, Matrix{Float64}}

fChl ~ 1 + pc1

Coefficients:
───────────────────────────────────────────────────────────────────────────
─────
                   Coef.   Std. Error       t  Pr(>|t|)    Lower 95%   Uppe
r 95%
───────────────────────────────────────────────────────────────────────────
─────
(Intercept)   0.494738    0.000726867  680.64    <1e-99   0.493313    0.496
163
pc1          -5.84374e-6  2.50864e-5    -0.23    0.8158  -5.50231e-5  4.333
57e-5
───────────────────────────────────────────────────────────────────────────
─────
```



```julia
lm2_Turbidity = lm(@formula(Turbidity ~ pc1), lm_s2_data)
```

```
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Vector{Float64}}, G
LM.DensePredChol{Float64, LinearAlgebra.CholeskyPivoted{Float64, Matrix{Flo
at64}}}}, Matrix{Float64}}

Turbidity ~ 1 + pc1

Coefficients:
───────────────────────────────────────────────────────────────────────────
───
                   Coef.  Std. Error       t  Pr(>|t|)    Lower 95%  Upper 
95%
───────────────────────────────────────────────────────────────────────────
───
(Intercept)   8.52793     0.0503434   169.40    <1e-99   8.42924     8.6266
2
pc1          -0.00166471  0.00173751   -0.96    0.3381  -0.00507092  0.0017
415
───────────────────────────────────────────────────────────────────────────
───
```



```julia
lm2_DO = lm(@formula(DO ~ pc1 + pc2), lm_s2_data)
```

```
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Vector{Float64}}, G
LM.DensePredChol{Float64, LinearAlgebra.CholeskyPivoted{Float64, Matrix{Flo
at64}}}}, Matrix{Float64}}

DO ~ 1 + pc1 + pc2

Coefficients:
───────────────────────────────────────────────────────────────────────────
───
                  Coef.   Std. Error       t  Pr(>|t|)   Lower 95%   Upper 
95%
───────────────────────────────────────────────────────────────────────────
───
(Intercept)  6.10162     0.00912595   668.60    <1e-99  6.08373     6.11951
pc1          0.00183729  0.000314965    5.83    <1e-08  0.00121984  0.00245
475
pc2          0.0117876   0.00298849     3.94    <1e-04  0.00592899  0.01764
62
───────────────────────────────────────────────────────────────────────────
───
```





# Conclusions and Next Steps
##### Regression Results
My prinary goal was to write the necessary code to perform this analysis on future datasets. That being said, I'm quite pleased to see statistical evidence of an effect of the principal components on some of the water chemistry constituents (for example, `Dissolved Oxygen, mg/L`, p < 0.0001). I'm unsure of the interpretability of the regression coefficients, since I did not zero and scale the data before the analysis, but it's great to see some results even on the raw data from only two of the three sensors.

##### Next Steps
1. First, I want to research the necessity of zeroing and normalizing the data. If this is required, I can add this step to the preprocessing.

1. Further data cleaning by removing data collected at night: The water chemistry data isn't helpful if the light intensities are zero at night, so I will filter values by day/night WHERE 70 > "azimuth" > 290.

1. Fitting the PCA model can't handle `missing` values, so the "checkerboard" UNION needs to be fixed. So, to continue the analysis on a full data set from both sensors, I'll need to JOIN the individual data sets on `datetime_15. This may not be necessary if we implement the algorithm to account for the three sensors.

1. Assuming these steps are taken, we will have a full pipeline to preprocess and conduct a PCR on our future radiometer deployments!

# References
1. Julia Documentation: [MultivariateStats](https://multivariatestatsjl.readthedocs.io/en/latest/pca.html#)

1. Wikipedia: [Principal Component Regression](https://en.wikipedia.org/wiki/Principal_component_regression)

1. Stack Exchange CrossValidated: [How can top principal components retain the predictive power on a dependent variable (or even lead to better predictions)?](https://stats.stackexchange.com/questions/141864/how-can-top-principal-components-retain-the-predictive-power-on-a-dependent-vari)

1. MATLAB Documentation: [Partial Least Square Regression and Principal Components Regression](https://www.mathworks.com/help/stats/partial-least-squares-regression-and-principal-components-regression.html)

1. Boehmke, B. and Greenwell, B. (2020) Hands-On Machine Learning with R: [Chapter 17 - Principal Components Analysis](https://bradleyboehmke.github.io/HOML/pca.html#finding-principal-components)