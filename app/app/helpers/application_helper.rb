module ApplicationHelper

	def app_header

		ret = "
			<div id=\" header_evo \" class=\"jumbotron\">
				<div class=\"container\">
				   <div class=\"row \">
				   	<div class=\"col-xs-2 col-md-2\">
				   		"+image_tag("logo_evo_small.png", :alt => "Evoluir")+"
				   	</div>
					<div class=\"col-xs-2 col-md-2 \">
				   		<h1 id=\"evo-tittle\"> EVO </h1>
				   	</div>


				   </div>


				</div>
			</div>"

		ret.html_safe

	end

	def app_footer

		ret = "
			    <footer class=\"footer\">
			      <div class=\"container\">
			        <p class=\"text-muted text-center\">Desenvolvido por André Peil</p>
			        <p class=\"text-muted text-center\">Projeto de Conclusão de Curso</p>
			      </div>
			    </footer>
		"
		ret.html_safe

	end
end
