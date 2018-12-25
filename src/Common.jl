using Printf

function writeln(fp, str)
    write(fp, str)
    write(fp, "\n")
end

fmt_float(x) = @sprintf("%24.16F", x)
fmt_vec3(x) = @sprintf("%24.16F %24.16F %24.16F", x[1], x[2], x[3])

read_vector(fp::IOStream) = String.(fp |> readline |> split)
read_matrix(fp::IOStream, n::Int64) = permutedims(hcat([read_vector(fp) for _ in 1:n]...), (2, 1))