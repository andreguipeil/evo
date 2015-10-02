require 'net/http'
require 'cgi'
require 'csv'
require 'rubygems'
require 'active_support/all'
require "thread"
require "json"
require "Query"
require "ConnectionSPARQL"
require "Desambiguation"
require "Entity"
require "FileArray"
require "Normalize"
require 'rdf'
require 'linkeddata'
require 'rdf/ntriples'
require 'rdf/nquads'
require 'set'


$KCODE = 'UTF8'


class OficinaController < ApplicationController


respond_to :html, :json, :js

	def index
		respond_with(@ret)
	end


	def desambiguar
		values = Hash.new
		graph = params[:graph]
		values['vd'] = params[:vd]
		values['nameArticle'] = params[:nameArticle]
		values['rank'] = params[:rank]
		values['conference'] = params[:conference]
		values['year'] = params[:year]
		values['levDist'] = params[:levDist]
		arq = FileArray.new


		graphArq = graph.gsub('.com', '')
		graphArq = graphArq.gsub('http://', '')
		graphArq = graphArq.gsub('www.', '')
		graphArq = graphArq.gsub('.br', '')
		graphArq = graphArq.gsub('.org', '')
		graphArq = graphArq.gsub('.net', '')
		graphArq = graphArq.gsub('.edu', '')


		#if(File.exist?(graphArq+".txt") != true) then

			# =========
			# STEP 1 - importing RDF data information
			# =========
			query = Query.new
			dataProfiles  = query.selectProfiles(graph)
			dataAuthors = query.selectAuthors(graph)
			queryArticles = query.selectArticles(graph)

			c = ConnectionSPARQL.new
			dataName  = c.runQuery(dataProfiles["queryProfileName"])
			dataGiven  = c.runQuery(dataProfiles["queryGivenName"])
			dataFamily = c.runQuery(dataProfiles["queryFamilyName"])

			dataArticles = c.runQuery(queryArticles)
			# =========
			# STEP 2 - normalization of names and articles
			# =========

			parse =  Normalize.new
			profiles = parse.normalizeProfiles(dataName, dataGiven, dataFamily, 0)
			tempAuthors = c.runQuery(dataAuthors['query'])
			authors = parse.csvToArray(tempAuthors, dataAuthors['cont'])

			articles  = parse.normalizeArticles(dataArticles)

			#logger.info articles
			# =========
			# STEP 3 - create similar articles block's
			# =========

			entities = Entity.new						#
			#semanticBlock = entities.createEntities(authors)		# cria os blocos semânticos com a distancia de leivinstein
			#entities.clusterizationByName(authors, profiles)
			entities.clusterizationByArticle(authors, articles)
			# =========
			# STEP 4 - load info quickly
			# =========

			#arq.createArq(semanticBlock, graphArq+'.txt')		# cria arquivo e insere os blocos semanticos
			#authorsTemp = arq.readArq(graphArq+'.txt')			# carrega os blocos semanticos
			#arq.createArqProfiles(profiles, graphArq+'-profiles.txt')
			#profilesTemp = arq.readArqProfiles(graphArq+'-profiles.txt')
		#else

			# =========
			# STEP 4 - load info quickly
			# =========
			#authorsTemp = arq.readArq(graphArq+'.txt')			# carrega os blocos semanticos
			#profilesTemp = arq.readArqProfiles(graphArq+'-profiles.txt')
		#end
		#config = Hash.new
		#config['vd'] = params[:vd]
		#config['nameArticle'] = params[:nameArticle]
		#config['conference'] = params[:conference]
		#config['rank'] = params[:rank]
		#config['year'] = params[:year]
		#config['levDist'] = params[:levDist]

		#arq.createArqConfig(config, graphArq+"-config.txt")

		# =========
		# STEP 5 - Desambiguation
		# =========
		#des = Desambiguation.new
		#entitySames = des.desambiguationEntities(authorsTemp, values)	# faz os casamentos dos semelhantes
		#triples = des.createTriples(entitySames, graphArq+'.nt')		#cria as triplas em um arquivo .nt

		# =========
		# STEP 6 - Store Triples
		# =========
		#query = Query.new
		#conn = ConnectionSPARQL.new
		#triples.each do | trip |
		#	logger.info trip
			#q = query.insert(graph, trip)
			#data = conn.runInsert(q)
		#end

		respond_with(@ret)
	end

	def navigation
		graph = params[:graph0]+":"+params[:graph1]
		q = Query.new
		query = q.navigation(graph)
		c = ConnectionSPARQL.new
		data = c.runQuery(query)

		arq = FileArray.new

		logger.info graph

		graphArq = graph.gsub('.com', '')
		graphArq = graphArq.gsub('http://', '')
		graphArq = graphArq.gsub('www.', '')
		graphArq = graphArq.gsub('.br', '')
		graphArq = graphArq.gsub('.org', '')
		graphArq = graphArq.gsub('.net', '')
		graphArq = graphArq.gsub('.edu', '')
		profilesTemp = arq.readArqProfiles(graphArq+'-profiles.txt')
		contPesquisadores = profilesTemp.size
		config = arq.readArqConfig(graphArq+"-config.txt")
		logger.info config


		@send = Hash.new
		@send['graph'] = graph
		@send['researchers'] = contPesquisadores
		if(contPesquisadores < 20) then
			@send['profiles'] = profilesTemp.sort{|a,b| a['name']<=>b['name']}
		end

		respond_with(@send)
	end

	def getProfiles
		graph = params[:graph]
		nameProfile = params[:nameProfile]
		logger.info graph
		logger.info nameProfile

		query = Query.new
		queryProfiles  = query.getProfiles(graph, nameProfile)
		c = ConnectionSPARQL.new
		data = c.runQuery(queryProfiles)

		parse =  Normalize.new
		profiles = parse.normalizeProfiles(data, 0, 0, 1)
		respond_with(profiles)
	end
end