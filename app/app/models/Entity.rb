class Entity


#######################################################
# Cria blocagem de aritgos
# --> Entrada: array of triples
# --> Saida: array of articles
#######################################################

	def createEntities (triples)

		entityYear  = Hash.new

		triples.each do | row |
			entityYear[row[7]] = Array.new
		end

		Rails.logger.info entityYear

		triples.each do | row |
			entityYear[row[7]].push(row)
		end

		entities = Array.new

		entityYear.each { | year, array |
			Rails.logger.info array.size

			sideA 	= array.dup
			sideB 	= array.dup

			sideA.each do |a|
				Rails.logger.info sideB.size
				if(sideB.size > 0) then
					ent 	  = Array.new
					newSide = Array.new

						sideB.each do |b|
							distance = Levenshtein.normalized_distance(a[5],b[5])
							if distance <= 0.2 || distance == 0.0 then
								arr = b
								ent.push(arr)
							else
								newSide.push(b)
							end
						end

					entities.push(ent)
					sideB = newSide
				end
			end

		}

		return entities
	end

end