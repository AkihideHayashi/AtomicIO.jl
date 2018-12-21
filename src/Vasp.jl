module VASP
include("Common.jl")
export read_contcar, read_poscar, write_contcar, write_poscar, read_outcar_energies, read_outcar_trajectory
using StaticArrays

    
read_move(tf) = tf in ("T", "t") ? true : tf in ("F", "f") ? false : error()

function read_switch(fp)
    s = fp |> readline |> strip
    selective = false
    if s[1] in ('S', 's')
        selective = true
        s = fp |> readline |> strip
    end
    if s[1] in ('C', 'c', 'K', 'k')
        cartesian = true
    else
        cartesian = false
    end
    (selective, cartesian)
end

function read_poscar(fp::IOStream)
    system = readline(fp)
    unit = parse(Float64, readline(fp))
    cell = parse.(Float64, read_matrix(fp, 3))
    elem = read_vector(fp)
    num = parse.(Int64, read_vector(fp))
    (selective, cartesian) = read_switch(fp)
    coordinate_str = read_matrix(fp, sum(num))
    r = parse.(Float64, coordinate_str[:, 1:3])
    if selective
        move = read_move.(coordinate_str[:, 4:6])
    else
        move = fill(true, size(r))
    end
    system, unit, cell, elem, num, selective, cartesian, r, move
end

function read_contcar(fp::IOStream)
    system, unit, cell, elem, num, selective, cartesian, r, move = read_poscar(fp)
    readline(fp)
    bonus = parse.(Float64, read_matrix(fp, sum(num)))
    system, unit, cell, elem, num, selective, cartesian, r, move, bonus
end

function write_poscar(fp::IOStream, system, unit, cell, elem, num, selective, cartesian, r, move)
    writeln(fp, system)
    writeln(fp, fmt_float(unit))
    for i in 1:size(cell, 1)
        writeln(fp, fmt_vec3(cell[i, :]))
    end
    writeln(fp, "  " * join(elem, "  "))
    writeln(fp, "  " * join(num, "  "))
    if selective
        writeln(fp, "Selective Dynamics")
    end
    if cartesian
        writeln(fp, "Cartesian")
    else
        writeln(fp, "Direct")
    end
    for i in 1:size(r, 1)
        write(fp, "  " * fmt_vec3(r[i, :]))
        if selective
            write(fp, "    " * join((x -> x ? "T" : "F").(move[i, :]), "    "))
        end
        write(fp, "\n")
    end
end

function write_contcar(fp::IOStream, system, unit, cell, elem, num, selective, cartesian, r, move, mode)
    write_poscar(fp, system, unit, cell, elem, num, selective, cartesian, r, move)
    write(fp, "\n")
    for i in 1:size(mode, 1)
        writeln(fp, "  " * fmt_vec3(mode[i, :]))
    end
end


function read_poscar(path::String)
    open(path) do fp
        read_poscar(fp)
    end
end

function read_contcar(path::String)
    open(path) do fp
        read_contcar(fp)
    end
end

function write_poscar(path::String, system, unit, cell, elem, num, selective, cartesian, r, move)
    open(path) do fp
        write_poscar(fp, system, unit, cell, elem, num, selective, cartesian, r, move)
    end
end

function write_contcar(path::String, system, unit, cell, elem, num, selective, cartesian, r, move, mode)
    open(path) do fp
        write_contcar(fp, system, unit, cell, elem, num, selective, cartesian, r, move, mode)
    end
end


function read_outcar_energies(fp::IOStream)
    ens = [line |> split |> last |> x->parse(Float64, x) for line in filter(x->occursin("energy  without", x), readlines(fp))]
end

function read_outcar_energies(path::String)
    open(path) do fp
        read_outcar_energies(fp)
    end
end


const freqreader = r"(\d).*f(.+)=\s+(\d*\.\d*)\s+THz\s+(\d*\.\d*)\s+2PiTHz\s+(\d*\.\d*)\s+cm-1\s+(\d*\.\d*)\s+meV"
function read_a_freq(fp::IOStream, nions)
    fp |> readline
    ens = match(freqreader, fp|>readline)
    fp |> readline
    freq = parse.(Float64, read_matrix(fp, nions)[:, 4:6])
    if ens[2] == "  "
        u = 1
    elseif ens[2] == "/i"
        u = 1im
    else
        error()
    end
    parse(ComplexF64, ens[5]) * u, freq
end

function read_outcar_freq(fp::IOStream)
    readuntil(fp, "NIONS")
    nions = parse(Int64, split(readline(fp))[2])
    readuntil(fp, "Degree of freedom")
    nfree = parse(Int64, readline(fp) |> split |> last)
    readuntil(fp, "Eigenvectors and eigenvalues of the dynamical matrix")
    for _ in 1:3
        fp |> readline
    end
    Tuple(zip([read_a_freq(fp, nions) for _ in 1:nfree]...))
end

function read_outcar_freq(path::String)
    open(path) do fp
        read_outcar_freq(fp)
    end
end

function read_outcar_lattice(fp::IOStream)
    readuntil(fp, "direct lattice vectors")
    readline(fp)
    lattices = parse.(Float64, read_matrix(fp, 3))
    if !eof(fp)
        lattices[:, 1:3]
    else
        nothing
    end
end

function read_outcar_position_force(fp::IOStream, nions)
    readuntil(fp, "POSITION                                       TOTAL-FORCE (eV/Angst)")
    if !eof(fp)
        readline(fp)
        readline(fp)
        m = parse.(Float64, read_matrix(fp, nions))
        m[:, 1:3], m[:, 4:6]
    else
        nothing, nothing
    end
end

function read_energy(fp::IOStream)
    readuntil(fp, "energy  without entropy=")
    parse(Float64, split(readline(fp))[end])
end

function read_outcar_symbols(fp::IOStream)
    readuntil(fp, "INCAR:")
    readline(fp)
    symbols = []
    while true
        line = fp |> readline |> split .|> String
        if line[1] != "POTCAR:"
            break
        else
            push!(symbols, line[3])
        end
    end
    pop!(symbols)
    Vector{String}(symbols)
end
    

function read_outcar_trajectory(fp::IOStream)
    symbols = read_outcar_symbols(fp)
    readuntil(fp, "NIONS")
    nions = parse(Int64, split(readline(fp))[2])
    readuntil(fp, "ions per type =")
    ions_per_type = fp |> readline |> split .|> x -> parse(Int64, x)
    energies = Vector{Float64}()
    lattices = Vector{Matrix{Float64}}()
    positions = Vector{Matrix{Float64}}()
    forces = Vector{Matrix{Float64}}()
    while true
        l = read_outcar_lattice(fp)
        p, f = read_outcar_position_force(fp, nions)
        if eof(fp)
            break
        end
        e = read_energy(fp)
        push!(energies, e)
        push!(lattices, l)
        push!(positions, p)
        push!(forces, f)
    end
    symbols, ions_per_type, energies, lattices, positions, forces
end

function read_outcar_trajectory(path::String)
    open(path) do fp
        read_outcar_trajectory(fp)
    end
end

end