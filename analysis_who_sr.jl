#===========================================================================
    Analysis for WHO suicide data, simple analysis
    Warm up for Julia Lang
    Start Date: June 9, 2019
    ****************************************************
    Goal is to do some analysis on the data, and
    if possible, try to find signals in different
    demographics.
===========================================================================#
# Setting working directory
cd("/home/gxyau/Documents/julia/who_suicide_rates/")

# Loading required packages
using CSV, DataFrames, Statistics # Simple statistical analysis
using GLM, CategoricalArrays # For linear regression
using Colors, Plots # Plotting graphs
gr()

# Reading raw data, and creating working copy
rawdata = CSV.read("master.csv") # raw
data = copy(rawdata) # working copy
# Renaming column names for easier access
new_col_names = [:country, :year, :sex, :age, :suicide_no,
 :population, :suicides_100k_pop, :country_year, :HDI,
 :gdp_for_year, :gdp_per_capita, :generation]
rename!(data, new_col_names)
names(data)
# Summary and head of data
describe(data, :all) # requires DataFrames package
first(data, 10) # requires DataFrames package

#=
    Attempt to tidy up data
=#
# Check if there's any missing value
colmissing = [any(ismissing(col)) for col =eachcol(data)]
# only HDI has missing values

# :country + :year = :country_year?
#=
  repeatedinfo takes in a row of data and check whether
  :country and :year contains same information as
  :country_year.
  Input: String
  Output: Boolean
=#
function countryyearrepeated(rows)
    nrow = size(rows, 1)
    bool = Array{Bool,1}()

    for i in 1:nrow
        row = rows[i,:]
        verdict = (string(row.country, row.year) == row.country_year)
        push!(bool, verdict)
    end

    return bool
end
any(countryyearrepeated(data))
# So column :country_year is repeated, we remove it
select!(data, Not(:country_year))
names(data)

# Removing element from array
function remove!(a, item)
    return deleteat!(a, findall(x->x==item, a))
end

# Unique years
uniqueyears = sort(unique(data.year))
# We don't need 2016 because data is incomplete
remove!(uniqueyears, 2016)

# Finding unique countries
uniquecountries = unique(data.country)

#==========================================================================
    Seems like the data for 2016 is incomplete, omitting the
    data for year 2016
==========================================================================#
df2016 = data[data.year .== 2016, :]
dfrest = data[data.year .!= 2016, :]
# Checking the country plot for 2016
suicide2016 = Array{Int64, 1}()
for country in sort(uniquecountries)
    subtotal = sum( df2016.suicide_no[df2016.country .== country] )
    push!(suicide2016, subtotal)
end
plot(sort(uniquecountries), suicide2016, seriestype = :line, legend = false)

#===========================================================================
    Plot basic graph, number of suicides per year
===========================================================================#

# Splitting data into male and females and do individual analysis
indexmales = isequal.(data.sex, "male")
datamales = data[indexmales, :]
datafemales = data[.!(indexmales), :]

#=
    Function totalsucide sums the total number of suicide based
    on year for a given data frame.
    Input: df - data frame
    Output: dict - dictionary with year as key and total number as value
=#
function totalsuicide(df)
    # Initiate empty dictionary
    dict = Dict{Int64,Int64}( year => 0 for year in uniqueyears )
    nrow = size(df,1)

    for i in 1:nrow # for each year
        row = df[i,:] # target row
        dict[row.year] += row.suicide_no
    end

    return dict
end

# # Total male and female suicide number
# maletotal = [ totalsuicide(datamales)[year] for year in uniqueyears ]
# femaletotal = [ totalsuicide(datafemales)[year] for year in uniqueyears ]
# suicidetotal = maletotal + femaletotal

# Plot
# Basic, total, men total, women total
plot(uniqueyears, suicidetotal, seriestype = :line, label="Total")
plot!(uniqueyears, maletotal, seriestype = :line, label="Male")
plot!(uniqueyears, femaletotal, seriestype = :line, label="Female")
title!("Year vs. Number of Sucides")
xlabel!("Year")
ylabel!("Number of Suicides")
plot!(size = (1920, 1080))
savefig("gender_suicide.png")

# By country
databysuicideno = sort(data, (:suicide_no, :country, :sex), rev = true)
#Observation: Russian Federation has highest suicide rate

# Separate suicide number into countries and then by gender

# By GDP
# Converting strings to numerical value
yearlygdp = data.gdp_for_year
removecomma(str) = parse(Int,join(split(str,",")))
data.gdp_for_year = broadcast(removecomma,yearlygdp)
describe(data.gdp_for_year)
describe(data.gdp_per_capita)


# Plot for GDP vs suicide no.

# Dictionary to record suicide vs gdp_for_year
# Keys are the GDP, values are the number of suicides
totalbygdpyear = Dict{Int64, Int64}()

# Updating dictionary
for year in uniqueyears
    for country in uniquecountries
        # Check if entry exists
        if size(data[(data.year .== year) .& (data.country .== country), :])[1] > 0
            # Update dictionary
            targets = data[(data.year .== year) .& (data.country .== country), :]
            if targets.gdp_for_year[1] in keys(totalbygdpyear)
                totalbygdpyear[targets.gdp_for_year[1]] += sum(targets.suicide_no)
            else
                totalbygdpyear[targets.gdp_for_year[1]] = sum(targets.suicide_no)
            end
        end
    end
end

#=
    Filtering values of totalbygdpyear to get
    unique values
=#
plotgdpyear, plotsuicide = collect(keys(totalbygdpyear)), collect(values(totalbygdpyear))


# Consolidating the number of suicides in GDP range
plot(plotgdpyear, plotsuicide, seriestype = :line, legend = false)
#scatter!(plotgdpyear, plotsuicide, seriestype = :points)
title!("Yearly GDP vs. Number of Suicides")
xlabel!("Yearly GDP")
ylabel!("Number of Suicide")
plot!(size=(1920, 1080))
savefig("suicides_gdp.png")

#=
    Suicide of country in each year
=#
# Defining colors
cols = distinguishable_colors(length(uniqueyears) + 1, [RGB(1,1,1)])[2:end] # First one is black
# Plotting the plots
#=
    4k resolution (4096, 2160)
    1080p resolution (1920, 1080)
=#
plot(bg = :white, size = (1920, 1080), legend = :outertopright)
title!("Number of suicides (total) in every country per year")
xlabel!("Countries")
ylabel!("Number of Suicides")
for i in 1:(length(uniqueyears) - 1) #-1 because we don't want 2016
    year = uniqueyears[i] # Doing this so we can use pcols
    subdata = dfrest[dfrest.year .== year,:]
    totalbycountryperyear = Int[]
    for country in uniquecountries
        satisfiedrows = ((dfrest.year .== year) .& (dfrest.country .== country))
        if any(satisfiedrows)
            push!( totalbycountryperyear, sum(dfrest.suicide_no[satisfiedrows,:]) )
        else
            push!( totalbycountryperyear, 0 )
        end
    end
    # Need to add display to show plots in a for loop
    display( plot!(uniquecountries, totalbycountryperyear, seriestype = :scatterpath, color = cols[i], label = string(year)) )
    plotname = string("country_per_year_",i,".png")
    savefig(plotname)
end

# Number of suicides per 100k capita instead of total number
plot(bg = :white, size = (1920, 1080), legend = :outertopright)
title!("Number of suicides (per 100k capita) in every country per year")
xlabel!("Countries")
ylabel!("Number of Suicides")
for i in 1:(length(uniqueyears) - 1) # -1 because we don't want 2016
    year = uniqueyears[i] # Doing this so we can use pcols
    subdata = dfrest[dfrest.year .== year,:]
    totalbycountryperyear = Float64[]
    for country in uniquecountries
        satisfiedrows = ((dfrest.year .== year) .& (dfrest.country .== country))
        if any(satisfiedrows)
            push!( totalbycountryperyear, sum(dfrest.suicides_100k_pop[satisfiedrows,:]) )
        else
            push!( totalbycountryperyear, 0 )
        end
    end
    # Need to add display to show plots in a for loop
    display( plot!(uniquecountries, totalbycountryperyear, seriestype = :scatterpath, color = cols[i], label = string(year)) )
    plotname = string("country_per_year_100k_",i,".png")
    savefig(plotname)
end

# Need interpolation for missing value in HDI

#===========================================================================
    Basic descriptive statistics analysis, check mean, median, s.d. of
    suicide of each year, indiscriminantly
===========================================================================#
# getstats will return mean, median, and sd of array
function getstats(array)
    stats = Dict{Symbol, Float64 }(
        :mean => mean(array),
        :median => median(array),
        :sd => std(array)
    )

    return stats
end

# Suicide rate per year and average suicide rate per year
averagerate, totalsuicide, totalpopulation = zeros(length(uniqueyears)), zeros(length(uniqueyears)), zeros(length(uniqueyears))
for i in 1:length(uniqueyears)
     averagerate[i] += mean(dfrest.suicides_100k_pop[dfrest.year .== uniqueyears[i]])/100000
     totalsuicide[i] += sum(dfrest.suicide_no[dfrest.year .== uniqueyears[i]])
     totalpopulation[i] += sum(dfrest.population[dfrest.year .== uniqueyears[i]])
end
suiciderate = totalsuicide ./ totalpopulation

# Plotting average suicide rate and suicide rate
# plot(uniqueyears, suiciderate, seriestype = :line, label="Suicide Rate", size = (1920, 1080), legend = :topright)
plot(uniqueyears, suiciderate, fill = (0,0.5,:blue), seriestype = :line, label="Suicide Rate")
plot!(uniqueyears, averagerate, fill = (0,0.5,:red), seriestype = :line, label="Average Rate")
title!("Suicide Rate and Average Suicide Rate VS Year")
xaxis!(collect(minimum(uniqueyears):5:maximum(uniqueyears)))
xlabel!("Year")
ylabel!("Rate")
savefig("total_vs_average.png")

#==========================================================================
==========================================================================#
