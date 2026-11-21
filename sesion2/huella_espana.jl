# =====================================================================
#  Huella de carbono del consumo español por país emisor, 2022
#  Réplica del indicador oficial de Eurostat (env_ac_ghgfp) con la
#  tabla input-output multirregional FIGARO y el modelo de Leontief
# =====================================================================
#
#  Datos (carpeta datos/, junto a este fichero). Si no están, el
#  script los descarga la primera vez.
#   1. FIGARO 2022, edición 2026, industria por industria (CSV, 49 MB)
#   2. Huellas de gases de efecto invernadero de Eurostat (CSV, 0,7 MB)
#
#  Paquetes (una sola vez):  using Pkg; Pkg.add(["CSV", "DataFrames"])
# =====================================================================

using CSV, DataFrames, LinearAlgebra, Printf, Downloads

const DATOS    = joinpath(@__DIR__, "datos")
const F_FIGARO = joinpath(DATOS, "matrix_eu-ic-io_ind-by-ind_26ed_2022.csv")
const F_EMIS   = joinpath(DATOS, "env_ac_ghgfp_2022.csv")
const URL_FIGARO = "https://circabc.europa.eu/d/d/workspace/SpacesStore/" *
    "f1330ee5-2841-4f3a-949c-20f36d068714/matrix_eu-ic-io_ind-by-ind_26ed_2022.csv"
const URL_EMIS = "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/" *
    "env_ac_ghgfp/A.TOTAL..WORLD+ES..?format=SDMX-CSV&startPeriod=2022&endPeriod=2022"

mkpath(DATOS)
isfile(F_FIGARO) || Downloads.download(URL_FIGARO, F_FIGARO)
isfile(F_EMIS)   || Downloads.download(URL_EMIS, F_EMIS)

# ---------------------------------------------------------------------
# 1. Leer la tabla FIGARO
# ---------------------------------------------------------------------
# Cada fila y cada columna de producción es un par país_rama (AL_A01,
# ES_C20...): 50 países × 64 ramas = 3.200 sectores. Las últimas
# columnas son la demanda final de cada país en 5 componentes.
t = @elapsed fig = CSV.read(F_FIGARO, DataFrame)
@printf("Tabla FIGARO leída en %.1f s: %d filas × %d columnas\n", t, nrow(fig), ncol(fig) - 1)

COMP_DF = ["P3_S13", "P3_S14", "P3_S15", "P51G", "P5M"]   # componentes de la demanda final
pais(c) = split(c, "_"; limit = 2)[1]
resto(c) = split(c, "_"; limit = 2)[2]

columnas = names(fig)[2:end]
sectores = filter(c -> !(resto(c) in COMP_DF), columnas)   # 3.200 sectores
cols_df  = filter(c -> resto(c) in COMP_DF, columnas)      # 250 columnas de demanda final
n = length(sectores)
@assert String.(fig.rowLabels[1:n]) == sectores "filas y columnas en distinto orden"

# Z: consumos intermedios en millones de euros. z_ij es lo que el sector j
#    compra al sector i.
# F: demanda final de todos los países (n × 250)
# x: producción total de cada sector = ventas intermedias + demanda final
Z = Matrix{Float64}(fig[1:n, sectores])
F = Matrix{Float64}(fig[1:n, cols_df])
x = vec(sum(Z; dims = 2)) .+ vec(sum(F; dims = 2))

# y: demanda final de España (consumo de hogares, ISFLSH y AAPP,
#    inversión y variación de existencias), venga de donde venga lo que compra
y = vec(sum(F[:, pais.(cols_df) .== "ES"]; dims = 2))
@printf("Demanda final de España: %.0f M€\n", sum(y))

# ---------------------------------------------------------------------
# 2. Modelo de Leontief
# ---------------------------------------------------------------------
# A: coeficientes técnicos, a_ij = z_ij / x_j (euros del sector i por
#    euro producido por j). Los sectores sin producción quedan a cero.
# L: inversa de Leontief, L = (I − A)⁻¹
# q: producción que hace falta en cada país y rama para atender la
#    demanda española, q = L y
xs = ifelse.(x .> 0, x, 1.0)
A = Z ./ xs'
t = @elapsed L = inv(I - A)
@printf("Inversa de Leontief (%d × %d) calculada en %.1f s\n", n, n, t)
q = L * y

# Comprobación: q debe cumplir q = A q + y
@printf("Comprobación q = A q + y, error máximo: %.1e M€\n", maximum(abs.(q .- (A * q .+ y))))

# ---------------------------------------------------------------------
# 3. Emisiones por país y rama (Eurostat)
# ---------------------------------------------------------------------
# El fichero de Eurostat trae la huella de cada país de destino. Con
# c_dest = WORLD (todos los destinos) y por rama, son las emisiones
# directas de cada país y rama, E. Con c_dest = ES y nace_r2 = TOTAL, es
# la cifra oficial de la huella española por país emisor.
em = CSV.read(F_EMIS, DataFrame)

# FIGARO y Eurostat no usan exactamente los mismos códigos
PAIS_EUROSTAT = Dict("GB" => "UK", "GR" => "EL", "FIGW1" => "WRL_REST", "ME" => "WRL_REST")
RAMA_EUROSTAT = Dict("C10T12" => "C10-C12", "C13T15" => "C13-C15", "C31_32" => "C31_C32",
    "D35" => "D", "E37T39" => "E37-E39", "J59_60" => "J59_J60", "J62_63" => "J62_J63",
    "M69_70" => "M69_M70", "M74_75" => "M74_M75", "N80T82" => "N80-N82",
    "O84" => "O", "P85" => "P", "Q87_88" => "Q87_Q88", "R90T92" => "R90-R92")
pais_e = [get(PAIS_EUROSTAT, pais(s), pais(s)) for s in sectores]
rama_e = [get(RAMA_EUROSTAT, resto(s), resto(s)) for s in sectores]

prod = em[em.c_dest .== "WORLD", :]
E_dict = Dict(zip(zip(prod.c_orig, prod.nace_r2), prod.OBS_VALUE))
E = [get(E_dict, (p, r), 0.0) for (p, r) in zip(pais_e, rama_e)]   # miles de t CO₂e

# d: intensidad de emisión, miles de toneladas de CO₂e por millón de euros
#    producido. Eurostat junta Montenegro con el resto del mundo, así que
#    los dos comparten intensidad.
x_grupo = Dict{Tuple{String,String},Float64}()
for (k, xi) in zip(zip(pais_e, rama_e), x)
    x_grupo[k] = get(x_grupo, k, 0.0) + xi
end
d = [x_grupo[k] > 0 ? E[i] / x_grupo[k] : 0.0 for (i, k) in enumerate(zip(pais_e, rama_e))]

# ---------------------------------------------------------------------
# 4. Huella de España por país emisor
# ---------------------------------------------------------------------
# h_i = d_i q_i: emisiones del sector i causadas por el consumo español
h = d .* q
replica = combine(groupby(DataFrame(pais = pais_e, h = h), :pais), :h => sum => :replica)

oficial = em[(em.c_dest .== "ES") .& (em.nace_r2 .== "TOTAL"), [:c_orig, :OBS_VALUE]]
rename!(oficial, :c_orig => :pais, :OBS_VALUE => :oficial)

res = innerjoin(replica, oficial; on = :pais)
res.dif = 100 .* (res.replica ./ res.oficial .- 1)
sort!(res, :oficial; rev = true)

NOMBRE = Dict("ES" => "España", "WRL_REST" => "Resto mundo", "CN" => "China",
    "US" => "EE. UU.", "RU" => "Rusia", "BR" => "Brasil", "IN" => "India",
    "FR" => "Francia", "DE" => "Alemania", "IT" => "Italia", "PL" => "Polonia",
    "PT" => "Portugal", "TR" => "Turquía", "UK" => "Reino Unido", "NL" => "Países Bajos",
    "SA" => "Arabia Saudí", "ZA" => "Sudáfrica", "ID" => "Indonesia", "JP" => "Japón")
res.nombre = [get(NOMBRE, p, p) for p in res.pais]

tot_r, tot_o = sum(res.replica), sum(res.oficial)
println("\nHuella de carbono de la demanda final española, 2022 (miles de t CO₂e)")
println("─"^64)
@printf("%-14s %12s %12s %9s %9s\n", "País", "Réplica", "Oficial", "Dif. %", "% total")
println("─"^64)
for r in eachrow(first(res, 15))
    @printf("%-14s %12.0f %12.0f %+9.2f %9.1f\n", r.nombre, r.replica, r.oficial, r.dif, 100r.oficial / tot_o)
end
println("─"^64)
@printf("%-14s %12.0f %12.0f %+9.2f %9.1f\n", "TOTAL", tot_r, tot_o, 100(tot_r / tot_o - 1), 100.0)
@printf("\nDesviación media por país: %.2f %%\n", sum(abs.(res.dif)) / nrow(res))
@printf("Emitido fuera de España: %.1f %% de la huella\n", 100(1 - res.replica[res.pais .== "ES"][1] / tot_r))
