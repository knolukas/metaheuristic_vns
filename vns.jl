# Hardcode für die gegebenen Daten
using Random

##################### start with functions ################################################

include("import_script.jl")

# Build Solution
function build_solution()
    #choose randomly which factories are opened
    plants = [ones(Int, max_fac); zeros(Int, m - max_fac)]
    shuffle!(plants)
    
    #always assign customer to most prefered opened facility
    assignment = assignCustomers(plants)

    return assignment, plants
end


# Build Solution
function build_solution_2(num_fac)
    #choose randomly which factories are opened
    plants = [ones(Int, num_fac); zeros(Int, m - num_fac)]
    shuffle!(plants)
    
    #always assign customer to most prefered opened facility
    assignment = assignCustomers(plants)

    return assignment, plants
end

# Funktion zur Generierung einer Nachbarlösung durch Verschieben eines Ortes in der Tour
function generate_neighbor(plants, k)
    neighbor = copy(plants) 
    #n = length(plants)
    
    # Sicherstellen, dass k nicht größer als die Anzahl der Elemente ist
    k = min(k, div(m, 2))

    for _ in 1:k
        opened = findall(x -> x == 1, neighbor)
        closed = findall(x -> x == 0, neighbor)
        idx1 = rand(opened, 1)
        idx2 =  rand(closed, 1)
        neighbor[idx1], neighbor[idx2] = neighbor[idx2], neighbor[idx1]
    end

    return neighbor
end

# Kostenfunktion (Mulitplikation von Opening Matrix and Cost Matrix)
function generate_objective_value(assignment::Matrix{Int64}, plants)
    summe = 0
    for i in 1:n
        for j in 1:m
            summe += assignment[i,j]*c[i,j]
        end
    end

    total_sum = summe + sum(plants .* opening_costs)

    return total_sum #objective value
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
function local_search(assignment, plants) # k aus neighborhood einfügen
    current_plant = plants
    current_assignment = assignment
    current_cost = generate_objective_value(assignment, plants)
    
    for i in 1:max_iterations
        neighbor_plants = generate_neighbor(current_plant, 1) #k einfügen
        neighbor_assignment = assignCustomers(neighbor_plants)
        neighbor_cost = generate_objective_value(neighbor_assignment, neighbor_plants)
        
        if neighbor_cost < current_cost
            current_plant = neighbor_plants
            current_assignment = neighbor_assignment
            current_cost = neighbor_cost
        end
    end
    
    return current_assignment, current_plant, current_cost
end

# Local Search 2
# function tabu_search(solution, tabu_tenure, inital_objective_value)
#     best_solution = solution[1]
#     best_solution_obj_value = inital_objective_value
    
#     tabu_list = Set{Any}()
    
#     for value in solution
#         if value in tabu_list
#             continue
#         end
        
#         solution_obj_value = generate_objective_value(neighbor)
        
#         if solution_obj_value < best_solution_obj_value
#             best_solution = neighbor
#             best_solution_obj_value = solution_obj_value
#         end
        
#         # Add the current neighbor to the tabu list
#         push!(tabu_list, neighbor)
        
#         # Maintain tabu list size
#         if length(tabu_list) > tabu_tenure
#             popfirst!(tabu_list)
#         end
#     end

#     return best_solution, best_solution_obj_value
# end

# Acceptance decision
function acceptance_decision(initial_assignment, initial_plant, updated_assignment, updated_plant)
    return (generate_objective_value(updated_assignment, updated_plant) < generate_objective_value(initial_assignment, initial_plant))
end

#################################################################################################
#################################################################################################
# main Function
#################################################################################################
#################################################################################################


function variable_neighborhood_search()
    assignment, plant = build_solution()
    best_assignment = copy(assignment)  # Julia's `copy` function is used to create a deep copy of the array
    best_plant = copy(plant)
    best_objective_value = 1000000000000
    k = 1
    count = 0

    while count < max_iterations
        plant_neighbor = generate_neighbor(plant, k)
        assignment_prime, plant_prime, objective_value = local_search(assignment, plant_neighbor)

        if acceptance_decision(best_assignment, best_plant, assignment_prime, plant_prime)
            
            best_assignment = copy(assignment_prime)  
            best_plant = copy(plant_prime)  # Ensure a deep copy
            best_objective_value = objective_value
            # Ensure a deep copy
            k = 1

            
        else
            k += 1 
        end
        count = count + 1
    end
    return best_assignment, best_plant, best_objective_value
end

#################################################################################################
#################################################################################################
# Variable neighborhood adapated function
#################################################################################################
#################################################################################################
function variable_neighborhood_search_2()
    assignment, plant = build_solution_2(1)
    best_assignment = copy(assignment)  # Julia's `copy` function is used to create a deep copy of the array
    best_plant = copy(plant)
    best_objective_value = Inf
    count = 0
    k = 1
    
    for num_facilities in 1:m
        assignment, plant = build_solution_2(num_facilities)
        while count < max_iterations
            plant_neighbor = generate_neighbor(plant, k)
            assignment_prime, plant_prime, objective_value = local_search(assignment, plant_neighbor)
    
            if acceptance_decision(best_assignment, best_plant, assignment_prime, plant_prime)
                
                best_assignment = copy(assignment_prime)  
                best_plant = copy(plant_prime)  # Ensure a deep copy
                best_objective_value = objective_value
                # Ensure a deep copy
                k = 1
    
                
            else
                k += 1 
            end
            count = count + 1
        end
    end
    
    return best_assignment, best_plant, best_objective_value
end


######################## Main Script #####################################################

# Initialisieren der Parameter
n = 20  # Anzahl der Kunden
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
max_fac = 3
max_iterations = 10

print(variable_neighborhood_search())
println("Adapted solution")
println(variable_neighborhood_search_2())