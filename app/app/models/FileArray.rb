

class FileArray


#######################################################
# Cria um arquivo representando a blocagem dos artigos
# --> Entrada: array of articles, name file
# --> Saida: object
#######################################################

	def createArq (entities, arq)
		File.open(arq, 'w') do |f2|
 			entities.each do | ent |
 				ent.each do | t |
 					f2.puts t
 				end
 				f2.puts "\n"
 			end
 		end
	end

#######################################################
# Lê arquivo contendo os blocos de artigos
# --> Entrada: nome do arquivo
# --> Saida: array de entidades
#######################################################


	def readArq (arq)
		#Rails.logger = Logger.new(STDOUT)
		entities = Array.new
		entity =  Array.new
		IO.readlines(arq).each do | line |
			if (line != "\n")
		#		Rails.logger.info line
				hash = eval(line)
				entity.push(hash)
		#		Rails.logger.info entity
			else
				if (entity.size > 0) then
					e = entity.dup
					entities.push(e)
					entity.clear
				end
			end
		end
		#Rails.logger.info entities

		#entities[0].each do |a|
		#	Rails.logger.info a
		#end
		return entities
	end

end