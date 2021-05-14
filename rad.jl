"""
    Import and Wrangle Data ----------------------------------------------------
"""
using CSV, DataFrames

sensor1_data = CSV.read("data/rad_sensor1.csv", DataFrame)
sensor2_data = CSV.read("data/rad_sensor2.csv", DataFrame)
# full_data = CSV.read("data/rad_all.csv", DataFrame)

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

"""
    Exploratory Data Visualization ---------------------------------------------
"""
using Plots
plotly()

scatter(sensor1_data[:, "fChl, water, in situ, RFU"],
        sensor1_data[:, "315.90247"], legend = false,
        ylabel = "fChl", xlabel = "λ 315 nm")

scatter(sensor1_data[:, "fChl, water, in situ, RFU"],
        sensor1_data[:, "412.67889"], legend = false,
        ylabel = "fChl", xlabel = "λ 412 nm")

scatter(sensor1_data[:, "fChl, water, in situ, RFU"],
        sensor1_data[:, "913.04602"], legend = false,
        ylabel = "fChl", xlabel = "λ 913 nm")

scatter(sensor1_data[:, "362.55771"],
        sensor1_data[:, "365.89523"], legend = false,
        ylabel = "λ 362 nm", xlabel = "λ 365 nm",
        title = "Adjacent λ's; High Correlation")

scatter(sensor1_data[:, "734.18652"],
        sensor1_data[:, "750.85486"], legend = false,
        ylabel = "λ 734 nm", xlabel = "λ 750 nm",
        title = "Neighboring λ's; Less Correlation")

scatter(sensor1_data[:, "399.30185"],
        sensor1_data[:, "750.85486"], legend = false,
        ylabel = "λ 399 nm", xlabel = "λ 750 nm",
        title = "Distant λ's; Lower Correlation")

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



θ = (π/180) * sensor1_data[1:1000, "azimuth"]
r = sensor1_data[1:1000, "solar_alt"]
r = sensor1_data[1:1000, 46]
r = sensor1_data[1:1000, "fChl, water, in situ, RFU"][1:1000]
scatter(θ, r, proj = :polar, m = 2)

θ = (π/180) * sensor2_data[1:1000, "azimuth"]
r = sensor2_data[1:1000, "solar_alt"]
r = sensor2_data[1:1000, 46]
r = sensor2_data[1:1000, "fChl, water, in situ, RFU"][1:1000]
scatter(θ, r, proj = :polar, m = 2, legend = false, title = "ϕ azimuth (θ) vs. fChl (r)")

cols = vcat("datetime_15", names(sensor1_data)[20:25])
scatter3d(sensor1_data[4:100, "datetime_15"], sensor1_data[4:100, 20], sensor1_data[4:100, 21], legend = false)
x3d = 
scatter3d(sensor1_data[4:10, cols[1]])
"""
    Principal Component Analysis -----------------------------------------------
"""
using Statistics, StatsBase, MultivariateStats

transpose(Matrix(sensor1_data[:, 20:end]))

# Sensor 1 data
pca_s1_data = transpose(Matrix(sensor1_data[:, 20:end]))
fit_s1 = fit(PCA, pca_s1_data, maxoutdim = 10)
fit_s1.proj

pc1_s1 = MultivariateStats.transform(fit_s1, pca_s1_data)'[:, 1]
pc2_s1 = MultivariateStats.transform(fit_s1, pca_s1_data)'[:, 2]

# Sensor 2 data
pca_s2_data = transpose(Matrix(sensor2_data[:, 20:end]))
fit_s2 = fit(PCA, pca_s2_data, maxoutdim = 10)
fit_s2.proj

pc1_s2 = MultivariateStats.transform(fit_s2, pca_s2_data)'[:, 1]
pc2_s2 = MultivariateStats.transform(fit_s2, pca_s2_data)'[:, 2]

loaded_waves_s1 = sortperm(abs.(fit_s1.proj[:, 1]), rev = true)
loaded_waves_s2 = sortperm(abs.(fit_s2.proj[:, 1]), rev = true)

# Treat sensor1_data as training data set and sensor2_data as testing set
Ytest = MultivariateStats.transform(fit_s1, pca_s2_data'[:, 1][1:191])

# Very few PCs -> Sanity Check: confirm a few wavelengths are highly correlated

# Theory: first, overpowering PC is solar altitude/azimuth. Test correlation
# between fChl and azimuth

scatter(sensor1_data[:, "azimuth"], sensor1_data[:, loaded_waves_s1[1]],
        legend = false, xlabel = "ϕ solar azimuth", ylabel = "λ 395 nm",
        title = "Azimuth and Highest-Loaded λ 395 nm")
# Very interesting bivariate distribution; perhaps reflectance interferes
# Data most likely needs to be thinned to remove observations WHERE 90 < ϕ < 270

scatter(sensor1_data[:, loaded_waves_s1[1]], sensor1_data[:, loaded_waves_s1[2]])

scatter3d(sensor1_data[4:100, "datetime_15"],
          sensor1_data[4:100, loaded_waves_s1[1]],
          sensor1_data[4:100, loaded_waves_s1[2]], legend = false)



"""
    Linear Modeling ------------------------------------------------------------
"""
using GLM

# Top 5 wavelengths
names(sensor1_data)[loaded_waves_s1[1:5] .+ 20] # λ columns start at index 20
names(sensor2_data)[loaded_waves_s2[1:5] .+ 20]

lm_s1_data = DataFrame(λ462 = sensor1_data[:, loaded_waves_s1[1] + 20],
                       λ466 = sensor1_data[:, loaded_waves_s1[2] + 20],
                       λ479 = sensor1_data[:, loaded_waves_s1[3] + 20],
                       λ459 = sensor1_data[:, loaded_waves_s1[4] + 20],
                       fChl = sensor1_data[:, "fChl, water, in situ, RFU"],
                       pc1 = pc1_s1,
                       pc2 = pc2_s1,
                       Turbidity = sensor1_data[:, "Turbidity, FNU"],
                       DO = sensor1_data[:, "Dissolved Oxygen, mg/L"],
                       fDOM = sensor1_data[:, "fDOM, water, in situ, QSE"])

lm_s2_data = DataFrame(λ581 = sensor2_data[:, loaded_waves_s2[1] + 20],
                       λ585 = sensor2_data[:, loaded_waves_s2[2] + 20],
                       λ578 = sensor2_data[:, loaded_waves_s2[3] + 20],
                       λ575 = sensor2_data[:, loaded_waves_s2[4] + 20],
                       pc1 = pc1_s2,
                       pc2 = pc2_s2,
                       fChl = sensor2_data[:, "fChl, water, in situ, RFU"],
                       Turbidity = sensor2_data[:, "Turbidity, FNU"],
                       DO = sensor2_data[:, "Dissolved Oxygen, mg/L"],
                       fDOM = sensor2_data[:, "fDOM, water, in situ, QSE"])

#lm1 = lm(@formula(fChl ~ λ462 + λ466 + λ479 + λ459), lm_s1_data)
#lm2 = lm(@formula(fChl ~ λ462), lm_s1_data)
#lm3 = lm(@formula(Y ~ λ462 + λ466), lm_s1_data)

lm1_Chl = lm(@formula(fChl ~ pc1), lm_s1_data)
lm1_Turbidity = lm(@formula(Turbidity ~ pc1), lm_s1_data)
lm1_DO = lm(@formula(DO ~ pc1), lm_s1_data)

lm2_Chl = lm(@formula(fChl ~ pc1), lm_s2_data)
lm2_Turbidity = lm(@formula(Turbidity ~ pc1), lm_s2_data)
lm2_DO = lm(@formula(DO ~ pc1 + pc2), lm_s2_data)