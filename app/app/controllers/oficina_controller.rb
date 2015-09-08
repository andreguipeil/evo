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


		graphArq = graph.gsub('.com', '')
		graphArq = graphArq.gsub('http://', '')
		graphArq = graphArq.gsub('www.', '')
		graphArq = graphArq.gsub('.br', '')
		graphArq = graphArq.gsub('.org', '')
		graphArq = graphArq.gsub('.net', '')
		graphArq = graphArq.gsub('.edu', '')
		aux =  graphArq.gsub(".txt", "")

		if(File.exist?(aux) != true) then
			logger.info "aqui"
			# =========
			# STEP 1 - importing RDF data information
			# =========
			query = Query.new
			q1 = query.selectCoauthors(graph)
			q2 = query.selectAuthors(graph)

			c = ConnectionSPARQL.new

			data = c.runQuery(q1["query"])				# recebe os dados vindos do virtuoso coauthores
		       	data2 = c.runQuery(q2["query"])			# recebe os dados vindos do virtuoso authores


			# =========
			# STEP 2 - normalization of names and articles
			# =========

			# faz a contagem do campos
			parse =  Normalize.new
			tempData1 = parse.csvToArray(data, q1["cont"])	# transforma de csv para array para facilitar a manipulacao
			tempData2 = parse.csvToArray(data2, q2["cont"])	# transforma de csv para array para facilitar a manipulacao

			triples = tempData1 + tempData2 			# merge coAutores e Autores

			# =========
			# STEP 3 - create similar articles block's
			# =========

			entities = Entity.new					#
			semanticBlock = entities.createEntities(triples)		# cria os blocos semânticos com a distancia de leivinstein

			# =========
			# STEP 4 - load info quickly
			# =========
			arq = FileArray.new

			arq.createArq(semanticBlock, graphArq+'.txt')		# cria arquivo e insere os blocos semanticos
			entitiesTemp = arq.readArq(graphArq+'.txt')			# carrega os blocos semanticos

		else
			# =========
			# STEP 4 - load info quickly
			# =========
			arq = FileArray.new
			entitiesTemp = arq.readArq(graphArq+'.txt')			# carrega os blocos semanticos

		end
		# =========
		# STEP 5 - Desambiguation
		# =========
		des = Desambiguation.new
		entitySames = des.desambiguationEntities(entitiesTemp, values)	# faz os casamentos dos semelhantes
		triples = des.createTriples(entitySames, graphArq+'.nt')		#cria as triplas em um arquivo .nt

		# =========
		# STEP 6 - Store Triples
		# =========
		query = Query.new
		conn = ConnectionSPARQL.new
		triples.each do | trip |
			q = query.insert(graphArq, trip)
			data = conn.runInsert(q)
		end

		respond_with(@ret)
	end

	def navigation
		graph = params[:graph0]+":"+params[:graph1]
		logger.info graph
		q = Query.new

		query = q.navigation(graph)
		c = ConnectionSPARQL.new
		data = c.runQuery(query)

		logger.info data

	end
end