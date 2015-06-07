module ApplicationHelper

	def app_header

		ret = "
			<div class=\"jumbotron\">
				<div class=\"container\">
				   <h1> " + image_tag("logo_evo_small.png", :alt => "Evoluir") + " EVO</h1>
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
