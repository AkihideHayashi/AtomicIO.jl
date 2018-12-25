module XYZ
include("Common.jl")
export write_xyz, read_xyz


function write_xyz(fp::IOStream, symbols::Vector{String}, positions::Vector{Matrix{Float64}})
    for pos in positions
        write(fp, "$(size(pos, 1))\n\n")
        for i in 1:length(symbols)
            write(fp, "$(symbols[i])  " * fmt_vec3(pos[i, :]) * "\n")
        end
        flush(fp)
    end
end

function write_xyz(path::String, symbols::Vector{String}, positions::Vector{Matrix{Float64}})
    open(path, "w") do fp
        write_xyz(fp, symbols, positions)
    end
end

function read_a_xyz(fp::IOStream)
    n = fp |> readline |> x -> parse(Int64, x)
    readline(fp)
    symbols = fill("", n)
    coordinates = fill(0.0, (n, 3))
    for i in 1:n
        line = fp |> readline |> split
        symbols[i] = String(line[1])
        coordinates[i, :] = parse.(Float64, line[2:end])
    end
    symbols, coordinates
end

function read_xyz(fp::IOStream)
    symbols::Vector{Vector{String}} = []
    coordinates::Vector{Matrix{Float64}} = []
    while true
        s, c = read_a_xyz(fp)
        push!(symbols, s)
        push!(coordinates, c)
        if eof(fp)
            break
        end
    end
    symbols, coordinates
end

function read_xyz(path::String)
    open(path) do fp
        read_xyz(fp)
    end
end

end