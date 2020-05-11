#===============================================================================
    Data modeling WHO suicide data
    Goal is to make a model to predict suicide rates
===============================================================================#
# Setting working directory
cd("/home/gxyau/Documents/github/who_suicide_rates/")

using CSV, DataFrames # Needed to load CSV

# Read in data
rawdata = CSV.read("stats_modeling_data.csv")
data = copy(rawdata) # working copy

# Inspect data
println(names(data))
println(head(data,10))
println(describe(data))

# Categorical data
categorical!(data, [:country, :sex, :age])

# Constants for this data set
const row_number = nrow(data)
const col_number = ncol(data) - 1 # One of the columns is y, our response

#=
    Defining X, y
=#
X = convert(Matrix, select(data, Not([:suicides_100k_pop, :country, :age, :sex])))
y = convert(Matrix, select(data, :suicides_100k_pop))

#=
    COMMENT: Only HDI has missing values.
=#

#===============================================================================
    Gradients descent
===============================================================================#
using Flux, LinearAlgebra, Random # Only need Flux.Tracker though, will see the need in the future
Random.seed!(1)

function update_variables(X, Y, W, b)
    # X is m by n matrix, the response is m by d matrix
    # alpha is step size
    Ŷ  = X*W .+ b
    println(W)
    println(b)
    gs = gradient(() -> sum((Y - Ŷ).^2), params(W,b))
    Ŵ  = gs[W]
    b̂  = gs[b]
    println((Ŵ, b̂))
    return (Ŵ = Ŵ, b̂ = b̂)
end

function gradient_descent(X,Y,α=0.1,iterations=1000)
    m = size(X)[1]; n = size(X)[2]; d = size(Y)[2]
    W  = rand(n,d)
    b  = rand(d,1)
    for i in 1:iterations
        W, b = update_variables(X,Y,W,b)
    end
    error = sum(Y - (X*W .+ b)).^2
    return (W = W, b = b, error = error)
end

#===============================================================================
    Gradient descent
===============================================================================#
res = gradient_descent(X,y)
