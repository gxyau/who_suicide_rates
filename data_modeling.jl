#==========================================================================
# Data Modeling
==========================================================================#
# Setting working directory
cd("/home/gxyau/Documents/github/who_suicide_rates/")

# Loading required packages
using CSV, DataFrames, Statistics # Simple statistical analysis
using GLM, CategoricalArrays, Flux

data = CSV.read("stats_modeling_data.csv")
