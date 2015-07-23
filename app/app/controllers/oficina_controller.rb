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

$KCODE = 'UTF8'


class OficinaController < ApplicationController

respond_to :html, :json, :js

	def index


		# =========
		# STEP 1 - importing RDF data information
		# =========
		#query = Query.new
		#q1 = query.selectCoauthors("http://laburb.com")
		#q2 = query.selectAuthors("http://laburb.com")

		#c = ConnectionSPARQL.new
		#data = c.runQuery(q1["query"])		# recebe os dados vindos do virtuoso coauthores
	       	#data2 = c.runQuery(q2["query"])	# recebe os dados vindos do virtuoso authores

		# =========
		# STEP 2 - normalization of names and articles
		# =========

		# faz a contagem do campos
		#parse =  Normalize.new
		#tempData1 = parse.csvToArray(data, q1["cont"])	# transforma de csv para array para facilitar a manipulacao
		#tempData2 = parse.csvToArray(data2, q2["cont"])	# transforma de csv para array para facilitar a manipulacao

		#@triples = tempData1 + tempData2 			# merge coAutores e Autores

		# =========
		# STEP 3 - create similar articles block's
		# =========

		#entities = Entity.new					#
		#semanticBlock = entities.createEntities(@triples)	# cria os blocos semânticos com a distancia de leivinstein

		# =========
		# STEP 4 - load info quickly
		# =========
		arq = FileArray.new
		arq.createArq(semanticBlock, "laburb.txt")		# cria arquivo e insere os blocos semanticos
		entitiesTemp = arq.readArq("laburb.txt")		# carrega os blocos semanticos

		# =========
		# STEP 5 - Desambiguation
		# =========
		des = Desambiguation.new
		des.desambiguationEntities(entitiesTemp)


 		#@ret = Hash.new
 		#@ret["triples"] = @triples
 		#@ret["cont"] = cont
 		#@ret["article"] = @triples
		#@ret["cont"] = 5

		#logger.info @ret
		respond_with(@ret)
	end

end