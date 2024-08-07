# Hardcode für die gegebenen Daten
using Random
using DelimitedFiles

##################### start with functions ################################################

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
function build_solution_2(num_fac::Int64)
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
            pref_new[i,j] = w[i,j] * -1 * plants[j]
            if plants[j] == 0
                pref_new[i,j] = -100000000000000
            end
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
function local_search(assignment, plants, max_iterations, k::Int64) # k aus neighborhood einfügen
    current_plant = plants
    current_assignment = assignment
    current_cost = generate_objective_value(assignment, plants)
    
    for i in 1:max_iterations
        neighbor_plants = generate_neighbor(current_plant, k) #k einfügen
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


function variable_neighborhood_search(max_iterations)
    assignment, plant = build_solution()
    best_assignment = copy(assignment)  # Julia's `copy` function is used to create a deep copy of the array
    best_plant = copy(plant)
    best_objective_value = 1000000000000
    k = 1
    count = 0

    while count < max_iterations
        plant_neighbor = generate_neighbor(plant, k)
        assignment_prime, plant_prime, objective_value = local_search(assignment, plant_neighbor, max_iterations, k)


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
    #println(best_objective_value)
    return best_assignment, best_plant, best_objective_value
end

#k genau in der anderen Reihenfolge einfügen

#################################################################################################
#################################################################################################
# Variable neighborhood adapated function
#################################################################################################
#################################################################################################
function variable_neighborhood_search_2(max_iterations::Int64)
    assignment, plant = build_solution_2(1)
    best_assignment = copy(assignment)  # Julia's `copy` function is used to create a deep copy of the array
    best_plant = copy(plant)
    best_objective_value = Inf
    k = 1
    #local_search_runtimes = []

    for num_facilities in 1:floor(Int,(m)/4)
        assignment, plant = build_solution_2(num_facilities)
        count = 0
        while count < max_iterations
            plant_neighbor = generate_neighbor(plant, 1) # changed k to 1 as explained by Sinnl
            # Measure the runtime of the local_search function
            #local_search_time = @elapsed begin

            assignment_prime, plant_prime, objective_value = local_search(assignment, plant_neighbor, max_iterations, k)
            #println(objective_value)

            #end
            #push!(local_search_runtimes, local_search_time)
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
    
    return best_assignment, best_plant, best_objective_value#, local_search_runtimes
end


#######################################################################################################
# Import function for instances
#######################################################################################################

function read_instance_data(file_path)

    # Lesen des gesamten Inhalts des Files
    file_content = readdlm(file_path, ' ')

    # Extrahieren der Anzahl von Kunden und Facilities aus der ersten Zeile
    num_facilities = file_content[1, 1]
    num_customers = file_content[1, 2]

    # Initialisieren der Arrays
    preference_array = Array{Int64}(undef, num_customers, num_facilities)
    opening_costs = Array{Float64}(undef, num_facilities)
    transportation_costs = Array{Float64}(undef, num_customers, num_facilities)

    # Füllen des preference_array
    for i in 1:num_customers
        for j in 1:num_facilities
            preference_array[i, j] = file_content[i + 1, j]
        end
    end

    # Füllen des opening_costs
    offset = 1 + num_customers
    for i in 1:num_facilities
        opening_costs[i] = file_content[offset + i, 1]
    end

    # Füllen des transportation_costs
    offset += num_facilities
    for i in 1:num_customers
        for j in 1:num_facilities
            transportation_costs[i, j] = file_content[offset + i, j]
        end
    end

    return num_customers, num_facilities, preference_array, opening_costs,  transportation_costs
end


######################## Main Script #####################################################

#get all instances names 
directory = "data/"
filenames = readdir(directory)

#initialize values so that the are globally visible
objective_values_all_instances = []
n= 0
m= 0
w=Array
opening_costs=Array
c = Array
 @time for instance in filenames
    Random.seed!(123)
    println(instance)
    n, m, w, opening_costs, c = read_instance_data(string(directory,instance))
    
    assignment, plants, objective_value = variable_neighborhood_search_2(10)

    push!(objective_values_all_instances, objective_value)

end

#for initial solution with fixed opened facilities
objective_values_all_instances = []
max_fac = 4

@time for instance in filenames
    Random.seed!(123)
    println(instance)
    n, m, w, opening_costs, c = read_instance_data(string(directory,instance))
    
    assignment, plants, objective_value = variable_neighborhood_search_2(20)
    push!(objective_values_all_instances, objective_value)

end

objective_values_all_instances
#only used to export the results to a csv file
using Pkg
Pkg.add("DataFrames")
Pkg.add("CSV")
using DataFrames
using CSV

#exporting filenames
CSV.write("filennames.csv", Tables.table(filenames),delim=';',decimal=',')
#for 4 fixed opened facilities:


CSV.write("varOpenFac_100.csv", Tables.table(objective_values_all_instances),delim=';',decimal=',')

#check for runtime of local Search
instance = "a100_75_1.txt"
Random.seed!(123)
println(instance)
n, m, w, opening_costs, c = read_instance_data(string(directory,instance))
@time assignment, plants, objective_value, runtime = variable_neighborhood_search_2(100)
sum(runtime)