function variable_neighborhood_search(build_solution, neighborhood_function, local_search, acceptance_decision, stopping_criterion, z)
    x = build_solution()
    x_star = copy(x)  # Julia's `copy` function is used to create a deep copy of the array
    k = 1

    while !stopping_criterion()
        x_prime = neighborhood_function(x, k)
        x_double_prime = local_search(x_prime)

        if acceptance_decision(x, x_double_prime)
            x = copy(x_double_prime)  # Ensure a deep copy
            k = 1

            if z(x) < z(x_star)
                x_star = copy(x)  # Ensure a deep copy
            end
        else
            k = 1 + (k % κ)
        end
    end

    return x_star
end