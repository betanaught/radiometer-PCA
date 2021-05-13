"""
    Import and Wrangle Data ----------------------------------------------------
"""
using CSV, DataFrames

sensor1_data = CSV.read("data/rad_sensor1.csv", DataFrame)
sensor2_data = CSV.read("data/rad_sensor2.csv", DataFrame)

show(names(sensor1_data)[1:20])
showcols(sensor1_data)
sensor1_data[1:10, ["datetime_15", "datetime_5", "Turbidity, FNU"]]

length()
sum(completecases(sensor1_data, [:"Turbidity, FNU"]))
sum(completecases(sensor1_data, [:"azimuth"]))
completecases(sensor1_data, names(sensor1_data)[1:20])

# TODO: add wrangling steps to split s1/s2 data from single table
# TODO: filter values by day/night WHERE 70 > "azimuth" > 290
# TODO: standardize data values

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

scatter3d

scatter(sensor1_data[:, "fChl, water, in situ, RFU"], sensor1_data[:, "315.90247"], legend = false)

scatter(sensor1_data[:, "fChl, water, in situ, RFU"], sensor1_data[:, "913.04602"], legend = false)

cols = vcat("datetime_15", names(sensor1_data)[20:25])
scatter3d(sensor1_data[4:100, "datetime_15"], sensor1_data[4:100, 20], sensor1_data[4:100, 21], legend = false)
x3d = 
scatter3d(sensor1_data[4:10, cols[1]])
"""
    Principal Component Analysis -----------------------------------------------
"""
using Statistics, StatsBase, MultivariateStats

transpose(Matrix(sensor1_data[:, 20:end]))

pca_s1_data = transpose(Matrix(sensor1_data[:, 20:end]))
fit_s1 = fit(PCA, pca_s1_data, maxoutdim = 10)
fit_s1.proj

pca_s2_data = transpose(Matrix(sensor2_data[:, 20:end]))
fit_s2 = fit(PCA, pca_s1_data, maxoutdim = 10)
fit_s2.proj

MultivariateStats.transform(fit_s1, pca_s1_data)

# Very few PCs -> Sanity Check: confirm a few wavelengths are highly correlated

# Transform observations into principal component
pc1 = transpose(MultivariateStats.transform(fit_s1, pca_s1_data))[:, 1]

# Theory: first, overpowering PC is solar altitude/azimuth. Test correlation
# between fChl and azimuth

loaded_waves = sortperm(abs.(fit_s1.proj[:, 1]), rev = true)
scatter(sensor1_data[:, loaded_waves[1]], sensor1_data[:, "azimuth"], legend = false)

scatter(loaded_waves[:, 1], loaded_waves[:, 2])

scatter3d(sensor1_data[4:100, "datetime_15"], sensor1_data[4:100, loaded_waves[1]], sensor1_data[4:100, loaded_waves[2]], legend = false)

θ = (π/180) * sensor1_data[1:1000, "azimuth"]
r = sensor1_data[1:1000, "solar_alt"]
r = sensor1_data[1:1000, 46]
r = sensor1_data[1:1000, "fChl, water, in situ, RFU"][1:1000]
scatter(θ, r, proj = :polar, m = 2)

θ = (π/180) * sensor2_data[1:1000, "azimuth"]
r = sensor2_data[1:1000, "solar_alt"]
r = sensor2_data[1:1000, 46]
r = sensor2_data[1:1000, "fChl, water, in situ, RFU"][1:1000]
scatter(θ, r, proj = :polar, m = 2)

"""
    Linear Modeling ------------------------------------------------------------
"""
using GLM
# Top 5 wavelengths
names(sensor1_data)[loaded_waves[1:5] .+ 20]

λ462 = sensor1_data[:, loaded_waves[1] + 20]
λ466 = sensor1_data[:, loaded_waves[2] + 20]
λ479 = sensor1_data[:, loaded_waves[3] + 20]
λ459 = sensor1_data[:, loaded_waves[4] + 20]
y = sensor1_data[:, "fChl, water, in situ, RFU"]
lmdata = DataFrame(fChl=y, pc1=pc1, λ462=λ462, λ466=λ466, λ479=λ479, λ459=λ459)

lm1 = lm(@formula(Y ~ λ462 + λ466 + λ479 + λ459), lmdata)
lm2 = lm(@formula(Y ~ λ462), lmdata)
lm3 = lm(@formula(Y ~ λ462 + λ466), lmdata)

lm4 = lm(@formula(Y ~ pc1), lmdata)