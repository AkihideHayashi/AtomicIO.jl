module XYZ
include("Common.jl")
export write_xyz, read_xyz


function write_xyz(fp::IOStream, symbols, positions)
    for pos in positions
        write(fp, "$(size(pos, 1))\n\n")
        for i in 1:length(symbols)
            write(fp, "$(symbols[i])  " * fmt_vec3(pos[i, :]) * "\n")
        end
        flush(fp)
    end
end

function write_xyz(path::String, symbols, positions)
    open(path) do fp
        write_xyz(fp, symbols, positions)
    end
end

function read_a_xyz(fp::IOStream)
    n = fp |> readline |> x -> parse(Int64, x)
    readline(fp)
    symbols = Vector{String}()
    coordinates = []
    for i in 1:n
        line = fp |> readline |> split
        push!(symbols, String(line[1]))
        push!(coordinates, parse.(Float64, line[2:end]))
    end
    symbols, hcat(coordinates...)'
end

function read_xyz(fp::IOStream)
    mols = []
    while true
        push!(mols, read_a_xyz(fp))
        if eof(fp)
            break
        end
    end
    mols
end

function read_xyz(path::String)
    open(path) do fp
        read_xyz(fp)
    end
end

end