module Vasp
using StaticArrays
using Printf
    
read_vector(fp) = String.(fp |> readline |> split)
read_matrix(fp, n) = permutedims(hcat([read_vector(fp) for _ in 1:n]...), (2, 1))
read_move(tf) = tf in ("T", "t") ? true : tf in ("F", "f") ? false : error()
expand_symbols(elem, num) = vcat([fill(e, n) for (e, n) in zip(elem, num)]...)

function fold_symbols(symbols)
    elem = [symbols[1]]
    num = [0]
    for symbol in symbols
        if elem[end] == symbol
            num[end] += 1
        else
            push!(elem, symbol)
            push!(num, 1)
        end
    end
    (elem, num)
end

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

function writeln(fp, str)
    write(fp, str)
    write(fp, "\n")
end

fmt_float(x) = @sprintf("%24.16F", x)
fmt_vec3(x) = @sprintf("%24.16F %24.16F %24.16F", x[1], x[2], x[3])

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
end
