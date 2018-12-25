module Element
export atomic_number, atomic_symbol

const periodic_table = string.(split("  H                                                  He
                                  Li Be                                B  C  N  O  F Ne
                                  Na Mg                               Al Si  P  S Cl Ar
                                   K Ca Sc Ti  V Cr Mn Fe Co Ni Cu Zn Ga Ge As Se Br Kr
                                  Rb Sr  Y Zr Nb Mo Tc Ru Rh Pd Ag Cd in Sn Sb Te  I Xe
                                  Cs Ba
                                        La Ce Pr Nd Pm Sm Eu Gd Tb Dy Ho Er Tm Yb Lu
                                        Hf Ta  W Re Os Ir Pt Au Hg Tl Pb Bi Po At Rn
                                  Fr Ra
                                        Ac Th Pa  U Np Pu Am Cm Bk Cf Es Fm Md No Lr
                                        Rf Db Sg Bh Hs Mt Ds Rg Cn Nh Fl Mc Lv Ts Og
                               "))

function element_mach(e, o)
    if length(e) == 1
        if o[1] == e[1]
            true
        else
            false
        end
    elseif length(e) == 2 && length(o) >= 2
        if o[1:2] == e[1:2]
            true
        else
            false
        end
    elseif length(e) == 2 && length(o) == 1
        false
    else
        error()
    end
end
        
function symbol2element(el)
    a = filter(x -> element_mach(x, el), periodic_table)
    if length(a) == 1
        a[1]
    elseif length(a) == 2
        a[end]
    else
        error()
    end
end

function atomic_number(s::String)
    findfirst(x->x==symbol2element(s), periodic_table)
end

function atomic_symbol(n::Int64)
    periodic_table[n]
end
end