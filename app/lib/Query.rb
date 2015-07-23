class Query

	def selectCoauthors (graph)
		query = "
			SELECT DISTINCT  ?refBy ?article (xsd:integer(?rank)) as ?rank ?nameReal ?nameRight ?nameArticle ?nameConference ?year ?nodeAuthor2
				FROM <"+graph+">
				WHERE{
				 ?article a bibo:AcademicArticle .
				 ?article dc:title ?nameArticle .
				 ?article dcterms:isReferencedBy ?refBy .
				 ?article vivo:relatedBy ?nodeAuthor .
				 ?article dcterms:issued ?year .
				 ?article bibo:presentedAt ?conference .
				 ?conference dc:title ?nameConference .

				 ?nodeAuthor vivo:relates ?nodeAuthor2 .
				 ?nodeAuthor vivo:rank ?rank .
				 ?nodeAuthor2 rdfs:label ?nameRight .

				 ?refBy bibo:identifier ?id .
				 ?refBy dc:creator ?personCreator .
				 ?personCreator rdfs:label ?nameWrong .
				 ?personCreator obo:ARG_2000028 ?nodeName .
				 ?nodeName vcard:hasName ?nameName .
				 ?nameName vcard:fn ?nameReal .

				 FILTER (!regex(str(?nodeAuthor2), concat(\"#author-\",str(?id)))) .
				 FILTER (str(?nameReal) = str(?nameWrong))
			} ORDER BY ?refBy ?nameArticle ?rank"

		first, *rest = query.split(/FROM/) 		# pega os campos dinamicamente
		cont = first.scan("?").count-1
		coAuthors = Hash.new
		coAuthors["query"] = query
		coAuthors["cont"] = cont
		return coAuthors
	end

	def selectAuthors (graph)
		query = "
			SELECT DISTINCT  ?refBy ?article (xsd:integer(?rank)) as ?rank ?nameReal ?nameRight ?nameArticle ?nameConference ?year ?nodeAuthor2
					FROM <"+graph+">
					WHERE {
					 ?article a bibo:AcademicArticle .
					 ?article dc:title ?nameArticle .
					 ?article dcterms:isReferencedBy ?refBy .
					 ?article vivo:relatedBy ?nodeAuthor .
					 ?article dcterms:issued ?year .
					 ?article bibo:presentedAt ?conference .
					 ?conference dc:title ?nameConference .

					 ?nodeAuthor vivo:relates ?nodeAuthor2 .
					 ?nodeAuthor vivo:rank ?rank .
					 ?nodeAuthor2 rdfs:label ?nameRight .

					 ?refBy bibo:identifier ?id .
					 ?refBy dc:creator ?personCreator .
					 ?personCreator rdfs:label ?nameWrong .
					 ?personCreator obo:ARG_2000028 ?nodeName .
					 ?nodeName vcard:hasName ?nameName .
					 ?nameName vcard:fn ?nameReal .

					 FILTER (regex(str(?nodeAuthor2), concat(\"#author-\",str(?id)))) .
					 FILTER (str(?nameReal) = str(?nameWrong))
	                                 		 FILTER (str(?nameReal) = str(?nameRight))
			} ORDER BY ?refBy ?nameArticle ?rank"

		first, *rest = query.split(/FROM/) 		# pega os campos dinamicamente
		cont = first.scan("?").count-1
		authors = Hash.new
		authors["query"] = query
		authors["cont"] = cont
		return authors
	end

	def insert (graph)

	end

	def delet (graph)
	end

end