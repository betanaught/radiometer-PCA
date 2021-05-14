using MultivariateStats, RDatasets, Plots
plotly()

iris = dataset("datasets", "iris")

Xtr = Matrix(iris[1:2:end, 1:4])'
Xtr_labels = Vector(iris[1:2:end, 5])

Xte = Matrix(iris[2:2:end, 1:4])'
Xte_labels = Vector(iris[2:2:end, 5])

M = fit(PCA, Xtr; maxoutdim = 3)
Yte = MultivariateStats.transform(M, Xte)
Xr = reconstruct

setosa = Yte[:, Xte_labels.=="setosa"]
versigolor = Yte[:, Xte_labels.=="versicolor"]
virginica = Yte[:, Xte_labels.=="virginica"]

scatter(setosa[1,:],setosa[2,:],setosa[3,:],marker=:circle,linewidtch=0)
scatter!(versigolor[1,:],versigolor[2,:],versigolor[3,:],marker=:circle,linewidth=0)
scatter!(virginica[1,:],virginica[2,:],virginica[3,:],marker=:circle,linewidth=0)

plot!(xlabel="PC1", ylabel="PC2", zlabel="PC3")