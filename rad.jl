"""
    Import and Wrangle Data ----------------------------------------------------
"""
using CSV, DataFrames

sensor1_data = CSV.read("data/rad_sensor1.csv", DataFrame)
names(sensor1_data)[1:20]
sensor1_data[1:10, 1:19]
sensor1_data[1:10, ["datetime_15", "datetime_5", "Turbidity, FNU"]]

length()
sum(completecases(sensor1_data, [:"Turbidity, FNU"]))
sum(completecases(sensor1_data, [:"azimuth"]))
completecases(sensor1_data, names(sensor1_data)[1:20])

# Show number of missing values for non-wavelength columns
for i in 1:20
    col_name = names(sensor1_data)[i]
    not_missing = sum(completecases(sensor1_data, i))
    num_missing = length(sensor1_data[!, i]) - not_missing
    println(col_name, " - ", num_missing)
end

"""
    Principal Component Analysis -----------------------------------------------
"""
using Statistics, StatsBase, MultivariateStats
using Plots

s1_pca_data = transpose(Matrix(dropmissing(sensor1_data[:, 20:end])))
s1_fit = fit(PCA, s1_pca_data, maxoutdim = 10)
s1_fit.proj

scatter(s1_fit.prinvars, legend = false)

# Very few PCs -> Sanity Check: confirm a few wavelengths are highly correlated

loaded_waves = sortperm(abs.(s1_fit.proj[:, 1]), rev = true)

using GLM

# lm1 = lm(@formula(Y ~ X), data)