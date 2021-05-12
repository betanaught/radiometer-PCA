"""
    Import and Wrangle Data ----------------------------------------------------
"""
using CSV, DataFrames

sensor1_data = CSV.read("data/rad_sensor1.csv", DataFrame)
sensor2_data = CSV.read("data/rad_sensor2.csv", DataFrame)

show(names(sensor1_data)[1:20])
sensor1_data[1:10, 1:19]
sensor1_data[1:10, ["datetime_15", "datetime_5", "Turbidity, FNU"]]

length()
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

pca_s1_data = transpose(Matrix(dropmissing(sensor1_data[:, 20:end])))
fit_s1 = fit(PCA, pca_s1_data, maxoutdim = 10)
fit_s1.proj

scatter(fit_s1.proj, sensor1_data[:, "azimuth"], legend = false)




# Very few PCs -> Sanity Check: confirm a few wavelengths are highly correlated

# Theory: first, overpowering PC is solar altitude/azimuth. Test correlation
# between fChl and azimuth

loaded_waves = sortperm(abs.(s1_fit.proj[:, 1]), rev = true)

using GLM

# lm1 = lm(@formula(Y ~ X), data)