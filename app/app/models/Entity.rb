class Entity


#######################################################
# Cria blocagem de aritgos
# --> Entrada: array of triples
# --> Saida: array of articles
#######################################################

	def createEntities (triples)
		sideA 	= triples.dup
		sideB 	= triples.dup
		entities = Array.new
		temp 	= Array.new

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
		return entities
	end

end