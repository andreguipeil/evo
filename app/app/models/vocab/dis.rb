# -*- encoding: utf-8 -*-
# This file generated automatically using vocab-fetch from vivoext.owl
require 'rdf'
module RDF
  class DIS < RDF::StrictVocabulary("http://vivoext.org")

    # Class definitions
    term :"#Pair",
      label: "#Pair".freeze,
      type: "owl:Class".freeze

    # Property definitions
    property :"#has_dis",
      domain: "http://vivoext.org#Pair".freeze,
      label: "#has_dis".freeze,
      type: ["owl:ObjectProperty".freeze, "owl:SymmetricProperty".freeze]
    property :"#vd",
      comment: %(This property is value disambiguation of authors pairs).freeze,
      domain: "http://vivoext.org#Pair".freeze,
      label: "value_disambiguation".freeze,
      range: "xsd:integer".freeze,
      type: "owl:DatatypeProperty".freeze

    # Extra definitions
    term :"",
      label: "".freeze,
      "owl:versionIRI" => %(http://vivoext.org/).freeze,
      type: "owl:Ontology".freeze
  end
end

