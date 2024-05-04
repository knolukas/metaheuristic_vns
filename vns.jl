# Hardcode für die gegebenen Daten
using Random
using JuMP
using CPLEX

# Initialisieren der Parameter
n = 100  # Anzahl der Kunden
m = 10   # Anzahl der Einrichtungen

# Generieren der Kostenmatrix c
c = rand(1:100, n, m)  # Transportkosten, zufällige positive Integer zwischen 1 und 100

# Generieren des Vektors für die Öffnungskosten der Einrichtungen
opening_costs = rand(100:500, m)  # Öffnungskosten, zufällige positive Integer zwischen 100 und 500

# Generieren der Präferenzmatrix w
w = zeros(Int, n, m)
for i in 1:n
    w[i, :] = shuffle(1:m)  # Zufällige Anordnung der Präferenzen 1 bis 10 für jeden Kunden
end

#maximale Anzahl geöffneter Factories
max_fac = 4


# Build Solution 1
function build_solution1(n::Int64, m::Int64, c::Matrix{Int64}, o::Vector{Int64}, max_fac::Int64)
    
    #Initialize decision variable with zeros
    #create model
    model = Model(CPLEX.Optimizer)
    set_silent(model)
    #make the variables
    @variable(model, x[1:n, 1:m], Bin)
    @variable(model, y[1:m], Bin)

    #create objective function
    @objective(model, Min, sum(c[i,j]*x[i,j] for i in 1:n for j in 1:m) + sum(o[j] * y[j] for j in 1:m))

    #create constraints
    @constraint(model, open_facilities[j = 1:m], sum(x[i,j] for i in 1:n) <= y[j]*n)
    @constraint(model, max_facilities, sum(y[j] for j in 1:m) <= max_fac)
    # every customer gets served by one factory
    @constraint(model, cust_serv[i = 1:n], sum(x[i,j] for j in 1:m) == 1)
    optimize!(model)
    return model, x , y
end
model, x, y  = build_solution1(n, m, c, opening_costs, max_fac)
value.(x)
value.(y)

# Build Solution 2
function build_solution2(n::Int64, m::Int64, c::Matrix{Int64}, max_fac::Int64)
    #choose randomly which factories are opened
    y = randperm(10)[1:max_fac]
    x = zeros(Int,n,m)
    #always assign customer to cheapest opened facility
    for i in 1:n
        index = argmin(c[i, y])
        index = y[index]
        x[i,index] =1
    end
    return x, y
end
x2, y2 = build_solution2(n, m, c, max_fac)
x2

# Local Seach 1
function steepest_descent(neighborhood)
    best_neighbor = neighborhood[1]
    best_neighbor_obj_value = objective(best_neighbor)
    
    for neighbor in neighborhood[2:end]
        neighbor_obj_value = objective(neighbor)
        if neighbor_obj_value < best_neighbor_obj_value
            best_neighbor = neighbor
            best_neighbor_obj_value = neighbor_obj_value
        end
    end
    
    return best_neighbor, best_neighbor_obj_value
end

# Local Search 2
function tabu_search(neighborhood, tabu_tenure)
    best_solution = neighborhood[1]
    best_solution_obj_value = objective(best_solution)
    
    tabu_list = Set{Any}()
    
    for neighbor in neighborhood
        if neighbor in tabu_list
            continue
        end
        
        neighbor_obj_value = objective(neighbor)
        
        if neighbor_obj_value < best_solution_obj_value
            best_solution = neighbor
            best_solution_obj_value = neighbor_obj_value
        end
        
        # Add the current neighbor to the tabu list
        push!(tabu_list, neighbor)
        
        # Maintain tabu list size
        if length(tabu_list) > tabu_tenure
            popfirst!(tabu_list)
        end
    end
    
    return best_solution, best_solution_obj_value
end

# Acceptance decision
function acceptance_decision(initial_value, updated_value)
    return (objective(updated_value) > objective(initial_value))
end


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
