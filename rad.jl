using CSV, DataFrames

sensor1_data = CSV.read("data/rad_sensor1.csv", DataFrame)
names(sensor1_data)[1:20]
sensor1_data[1:10, 1:19]
sensor1_data[1:10, ["datetime_15", "datetime_5", "Turbidity, FNU"]]

length()
sum(completecases(sensor1_data, [:"Turbidity, FNU"]))
sum(completecases(sensor1_data, [:"azimuth"]))
completecases(sensor1_data, names(sensor1_data)[1:20])

for i in 1:20
    col_name = names(sensor1_data)[i]
    not_missing = sum(completecases(sensor1_data, i))
    num_missing = length(sensor1_data[!, i]) - num_present
    println(col_name, " - ", num_missing)
end
