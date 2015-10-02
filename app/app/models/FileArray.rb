

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

#######################################################
# Cria um arquivo representando a blocagem dos artigos
# --> Entrada: array of articles, name file
# --> Saida: object
#######################################################

	def createArqProfiles (profiles, arq)
		File.open(arq, 'w') do |f2|
 			profiles.each do | pro |
 				f2.puts pro
 				#f2.puts "\n"
 			end
 		end
	end


#######################################################
# Lê arquivo contendo os blocos dos profiles
# --> Entrada: nome do arquivo
# --> Saida: array de profiles
#######################################################


	def readArqProfiles (arq)
		profiles = Array.new
		IO.readlines(arq).each do | line |
			if (line != "\n")
				hash = eval(line)
				profiles.push(hash)
			end
		end
		return profiles
	end

#######################################################
# Cria um arquivo com os dados da configuracao
# --> Entrada: nome, configuracoes
# --> Saida: object
#######################################################

	def createArqConfig (config, arq)
		File.open(arq, 'w') do |f2|
 			f2.puts config
 		end
	end

#######################################################
# Lê arquivo contendo as configuracoes
# --> Entrada: nome do arquivo
# --> Saida: hash com as configuracoes
#######################################################


	def readArqConfig (arq)
		config = Hash.new
		IO.readlines(arq).each do | line |
			if (line != "\n")
				config = eval(line)
			end
		end
		return config
	end


#######################################################
# Função que insere um log no arquivo
# --> Entrada: nome do arquivo e o conteudo
# --> Saida: true or false
#######################################################
	def insertLogFile (content, arquivo)

		if(File.exist?("estatistica.txt") != true) then
			File.open("estatistica.txt", 'w') do |f2|

				if(arquivo == 0) then
					f2.puts "======================"
					f2.puts "=   LOG DE CLUSTERIZAÇÃO"
					f2.puts "======================"
					f2.puts "Número de triplas: #{content.last['numero_triplas']}"
					f2.puts "Número de entidades/ano: #{content.last['numero_entidades_ano']}"
					f2.puts "Quantidade de autores por ano:"
					cont = 0;
					content.each do | y |
						if(cont < content.size) then
							f2.puts y
						end
						cont = cont+1
					end
					f2.puts "Quantidade de comparações na clusterização:"+content.last['contClusterizacao'].to_s
				else
					f2.puts "======================"
					f2.puts "=   LOG DE DESAMBIGUAÇÃO"
					f2.puts "======================"
					content.each do | c |
						f2.puts "Nivel 1: #{c['nivel1']}   // Se são diferentes um do outro"
						f2.puts "Nivel 2: #{c['nivel2']}   // Verificação da distancia"
						f2.puts "Nivel 3: #{c['nivel3']}   // Desambiguados"
						f2.puts "Nivel 4: #{c['nivel4']}   // Não desambiguados"
						f2.puts "Nivel 5: #{c['nivel5']}   // Valor acima do limiar"
						f2.puts "Nivel 6: #{c['nivel6']}   // artigos Iguais"
						f2.puts "Nivel 7: #{c['nivel7']}   // artigos muito proximos"
						f2.puts "\n"
					end

					soman1 = 0
					soman2 = 0
					soman3 = 0
					soman4 = 0
					soman5 = 0
					soman6 = 0
					soman7 = 0
					content.each do | e |
						soman1 = e['nivel1']+soman1
						soman2 = e['nivel2']+soman2
						soman3 = e['nivel3']+soman3
						soman4 = e['nivel4']+soman4
						soman5 = e['nivel5']+soman5
						soman6 = e['nivel6']+soman6
						soman7 = e['nivel7']+soman7
					end
					f2.puts "===================="
					f2.puts "=   NÍVEIS SOMADOS"
					f2.puts "===================="
					f2.puts "Nivel 1: #{soman1}   // Se são diferentes um do outro"
					f2.puts "Nivel 2: #{soman2}   // Verificação da distancia"
					f2.puts "Nivel 3: #{soman3}   // Desambiguados"
					f2.puts "Nivel 4: #{soman4}   // Não desambiguados"
					f2.puts "Nivel 5: #{soman5}   // Valor acima do limiar"
					f2.puts "Nivel 6: #{soman6}   // artigos Iguais"
					f2.puts "Nivel 7: #{soman7}   // artigos muito proximos"
					f2.puts "\n"

				end

	 		end
		else
			File.open("estatistica.txt", 'a+') do |f2|
				if(arquivo == 0) then
					f2.puts "======================"
					f2.puts "=   LOG DE CLUSTERIZAÇÃO"
					f2.puts "======================"
					f2.puts "Número de triplas: #{content.last['numero_triplas']}"
					f2.puts "Número de entidades/ano: #{content.last['numero_entidades_ano']}"
					f2.puts "Quantidade de autores por ano:"
					cont = 0;
					content.each do | y |
						if(cont < content.size-1) then
							f2.puts y
						end
						cont = cont+1
					end
					f2.puts "Quantidade de comparações na clusterização:"+content.last['contClusterizacao'].to_s
				else
					f2.puts "======================"
					f2.puts "=   LOG DE DESAMBIGUAÇÃO"
					f2.puts "======================"
					content.each do | c |
						f2.puts "Nivel 1: #{c['nivel1']}   // Se são diferentes um do outro"
						f2.puts "Nivel 2: #{c['nivel2']}   // Verificação da distancia"
						f2.puts "Nivel 3: #{c['nivel3']}   // Desambiguados"
						f2.puts "Nivel 4: #{c['nivel4']}   // Não desambiguados"
						f2.puts "Nivel 5: #{c['nivel5']}   // Valor acima do limiar"
						f2.puts "Nivel 6: #{c['nivel6']}   // artigos Iguais"
						f2.puts "Nivel 7: #{c['nivel7']}   // artigos muito proximos"
						f2.puts "\n"
					end

					soman1 = 0
					soman2 = 0
					soman3 = 0
					soman4 = 0
					soman5 = 0
					soman6 = 0
					soman7 = 0
					content.each do | e |
						soman1 = e['nivel1']+soman1
						soman2 = e['nivel2']+soman2
						soman3 = e['nivel3']+soman3
						soman4 = e['nivel4']+soman4
						soman5 = e['nivel5']+soman5
						soman6 = e['nivel6']+soman6
						soman7 = e['nivel7']+soman7
					end
					f2.puts "===================="
					f2.puts "=   NÍVEIS SOMADOS"
					f2.puts "===================="
					f2.puts "Nivel 1: #{soman1}   // Se são diferentes um do outro"
					f2.puts "Nivel 2: #{soman2}   // Verificação da distancia"
					f2.puts "Nivel 3: #{soman3}   // Desambiguados"
					f2.puts "Nivel 4: #{soman4}   // Não desambiguados"
					f2.puts "Nivel 5: #{soman5}   // Valor acima do limiar"
					f2.puts "Nivel 6: #{soman6}   // artigos Iguais"
					f2.puts "Nivel 7: #{soman7}   // artigos muito proximos"
					f2.puts "\n"
				end
	 		end
		end
	end
end