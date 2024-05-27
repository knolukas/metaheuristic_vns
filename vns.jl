# Hardcode für die gegebenen Daten
using Random

##################### start with functions ################################################


# Build Solution
function build_solution(max_fac::Int64)
    #choose randomly which factories are opened
    plants = [ones(Int, max_fac); zeros(Int, m - max_fac)]
    shuffle!(plants)
    
    #always assign customer to most prefered opened facility
    assignment = assignCustomers(plants)

    return assignment, plants
end

x2, y2 = build_solution(max_fac)
x2
y2

# Funktion zur Generierung einer Nachbarlösung durch Verschieben eines Ortes in der Tour
function generate_neighbor(plants, k)
    neighbor = copy(plants)
    n = length(plants)
    
    # Sicherstellen, dass k nicht größer als die Anzahl der Elemente ist
    k = min(k, div(n, 2))

    for _ in 1:k
        idx1, idx2 = rand(1:n, 2)
        neighbor[idx1], neighbor[idx2] = neighbor[idx2], neighbor[idx1]
    end

    return neighbor
end

generate_neighbor(x2, 2)

# Kostenfunktion (Mulitplikation von Opening Matrix and Cost Matrix)
function generate_objective_value(assignment::Matrix{Int64})
    sum = 0
    for i in 1:100
        for j in 1:10
            sum += assignment[i,j]*c[i,j]
        end
    end
    return sum #objective value
end


function assignCustomers(plants)
    # 10 ist das beste 1 das schlechteste
    pref_new = zeros(Int, n,m)
    for i in 1:n
        for j in 1:m 
            pref_new[i,j] = w[i,j] * plants[j]
        end
    end

    assignment = zeros(Int, n, m)
    for i in 1:n
        best_pref = argmax(pref_new[i,:])
        assignment[i, best_pref] = 1
    end
    
    return assignment

end


# Einfache Nachbarschaftssuche mit gegebener Initiallösung
function local_search(assignment, plants, max_iterations) # k aus neighborhood einfügen
    current_plant = plants
    current_cost = generate_objective_value(assignment)
    
    for i in 1:max_iterations
        neighbor_plants = generate_neighbor(current_plant, 1) #k einfügen
        neibhbor_assignment = assignCustomers(neighbor_plants)
        neighbor_cost = generate_objective_value(neibhbor_assignment)
        
        if neighbor_cost < current_cost
            current_plant = neighbor_plants
            current_assignment = neibhbor_assignment
            current_cost = neighbor_cost
        end
    end
    
    return current_plant, current_assignment, current_cost
end

local_search(x2, y2, 1000)

a = generate_objective_value(x2)

# Local Search 2
function tabu_search(solution, tabu_tenure, inital_objective_value)
    best_solution = solution[1]
    best_solution_obj_value = inital_objective_value
    
    tabu_list = Set{Any}()
    
    for value in solution
        if value in tabu_list
            continue
        end
        
        solution_obj_value = generate_objective_value(neighbor)
        
        if solution_obj_value < best_solution_obj_value
            best_solution = neighbor
            best_solution_obj_value = solution_obj_value
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
    return (generate_objective_value(updated_value) > generate_objective_value(initial_value))
end

#################################################################################################
#################################################################################################
# main Function
#################################################################################################
#################################################################################################


function variable_neighborhood_search(z)
    assignment, plant = build_solution2(n, m, c, max_fac)
    x_star = copy(x)  # Julia's `copy` function is used to create a deep copy of the array
    k = 1

    while count < max_iterations
        plant_prime = neighborhood_function(plant, k)
        assignment_prime, obejctive_value = local_search(assignment, plant_prime, 16)

        if acceptance_decision(x, x_double_prime)
            x = copy(x_double_prime)  # Ensure a deep copy
            k = 1

            if generate_objective_value(x) < generate_objective_value(x_star)
                x_star = copy(x)  # Ensure a deep copy
            end
        else
            k = 1 + (k % κ)
        end
        count = count + 1
    end
    return x_star
end

######################## Main Script #####################################################

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

#maximale Anzahl geöffneter Factories und Iterations
max_fac = 4
max_iterations = 10

print(variable_neighborhood_search())
