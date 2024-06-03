# Importieren der benötigten Module

        using DelimitedFiles

        # Pfad zum Input-File
        file_path = "a100_75_1.txt"

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

        # Ausgabe der Arrays zur Überprüfung
        println("Preference Array:")
        println(preference_array)

        println("Opening Costs:")
        println(opening_costs)

        println("Transportation Costs:")
        println(transportation_costs)