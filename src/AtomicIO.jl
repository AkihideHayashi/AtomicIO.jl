module AtomicIO
include("VASP.jl")
include("Element.jl")
include("XYZ.jl")
using .Element
using .VASP
using .XYZ

export read_contcar, read_poscar, write_contcar, write_poscar, read_outcar_energies, read_outcar_trajectory
export contract, expand
export atomic_number, atomic_symbol
export write_xyz, read_xyz

expand(elem, num) = vcat([fill(e, n) for (e, n) in zip(elem, num)]...)

function contract(symbols)
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

end # module
