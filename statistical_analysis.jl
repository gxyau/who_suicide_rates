#===========================================================================
    Statistical Analysis WHO suicide data
    Computing various statistics and see how it changes
===========================================================================#
# Setting working directory
cd("/home/gxyau/Documents/julia/who_suicide_rates/")

# Loading required packages
using CSV, DataFrames, Statistics, GLM

# Reading raw data, and creating working copy
rawdata = CSV.read("master.csv") # raw
data = copy(rawdata) # working copy
# Renaming column names for easier access
new_col_names = [:country, :year, :sex, :age, :suicide_no,
 :population, :suicides_100k_pop, :country_year, :HDI,
 :gdp_for_year, :gdp_per_capita, :generation]
names!(data, new_col_names)
names(data)

# Changing abstract strings into categorical data
categorical!(data, [:country, :sex, :age, :generation])
levels!(data.age,["5-14 years","15-24 years","25-34 years","35-54 years","55-74 years","75+ years"])
levels!(data.generation,["G.I. Generation","Silent","Boomers","Generation X","Millenials","Generation Z"])

# removing column country_year because of its redundancy
select!(data, Not(:country_year))

# Removing element from array
function remove!(a, item)
    return deleteat!(a, findall(x->x==item, a))
end

# Unique years
uniqueyears = sort(unique(data.year))
# We don't need 2016 because data is incomplete
remove!(uniqueyears, 2016)
# Need to remove 2016 rows from data too
data = data[data.year .!= 2016, :]


# Finding unique countries
uniquecountries = unique(data.country)

#=
    COMMENT: We can view suicide_no as the total number of suicdes,
    while suicide_100k_pop is the suicide rate (needs to be divided
    by 100000)
=#

#==========================================================================
    Checking suicide_no vs suicide_100k_pop, expecting positive correlation
    since the more people suicide, the higher the suicide rate is
==========================================================================#
model_total_vs_rate = lm(@formula(suicides_100k_pop ~ suicide_no), data)
# Comment: Lol, as expected.

#==========================================================================
    Check for human development index regression
==========================================================================#
model_HDI = lm(@formula(suicides_100k_pop ~ HDI), data)
#=
    COMMENT: Pretty significant, what's surprising though is increasing
    HDI actually increase the likelyhood of suicide
=#

#==========================================================================
    What about countries? Expecting some countries has higher suicide
    rates because of culture or something.
==========================================================================#
model_country = lm(@formula(suicides_100k_pop ~ country), data)
#=
    Comment: Yeap, in general countries who are wealthier somehow
    has higher suicide rate. Wonder if they are correlated.
=#

# HDI + country, and if they interract
model_country_HDI = lm(@formula(suicides_100k_pop ~ HDI+country), data)
model_country_HDI_interract = lm(@formula(suicides_100k_pop ~ HDI&country), data)
#=
    Comment: Without interraction, the model uses country to "correct" each
    country to its suicide rate. With interraction, almost every pair is
    significant. Potential overfit since this doesn't happen when
    using country alone.
=#

#==========================================================================
    Suicide rate vs sex, expect a very significant p-value
==========================================================================#
model_sex = lm(@formula(suicides_100k_pop ~ sex), data)
#=
    Comment: Yeap.
=#

#==========================================================================
    Suicide rate vs age/generation. Generation actually gives a lot of
    information about age so expecting age and generation to be
    highly correlated
==========================================================================#
model_age = lm(@formula(suicides_100k_pop ~ age), data)
model_gen = lm(@formula(suicides_100k_pop ~ generation), data)
model_age_gen = lm(@formula(suicides_100k_pop ~ age+generation), data) # potential overfit
#=
    Comment: As expected. Notice that estimate of coefficient in generation
    is negative while in age it's positive, which corresponds to their
    respective levels.

    Comment: Lol, can't even run lm if interracting age&generation. Matrix not
    positive definite so Cholesky decomposition failed. Lolol, yeap, definitely
    highly correlated.
=#

#===============================================================================
===============================================================================#
function qqplot(obs,F⁰,title)
    nobs=length(obs)
    sort!(obs)
    quantiles⁰ = [quantile(F⁰,i/nobs) for i in 1:nobs]
    # Note that only n-1 points may be plotted, as quantile(F⁰,1) may be inf
    plot(quantiles⁰, obs, seriestype=:scatter, xlabel="Theoretical Quantiles", ylabel = "Sample Quantiles", title=title, label="" )
    plot!(obs,obs,label="")
end
